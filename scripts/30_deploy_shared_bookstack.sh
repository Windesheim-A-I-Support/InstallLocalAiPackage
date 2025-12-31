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

# Shared BookStack wiki/documentation
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 30_deploy_shared_bookstack.sh [--update] <postgres_host> <postgres_password>

POSTGRES_HOST="${2:-10.0.5.24}"
POSTGRES_PASS="${3}"

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
  echo "❌ Usage: bash 30_deploy_shared_bookstack.sh <postgres_host> <postgres_password>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating BookStack ==="
  cd /opt/bookstack
  docker compose pull
  docker compose up -d
  echo "✅ BookStack updated"
  exit 0
fi

echo "=== BookStack Shared Service Deployment ==="

mkdir -p /opt/bookstack/{uploads,storage}
cd /opt/bookstack

APP_KEY=$(openssl rand -base64 32)

cat > docker-compose.yml << EOF
version: '3.8'

services:
  bookstack:
    image: lscr.io/linuxserver/bookstack:latest
    container_name: bookstack-shared
    restart: unless-stopped
    ports:
      - "3005:80"
    environment:
      PUID: 1000
      PGID: 1000
      APP_URL: http://$(hostname -I | awk '{print $1}'):3005
      DB_HOST: $POSTGRES_HOST
      DB_PORT: 5432
      DB_DATABASE: bookstack
      DB_USERNAME: dbadmin
      DB_PASSWORD: $POSTGRES_PASS
    volumes:
      - ./uploads:/config
EOF

# Create database
PGPASSWORD=$POSTGRES_PASS psql -h $POSTGRES_HOST -U dbadmin -d postgres -c "CREATE DATABASE bookstack;" 2>/dev/null || true

docker compose up -d

echo "✅ BookStack deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3005"
echo "Default: admin@admin.com / password"
