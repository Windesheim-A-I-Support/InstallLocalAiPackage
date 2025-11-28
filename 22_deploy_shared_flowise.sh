#!/bin/bash
set -e

# Shared Flowise AI orchestration
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 22_deploy_shared_flowise.sh [--update] <postgres_host> <postgres_password>

POSTGRES_HOST="${2:-10.0.5.24}"
POSTGRES_PASS="${3}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

if [ -z "$POSTGRES_PASS" ] && [ "$1" != "--update" ]; then
  echo "❌ Usage: bash 22_deploy_shared_flowise.sh <postgres_host> <postgres_password>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Flowise ==="
  cd /opt/flowise
  docker compose pull
  docker compose up -d
  echo "✅ Flowise updated"
  exit 0
fi

echo "=== Flowise Shared Service Deployment ==="

# Create directory
mkdir -p /opt/flowise/data
cd /opt/flowise

# Generate credentials
FLOWISE_USER="admin"
FLOWISE_PASS=$(openssl rand -base64 20)
FLOWISE_KEY=$(openssl rand -hex 32)

# Create docker-compose
cat > docker-compose.yml << EOF
version: '3.8'

services:
  flowise:
    image: flowiseai/flowise:latest
    container_name: flowise-shared
    restart: unless-stopped
    ports:
      - "3002:3000"
    environment:
      FLOWISE_USERNAME: $FLOWISE_USER
      FLOWISE_PASSWORD: $FLOWISE_PASS
      APIKEY_PATH: /root/.flowise
      SECRETKEY_PATH: /root/.flowise
      DATABASE_TYPE: postgres
      DATABASE_HOST: $POSTGRES_HOST
      DATABASE_PORT: 5432
      DATABASE_USER: dbadmin
      DATABASE_PASSWORD: $POSTGRES_PASS
      DATABASE_NAME: shared
    volumes:
      - ./data:/root/.flowise
EOF

# Start service
docker compose up -d

echo "✅ Flowise deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3002"
echo ""
echo "Username: $FLOWISE_USER"
echo "Password: $FLOWISE_PASS"
