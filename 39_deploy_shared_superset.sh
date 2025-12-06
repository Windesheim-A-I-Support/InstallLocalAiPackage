#!/bin/bash
# ==============================================================================
# ⚠️  CRITICAL: NO DOCKER FOR SHARED SERVICES! ⚠️
# ==============================================================================
# SHARED SERVICES (containers 100-199) MUST BE DEPLOYED NATIVELY!
# 
# ❌ DO NOT USE DOCKER for shared services
# ✅ ONLY USER CONTAINERS (200-249) can use Docker
#
# This service deploys NATIVELY using system packages and systemd.
# Docker is ONLY allowed for individual user containers!
# ==============================================================================

set -e

# Shared Apache Superset
# Enterprise BI and data visualization platform
# Requires PostgreSQL (13_deploy_shared_postgres.sh) and Redis (14_deploy_shared_redis.sh)
# Usage: bash 39_deploy_shared_superset.sh [--update] <postgres_host> <postgres_password> <redis_host> <redis_password>

POSTGRES_HOST="${2:-10.0.5.24}"
POSTGRES_PASS="${3}"
REDIS_HOST="${4:-10.0.5.24}"
REDIS_PASS="${5}"

# Debian 12 compatibility checks
if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Check if running on Debian 12
if ! grep -q "Debian GNU/Linux 12" /etc/os-release 2>/dev/null; then
  echo "⚠️  Warning: This script is optimized for Debian 12"
  echo "Current OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
fi

if [ -z "$POSTGRES_PASS" ] && [ "$1" != "--update" ]; then
  echo "❌ Usage: bash 39_deploy_shared_superset.sh <postgres_host> <postgres_password> <redis_host> <redis_password>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Superset ===\"
  cd /opt/superset
  docker compose pull
  docker compose up -d
  echo "✅ Superset updated"
  exit 0
fi

echo "=== Apache Superset Deployment ==="

mkdir -p /opt/superset
cd /opt/superset

SECRET_KEY=$(openssl rand -base64 42)

cat > docker-compose.yml << EOF
version: '3.8'

services:
  superset:
    image: apache/superset:latest
    container_name: superset-shared
    restart: unless-stopped
    ports:
      - "3011:8088"
    environment:
      DATABASE_DIALECT: postgresql
      DATABASE_HOST: ${POSTGRES_HOST}
      DATABASE_PORT: 5432
      DATABASE_DB: superset
      DATABASE_USER: dbadmin
      DATABASE_PASSWORD: ${POSTGRES_PASS}
      REDIS_HOST: ${REDIS_HOST}
      REDIS_PORT: 6379
      REDIS_PASSWORD: ${REDIS_PASS}
      SECRET_KEY: ${SECRET_KEY}
      SUPERSET_ENV: production
    volumes:
      - ./superset_home:/app/superset_home
    command: >
      bash -c "
        superset db upgrade &&
        superset fab create-admin --username admin --firstname Admin --lastname User --email admin@superset.com --password admin &&
        superset init &&
        /usr/bin/run-server.sh
      "
EOF

# Create database
PGPASSWORD=$POSTGRES_PASS psql -h $POSTGRES_HOST -U dbadmin -d postgres -c "CREATE DATABASE superset;" 2>/dev/null || true

docker compose up -d

echo "✅ Superset deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3011"
echo "Username: admin"
echo "Password: admin"
echo ""
echo "⚠️  Change admin password immediately after first login"
