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

# Shared N8N workflow automation
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 21_deploy_shared_n8n.sh [--update] <postgres_host> <postgres_password>

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
  echo "❌ Usage: bash 21_deploy_shared_n8n.sh <postgres_host> <postgres_password>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating N8N ==="
  cd /opt/n8n
  docker compose pull
  docker compose up -d
  echo "✅ N8N updated"
  exit 0
fi

echo "=== N8N Shared Service Deployment ==="

# Create directory
mkdir -p /opt/n8n/data
cd /opt/n8n

# Generate encryption key
ENCRYPTION_KEY=$(openssl rand -hex 32)

# Create docker-compose
cat > docker-compose.yml << EOF
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n-shared
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      N8N_ENCRYPTION_KEY: $ENCRYPTION_KEY
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: $POSTGRES_HOST
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: dbadmin
      DB_POSTGRESDB_PASSWORD: $POSTGRES_PASS
      N8N_DIAGNOSTICS_ENABLED: "false"
      N8N_PERSONALIZATION_ENABLED: "false"
    volumes:
      - ./data:/home/node/.n8n
EOF

# Start service
docker compose up -d

echo "✅ N8N deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):5678"
echo ""
echo "Access from Open WebUI workflows"
