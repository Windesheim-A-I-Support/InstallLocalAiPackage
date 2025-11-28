#!/bin/bash
set -e

# Shared Kotaemon
# RAG-based document QA system with clean UI
# Upload documents and ask questions using local LLMs
# Usage: bash 48_deploy_shared_kotaemon.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Kotaemon ==="
  cd /opt/kotaemon
  git pull
  docker compose down
  docker compose build
  docker compose up -d
  echo "✅ Kotaemon updated"
  exit 0
fi

echo "=== Kotaemon Deployment ==="

# Install git if needed
command -v git >/dev/null 2>&1 || apt-get install -y git

mkdir -p /opt/kotaemon
cd /opt/kotaemon

# Clone the repo if not exists
if [ ! -d ".git" ]; then
  git clone https://github.com/Cinnamon/kotaemon .
fi

# Create .env file for configuration
cat > .env << EOF
# Ollama configuration
OLLAMA_BASE_URL=http://host.docker.internal:11434

# Qdrant configuration (if using external Qdrant)
QDRANT_URL=http://host.docker.internal:6333
QDRANT_API_KEY=

# PostgreSQL configuration (optional, for user management)
# Leave empty to use SQLite
DATABASE_URL=

# Application settings
KT_ENABLE_AUTH=False
KT_ENABLE_SIGNUP=True
KT_MAX_FILE_SIZE=100

# Model settings - will use Ollama
LLM_PROVIDER=ollama
EMBEDDING_PROVIDER=ollama
EOF

# Create docker-compose.yml if it doesn't exist or update it
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  kotaemon:
    build: .
    container_name: kotaemon-shared
    restart: unless-stopped
    ports:
      - "7860:7860"
    volumes:
      - ./ktem_app_data:/app/ktem_app_data
      - ./.env:/app/.env
    environment:
      - GRADIO_SERVER_NAME=0.0.0.0
      - GRADIO_SERVER_PORT=7860
    extra_hosts:
      - "host.docker.internal:host-gateway"
EOF

# Build and start
echo "Building Kotaemon (this may take a few minutes)..."
docker compose build
docker compose up -d

# Wait for service to be ready
echo "Waiting for Kotaemon to start..."
sleep 10

echo "✅ Kotaemon deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):7860"
echo ""
echo "Kotaemon Features:"
echo "  📄 Document Upload: PDF, DOCX, TXT, and more"
echo "  🤖 RAG-based QA: Ask questions about your documents"
echo "  🔍 Multi-document search and retrieval"
echo "  💬 Chat interface with document context"
echo "  📊 Source citations and references"
echo "  🎨 Clean, modern Gradio UI"
echo ""
echo "Integration with your stack:"
echo "  - LLM: Connected to Ollama at http://host.docker.internal:11434"
echo "  - Vector DB: Can use Qdrant at http://host.docker.internal:6333"
echo "  - Or use built-in ChromaDB (default)"
echo ""
echo "Configuration:"
echo "  - Edit /opt/kotaemon/.env to customize settings"
echo "  - Set up models in Ollama: qwen2.5:3b, nomic-embed-text"
echo ""
echo "Usage:"
echo "  1. Open the URL above"
echo "  2. Upload your documents (PDF, DOCX, etc.)"
echo "  3. Wait for indexing to complete"
echo "  4. Ask questions about your documents!"
echo ""
echo "Data stored in: /opt/kotaemon/ktem_app_data"
