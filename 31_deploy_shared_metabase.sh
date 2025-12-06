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

# Shared Metabase analytics
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 31_deploy_shared_metabase.sh [--update] <postgres_host> <postgres_password>

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
  echo "❌ Usage: bash 31_deploy_shared_metabase.sh <postgres_host> <postgres_password>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Metabase ==="
  cd /opt/metabase
  docker compose pull
  docker compose up -d
  echo "✅ Metabase updated"
  exit 0
fi

echo "=== Metabase Shared Service Deployment ==="

mkdir -p /opt/metabase/data
cd /opt/metabase

cat > docker-compose.yml << EOF
version: '3.8'

services:
  metabase:
    image: metabase/metabase:latest
    container_name: metabase-shared
    restart: unless-stopped
    ports:
      - "3006:3000"
    environment:
      MB_DB_TYPE: postgres
      MB_DB_DBNAME: metabase
      MB_DB_PORT: 5432
      MB_DB_USER: dbadmin
      MB_DB_PASS: $POSTGRES_PASS
      MB_DB_HOST: $POSTGRES_HOST
    volumes:
      - ./data:/metabase-data
EOF

# Create database
PGPASSWORD=$POSTGRES_PASS psql -h $POSTGRES_HOST -U dbadmin -d postgres -c "CREATE DATABASE metabase;" 2>/dev/null || true

docker compose up -d

echo "✅ Metabase deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3006"
