#!/bin/bash
set -e

# Shared Apache Tika document extraction
# Usage: bash 23_deploy_shared_tika.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
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
