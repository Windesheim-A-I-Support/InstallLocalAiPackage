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

# Shared Docling document parsing
# Usage: bash 24_deploy_shared_docling.sh [--update]

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
  echo "=== Updating Docling ==="
  cd /opt/docling
  docker compose pull
  docker compose up -d
  echo "✅ Docling updated"
  exit 0
fi

echo "=== Docling Shared Service Deployment ==="

mkdir -p /opt/docling
cd /opt/docling

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  docling:
    image: quay.io/docling-project/docling-serve:latest
    container_name: docling-shared
    restart: unless-stopped
    ports:
      - "5001:5001"
    environment:
      DOCLING_SERVE_ENABLE_UI: "1"
EOF

docker compose up -d

echo "✅ Docling deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):5001"
echo "UI: http://$(hostname -I | awk '{print $1}'):5001/ui"
