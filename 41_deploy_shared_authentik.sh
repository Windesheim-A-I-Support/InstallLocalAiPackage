#!/bin/bash
set -e

# Shared Authentik SSO
# Single Sign-On and identity provider
# Requires PostgreSQL (13_deploy_shared_postgres.sh) and Redis (14_deploy_shared_redis.sh)
# Usage: bash 41_deploy_shared_authentik.sh [--update] <postgres_host> <postgres_password> <redis_host> <redis_password>

POSTGRES_HOST="${2:-10.0.5.24}"
POSTGRES_PASS="${3}"
REDIS_HOST="${4:-10.0.5.24}"
REDIS_PASS="${5}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

if [ -z "$POSTGRES_PASS" ] && [ "$1" != "--update" ]; then
  echo "❌ Usage: bash 41_deploy_shared_authentik.sh <postgres_host> <postgres_password> <redis_host> <redis_password>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Authentik ===\"
  cd /opt/authentik
  docker compose pull
  docker compose up -d
  echo "✅ Authentik updated"
  exit 0
fi

echo "=== Authentik SSO Deployment ==="

mkdir -p /opt/authentik/{media,custom-templates}
cd /opt/authentik

# Generate secrets
AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60)
AUTHENTIK_BOOTSTRAP_PASSWORD=$(openssl rand -base64 32)
AUTHENTIK_BOOTSTRAP_TOKEN=$(openssl rand -base64 32)

cat > .env << EOF
AUTHENTIK_SECRET_KEY=$AUTHENTIK_SECRET_KEY
AUTHENTIK_BOOTSTRAP_PASSWORD=$AUTHENTIK_BOOTSTRAP_PASSWORD
AUTHENTIK_BOOTSTRAP_TOKEN=$AUTHENTIK_BOOTSTRAP_TOKEN
AUTHENTIK_POSTGRESQL__HOST=$POSTGRES_HOST
AUTHENTIK_POSTGRESQL__NAME=authentik
AUTHENTIK_POSTGRESQL__USER=dbadmin
AUTHENTIK_POSTGRESQL__PASSWORD=$POSTGRES_PASS
AUTHENTIK_REDIS__HOST=$REDIS_HOST
AUTHENTIK_REDIS__PASSWORD=$REDIS_PASS
EOF

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  server:
    image: ghcr.io/goauthentik/server:latest
    container_name: authentik-server
    restart: unless-stopped
    command: server
    ports:
      - "9000:9000"
      - "9443:9443"
    environment:
      AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY}
      AUTHENTIK_BOOTSTRAP_PASSWORD: ${AUTHENTIK_BOOTSTRAP_PASSWORD}
      AUTHENTIK_BOOTSTRAP_TOKEN: ${AUTHENTIK_BOOTSTRAP_TOKEN}
      AUTHENTIK_POSTGRESQL__HOST: ${AUTHENTIK_POSTGRESQL__HOST}
      AUTHENTIK_POSTGRESQL__NAME: ${AUTHENTIK_POSTGRESQL__NAME}
      AUTHENTIK_POSTGRESQL__USER: ${AUTHENTIK_POSTGRESQL__USER}
      AUTHENTIK_POSTGRESQL__PASSWORD: ${AUTHENTIK_POSTGRESQL__PASSWORD}
      AUTHENTIK_REDIS__HOST: ${AUTHENTIK_REDIS__HOST}
      AUTHENTIK_REDIS__PASSWORD: ${AUTHENTIK_REDIS__PASSWORD}
    volumes:
      - ./media:/media
      - ./custom-templates:/templates

  worker:
    image: ghcr.io/goauthentik/server:latest
    container_name: authentik-worker
    restart: unless-stopped
    command: worker
    environment:
      AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY}
      AUTHENTIK_POSTGRESQL__HOST: ${AUTHENTIK_POSTGRESQL__HOST}
      AUTHENTIK_POSTGRESQL__NAME: ${AUTHENTIK_POSTGRESQL__NAME}
      AUTHENTIK_POSTGRESQL__USER: ${AUTHENTIK_POSTGRESQL__USER}
      AUTHENTIK_POSTGRESQL__PASSWORD: ${AUTHENTIK_POSTGRESQL__PASSWORD}
      AUTHENTIK_REDIS__HOST: ${AUTHENTIK_REDIS__HOST}
      AUTHENTIK_REDIS__PASSWORD: ${AUTHENTIK_REDIS__PASSWORD}
    volumes:
      - ./media:/media
      - ./custom-templates:/templates
EOF

# Create database
PGPASSWORD=$POSTGRES_PASS psql -h $POSTGRES_HOST -U dbadmin -d postgres -c "CREATE DATABASE authentik;" 2>/dev/null || true

docker compose up -d

echo "✅ Authentik deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):9000"
echo "Email: akadmin"
echo "Password: $AUTHENTIK_BOOTSTRAP_PASSWORD"
echo ""
echo "⚠️  SAVE THIS PASSWORD - it won't be shown again!"
echo ""
echo "Bootstrap Token (for API): $AUTHENTIK_BOOTSTRAP_TOKEN"
echo ""
echo "Next steps:"
echo "1. Log in and change password"
echo "2. Create applications for each service (Gitea, Grafana, etc.)"
echo "3. Configure OAuth2/OIDC for each service"
echo "4. See AUTHENTICATION_STRATEGY.md for integration guides"
