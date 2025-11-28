#!/bin/bash
set -e

# Shared Formbricks survey/feedback platform
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 35_deploy_shared_formbricks.sh [--update] <postgres_host> <postgres_password>

POSTGRES_HOST="${2:-10.0.5.24}"
POSTGRES_PASS="${3}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

if [ -z "$POSTGRES_PASS" ] && [ "$1" != "--update" ]; then
  echo "❌ Usage: bash 35_deploy_shared_formbricks.sh <postgres_host> <postgres_password>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Formbricks ==="
  cd /opt/formbricks
  docker compose pull
  docker compose up -d
  echo "✅ Formbricks updated"
  exit 0
fi

echo "=== Formbricks Deployment ==="

mkdir -p /opt/formbricks
cd /opt/formbricks

NEXTAUTH_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)

cat > docker-compose.yml << EOF
version: '3.8'

services:
  formbricks:
    image: formbricks/formbricks:latest
    container_name: formbricks-shared
    restart: unless-stopped
    ports:
      - "3008:3000"
    environment:
      DATABASE_URL: postgresql://dbadmin:${POSTGRES_PASS}@${POSTGRES_HOST}:5432/formbricks
      NEXTAUTH_SECRET: $NEXTAUTH_SECRET
      ENCRYPTION_KEY: $ENCRYPTION_KEY
      NEXTAUTH_URL: http://$(hostname -I | awk '{print $1}'):3008
EOF

# Create database
PGPASSWORD=$POSTGRES_PASS psql -h $POSTGRES_HOST -U dbadmin -d postgres -c "CREATE DATABASE formbricks;" 2>/dev/null || true

docker compose up -d

echo "✅ Formbricks deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3008"
