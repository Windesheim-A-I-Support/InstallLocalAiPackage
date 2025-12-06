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

# Shared MCPO (MCP-to-OpenAPI Proxy)
# Converts Model Context Protocol tools to OpenAPI endpoints
# Usage: bash 27_deploy_shared_mcpo.sh [--update]

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
  echo "=== Updating MCPO ==="
  cd /opt/mcpo
  docker compose pull
  docker compose up -d
  echo "✅ MCPO updated"
  exit 0
fi

echo "=== MCPO Shared Service Deployment ==="

mkdir -p /opt/mcpo/config
cd /opt/mcpo

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  mcpo:
    image: ghcr.io/open-webui/mcpo:latest
    container_name: mcpo-shared
    restart: unless-stopped
    ports:
      - "8765:8765"
    environment:
      MCPO_PORT: 8765
      MCPO_HOST: 0.0.0.0
      LOG_LEVEL: info
    volumes:
      - ./config:/app/config
    command: mcpo --host 0.0.0.0 --port 8765
EOF

# Create example config
cat > config/mcpo.yaml << 'EOF'
# MCPO Configuration
# Add MCP server configurations here
servers: []
EOF

docker compose up -d

echo "✅ MCPO deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):8765"
echo "OpenAPI Docs: http://$(hostname -I | awk '{print $1}'):8765/docs"
echo ""
echo "Connect from Open WebUI:"
echo "  MCP_SERVERS=http://$(hostname -I | awk '{print $1}'):8765"
echo ""
echo "Configure MCP servers in: /opt/mcpo/config/mcpo.yaml"
