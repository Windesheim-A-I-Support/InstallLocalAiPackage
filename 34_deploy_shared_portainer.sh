#!/bin/bash
set -e

# Shared Portainer container management
# Usage: bash 34_deploy_shared_portainer.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Portainer ==="
  cd /opt/portainer
  docker compose pull
  docker compose up -d
  echo "✅ Portainer updated"
  exit 0
fi

echo "=== Portainer Deployment ==="

mkdir -p /opt/portainer/data
cd /opt/portainer

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer-shared
    restart: unless-stopped
    ports:
      - "9443:9443"
      - "8000:8000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/data
EOF

docker compose up -d

echo "✅ Portainer deployed"
echo ""
echo "URL: https://$(hostname -I | awk '{print $1}'):9443"
echo ""
echo "Create admin user on first login"
