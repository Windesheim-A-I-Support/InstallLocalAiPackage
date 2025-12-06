#!/bin/bash
set -e

# ==============================================================================
# SIMPLE OPEN WEBUI DEPLOYMENT
# ==============================================================================
# Minimal deployment with just Open WebUI + Pipelines
# Connects to shared Ollama and uses built-in SQLite database
#
# Perfect for:
#   - Quick testing
#   - Individual users
#   - Learning the platform
#
# Upgrade path: Run 08b_upgrade_to_full_stack.sh later
# ==============================================================================

USER_IP="${1:-10.0.5.200}"
STACK_DIR="/opt/simple-openwebui"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   SIMPLE OPEN WEBUI DEPLOYMENT"
echo "========================================================="
echo ""
echo "This deploys:"
echo "  • Open WebUI (chat interface)"
echo "  • Open WebUI Pipelines (plugins)"
echo ""
echo "Using SHARED Ollama at: http://10.0.5.100:11434"
echo "Storage: Built-in SQLite (simple, no external DB needed)"
echo ""
echo "Access at: http://${USER_IP}:3000"
echo ""
read -p "Press ENTER to continue or Ctrl+C to cancel..."
echo ""

# ==============================================================================
# STEP 1: CREATE DIRECTORY STRUCTURE
# ==============================================================================
echo "--> [1/3] Creating directory structure..."
mkdir -p "$STACK_DIR"
cd "$STACK_DIR"

mkdir -p open-webui/data
mkdir -p pipelines/data

echo "✅ Directory structure created"

# ==============================================================================
# STEP 2: CREATE DOCKER COMPOSE FILE
# ==============================================================================
echo "--> [2/3] Creating docker-compose.yml..."

cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  # ====================
  # OPEN WEBUI PIPELINES
  # ====================
  pipelines:
    image: ghcr.io/open-webui/pipelines:main
    container_name: simple-pipelines
    restart: unless-stopped
    ports:
      - "9099:9099"
    environment:
      PIPELINES_DIR: /app/pipelines
      # Connect to shared Ollama
      OLLAMA_BASE_URL: http://10.0.5.100:11434
    volumes:
      - ./pipelines/data:/app/pipelines
    networks:
      - webui-network

  # ====================
  # OPEN WEBUI
  # ====================
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: simple-open-webui
    restart: unless-stopped
    ports:
      - "3000:8080"
    environment:
      # Connect to shared Ollama
      OLLAMA_BASE_URL: http://10.0.5.100:11434

      # Use built-in SQLite database
      DATABASE_URL: sqlite:///app/backend/data/webui.db

      # Connect to Pipelines
      OPENAI_API_BASE_URLS: http://pipelines:9099
      OPENAI_API_KEYS: "dummy-key"

      # Basic settings
      WEBUI_AUTH: "true"
      ENABLE_SIGNUP: "true"
      DEFAULT_USER_ROLE: "user"

      # Enable RAG
      ENABLE_RAG_WEB_SEARCH: "false"
      RAG_EMBEDDING_ENGINE: ollama
      RAG_EMBEDDING_MODEL: nomic-embed-text:latest

      # Disable features we don't need yet
      ENABLE_IMAGE_GENERATION: "false"
      ENABLE_COMMUNITY_SHARING: "false"
    volumes:
      - ./open-webui/data:/app/backend/data
    networks:
      - webui-network
    depends_on:
      - pipelines

networks:
  webui-network:
    driver: bridge
EOF

echo "✅ docker-compose.yml created"

# ==============================================================================
# STEP 3: DEPLOY STACK
# ==============================================================================
echo "--> [3/3] Deploying Open WebUI..."
echo ""
echo "⚠️  This will pull Docker images (~500MB)"
echo ""

# Deploy the stack
docker compose up -d

echo ""
echo "========================================================="
echo "✅ SIMPLE OPEN WEBUI DEPLOYED"
echo "========================================================="
echo ""
echo "Services are starting up. This may take 30-60 seconds."
echo ""
echo "Access your services at:"
echo "  • Open WebUI:      http://${USER_IP}:3000"
echo "  • Pipelines:       http://${USER_IP}:9099"
echo ""
echo "Using shared Ollama: http://10.0.5.100:11434"
echo ""
echo "Next Steps:"
echo "  1. Open http://${USER_IP}:3000 in your browser"
echo "  2. Create your admin account (first user is admin)"
echo "  3. Start chatting with Ollama models!"
echo ""
echo "To check status:"
echo "  docker ps"
echo ""
echo "To view logs:"
echo "  docker logs simple-open-webui -f"
echo ""
echo "To upgrade to full stack with PostgreSQL, Redis, etc:"
echo "  bash 08b_upgrade_to_full_stack.sh"
echo ""
echo "To stop:"
echo "  cd $STACK_DIR && docker compose down"
echo ""
echo "Stack location: $STACK_DIR"
echo "========================================================="
