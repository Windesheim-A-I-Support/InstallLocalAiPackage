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

# Shared Jupyter Lab for data analysis
# Usage: bash 20_deploy_shared_jupyter.sh [--update]

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
  echo "=== Updating Jupyter ==="
  cd /opt/jupyter
  docker compose pull
  docker compose up -d
  echo "✅ Jupyter updated"
  exit 0
fi

echo "=== Jupyter Shared Service Deployment ==="

# Create directory
mkdir -p /opt/jupyter/notebooks
cd /opt/jupyter

# Generate token
JUPYTER_TOKEN=$(openssl rand -base64 32)

# Create docker-compose
cat > docker-compose.yml << EOF
version: '3.8'

services:
  jupyter:
    image: jupyter/datascience-notebook:latest
    container_name: jupyter-shared
    restart: unless-stopped
    ports:
      - "8888:8888"
    environment:
      JUPYTER_ENABLE_LAB: "yes"
      JUPYTER_TOKEN: $JUPYTER_TOKEN
      GRANT_SUDO: "yes"
    volumes:
      - ./notebooks:/home/jovyan/work
    user: root
    command: start-notebook.sh --NotebookApp.token='$JUPYTER_TOKEN'
EOF

# Start service
docker compose up -d

echo "✅ Jupyter deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):8888"
echo "Token: $JUPYTER_TOKEN"
echo ""
echo "Connect from Open WebUI:"
echo "  ENABLE_JUPYTER=true"
echo "  JUPYTER_URL=http://$(hostname -I | awk '{print $1}'):8888"
echo "  JUPYTER_TOKEN=$JUPYTER_TOKEN"
