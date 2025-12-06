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

# Shared Apache Tika document extraction
# Usage: bash 23_deploy_shared_tika.sh [--update]

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

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Tika ==="
  cd /opt/tika
  docker compose pull
  docker compose up -d
  echo "✅ Tika updated"
  exit 0
fi

echo "=== Tika Shared Service Deployment ==="

mkdir -p /opt/tika
cd /opt/tika

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  tika:
    image: apache/tika:latest
    container_name: tika-shared
    restart: unless-stopped
    ports:
      - "9998:9998"
EOF

docker compose up -d

echo "✅ Tika deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):9998"
echo ""
echo "Connect from Open WebUI:"
echo "  CONTENT_EXTRACTION_ENGINE=tika"
echo "  TIKA_SERVER_URL=http://$(hostname -I | awk '{print $1}'):9998"
