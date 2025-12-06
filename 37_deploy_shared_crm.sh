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

# Shared CRM (EspoCRM)
# Customer Relationship Management system
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 37_deploy_shared_crm.sh [--update] <postgres_host> <postgres_password>

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
  echo "❌ Usage: bash 37_deploy_shared_crm.sh <postgres_host> <postgres_password>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating EspoCRM ===\"
  cd /opt/espocrm
  docker compose pull
  docker compose up -d
  echo "✅ EspoCRM updated"
  exit 0
fi

echo "=== EspoCRM Deployment ==="

mkdir -p /opt/espocrm
cd /opt/espocrm

cat > docker-compose.yml << EOF
version: '3.8'

services:
  espocrm:
    image: espocrm/espocrm:latest
    container_name: espocrm-shared
    restart: unless-stopped
    ports:
      - "3009:80"
    environment:
      ESPOCRM_DATABASE_PLATFORM: Postgresql
      ESPOCRM_DATABASE_HOST: ${POSTGRES_HOST}
      ESPOCRM_DATABASE_PORT: 5432
      ESPOCRM_DATABASE_NAME: espocrm
      ESPOCRM_DATABASE_USER: dbadmin
      ESPOCRM_DATABASE_PASSWORD: ${POSTGRES_PASS}
      ESPOCRM_ADMIN_USERNAME: admin
      ESPOCRM_ADMIN_PASSWORD: $(openssl rand -base64 16)
      ESPOCRM_SITE_URL: http://$(hostname -I | awk '{print $1}'):3009
    volumes:
      - ./data:/var/www/html
EOF

# Create database
PGPASSWORD=$POSTGRES_PASS psql -h $POSTGRES_HOST -U dbadmin -d postgres -c "CREATE DATABASE espocrm;" 2>/dev/null || true

docker compose up -d

# Get admin password
ADMIN_PASS=$(grep ESPOCRM_ADMIN_PASSWORD docker-compose.yml | cut -d: -f2 | tr -d ' ')

echo "✅ EspoCRM deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3009"
echo "Username: admin"
echo "Password: $ADMIN_PASS"
echo ""
echo "Save this password - it won't be shown again!"
