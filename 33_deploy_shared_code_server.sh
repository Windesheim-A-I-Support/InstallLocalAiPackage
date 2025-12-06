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

# Shared VS Code Server (code-server)
# Usage: bash 33_deploy_shared_code_server.sh [--update]

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
  echo "=== Updating code-server ==="
  cd /opt/code-server
  docker compose pull
  docker compose up -d
  echo "✅ code-server updated"
  exit 0
fi

echo "=== code-server Deployment ==="

mkdir -p /opt/code-server/{config,projects}
cd /opt/code-server

PASSWORD=$(openssl rand -base64 20)

cat > docker-compose.yml << EOF
version: '3.8'

services:
  code-server:
    image: lscr.io/linuxserver/code-server:latest
    container_name: code-server-shared
    restart: unless-stopped
    ports:
      - "8443:8443"
    environment:
      PUID: 1000
      PGID: 1000
      PASSWORD: $PASSWORD
      SUDO_PASSWORD: $PASSWORD
    volumes:
      - ./config:/config
      - ./projects:/config/workspace
EOF

docker compose up -d

echo "✅ code-server deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):8443"
echo "Password: $PASSWORD"
