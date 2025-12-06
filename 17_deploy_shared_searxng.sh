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

# Shared SearXNG meta-search engine
# Usage: bash 17_deploy_shared_searxng.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode (SearXNG via Docker)
if [ "$1" = "--update" ]; then
  echo "=== Updating SearXNG ==="
  cd /opt/searxng
  docker compose pull
  docker compose up -d
  echo "✅ SearXNG updated"
  exit 0
fi

echo "=== SearXNG Shared Service Deployment ==="

# Create directory
mkdir -p /opt/searxng
cd /opt/searxng

# Generate secret
SECRET=$(openssl rand -base64 32)

# Create docker-compose
cat > docker-compose.yml << EOF
version: '3.8'

services:
  searxng:
    image: searxng/searxng:latest
    container_name: searxng-shared
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      SEARXNG_SECRET: $SECRET
      SEARXNG_BASE_URL: http://$(hostname -I | awk '{print $1}'):8080
    volumes:
      - ./config:/etc/searxng:rw
EOF

# Create config
mkdir -p config
cat > config/settings.yml << 'EOF'
general:
  instance_name: "Shared Search"

search:
  safe_search: 0
  autocomplete: "google"

server:
  bind_address: "0.0.0.0"
  port: 8080
  secret_key: ""

engines:
  - name: google
    disabled: false
  - name: duckduckgo
    disabled: false
  - name: wikipedia
    disabled: false
EOF

# Start service
docker compose up -d

echo "✅ SearXNG deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):8080"
echo "Secret: $SECRET"
echo ""
echo "Connect from Open WebUI:"
echo "  RAG_WEB_SEARCH_ENGINE=searxng"
echo "  SEARXNG_QUERY_URL=http://$(hostname -I | awk '{print $1}'):8080/search?q=<query>"
