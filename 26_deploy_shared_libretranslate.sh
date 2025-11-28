#!/bin/bash
set -e

# Shared LibreTranslate translation service
# Usage: bash 26_deploy_shared_libretranslate.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating LibreTranslate ==="
  cd /opt/libretranslate
  docker compose pull
  docker compose up -d
  echo "✅ LibreTranslate updated"
  exit 0
fi

echo "=== LibreTranslate Shared Service Deployment ==="

mkdir -p /opt/libretranslate
cd /opt/libretranslate

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  libretranslate:
    image: libretranslate/libretranslate:latest
    container_name: libretranslate-shared
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      LT_DISABLE_WEB_UI: "false"
EOF

docker compose up -d

echo "✅ LibreTranslate deployed"
echo ""
echo "API: http://$(hostname -I | awk '{print $1}'):5000"
echo "UI: http://$(hostname -I | awk '{print $1}'):5000"
