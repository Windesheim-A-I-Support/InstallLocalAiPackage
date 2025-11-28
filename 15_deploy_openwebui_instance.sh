#!/bin/bash
set -e

# Deploy individual Open WebUI instance (Docker)
# Connects to shared services (Ollama, Qdrant, Redis, etc.)

INSTANCE_NAME="${1:-webui1}"
PORT="${2:-3000}"
OLLAMA_URL="${3:-http://10.0.5.24:11434}"
QDRANT_URL="${4:-http://10.0.5.24:6333}"
REDIS_URL="${5:-redis://:password@10.0.5.24:6379/0}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== Open WebUI Instance Deployment ==="
echo "Instance: $INSTANCE_NAME"
echo "Port: $PORT"

# Create data directory
mkdir -p "/opt/open-webui-$INSTANCE_NAME/data"

# Generate secret
WEBUI_SECRET=$(openssl rand -base64 32)

# Create docker-compose file
cat > "/opt/open-webui-$INSTANCE_NAME/docker-compose.yml" << EOF
version: '3.8'

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui-$INSTANCE_NAME
    restart: unless-stopped
    ports:
      - "$PORT:8080"
    environment:
      # Shared services
      OLLAMA_BASE_URL: $OLLAMA_URL
      VECTOR_DB: qdrant
      QDRANT_URI: $QDRANT_URL
      REDIS_URL: $REDIS_URL

      # Authentication
      WEBUI_AUTH: "true"
      WEBUI_SECRET_KEY: $WEBUI_SECRET
      ENABLE_SIGNUP: "true"
      DEFAULT_USER_ROLE: "user"

      # RAG
      ENABLE_RAG_WEB_SEARCH: "true"
      RAG_EMBEDDING_ENGINE: ollama
      RAG_EMBEDDING_MODEL: nomic-embed-text:latest

      # Features
      ENABLE_IMAGE_GENERATION: "false"
      ENABLE_COMMUNITY_SHARING: "false"
    volumes:
      - ./data:/app/backend/data
EOF

# Start service
cd "/opt/open-webui-$INSTANCE_NAME"
docker compose up -d

echo "✅ Open WebUI instance deployed"
echo ""
echo "Access: http://$(hostname -I | awk '{print $1}'):$PORT"
echo "Data: /opt/open-webui-$INSTANCE_NAME/data"
echo "Secret: $WEBUI_SECRET"
echo ""
echo "To stop:"
echo "  cd /opt/open-webui-$INSTANCE_NAME && docker compose down"
