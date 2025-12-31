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

# Shared Gitea Git service
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 28_deploy_shared_gitea.sh [--update] <postgres_host> <postgres_password>

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
  echo "❌ Usage: bash 28_deploy_shared_gitea.sh <postgres_host> <postgres_password>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Gitea ==="
  cd /opt/gitea
  docker compose pull
  docker compose up -d
  echo "✅ Gitea updated"
  exit 0
fi

echo "=== Gitea Shared Service Deployment ==="

mkdir -p /opt/gitea/{data,config}
cd /opt/gitea

cat > docker-compose.yml << EOF
version: '3.8'

services:
  gitea:
    image: gitea/gitea:latest
    container_name: gitea-shared
    restart: unless-stopped
    ports:
      - "3003:3000"
      - "2222:22"
    environment:
      USER_UID: 1000
      USER_GID: 1000
      GITEA__database__DB_TYPE: postgres
      GITEA__database__HOST: $POSTGRES_HOST:5432
      GITEA__database__NAME: gitea
      GITEA__database__USER: dbadmin
      GITEA__database__PASSWD: $POSTGRES_PASS
    volumes:
      - ./data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
EOF

# Create database
PGPASSWORD=$POSTGRES_PASS psql -h $POSTGRES_HOST -U dbadmin -d postgres -c "CREATE DATABASE gitea;" 2>/dev/null || true

docker compose up -d

echo "✅ Gitea deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3003"
echo "SSH: git@$(hostname -I | awk '{print $1}'):2222"
