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
OLLAMA_URL="${2:-http://10.0.5.100:11434}"
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
echo "Using SHARED Ollama at: ${OLLAMA_URL}"
echo "Storage: Built-in SQLite (simple, no external DB needed)"
echo ""
echo "Access at: http://${USER_IP}:3000"
echo ""
read -p "Press ENTER to continue or Ctrl+C to cancel..."
echo ""

# ==============================================================================
# STEP 0: CHECK DOCKER INSTALLATION
# ==============================================================================
echo "--> [0/4] Checking Docker installation..."

if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker not found. Installing Docker..."

    # Update package index
    apt-get update

    # Install prerequisites
    apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Verify docker compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Error: docker compose plugin not available"
    echo "Please install docker-compose-plugin manually"
    exit 1
fi

echo "✅ Docker prerequisites satisfied"

# ==============================================================================
# STEP 1: CREATE DIRECTORY STRUCTURE
# ==============================================================================
echo "--> [1/4] Creating directory structure..."
mkdir -p "$STACK_DIR"
cd "$STACK_DIR"

mkdir -p open-webui/data
mkdir -p pipelines/data

echo "✅ Directory structure created"

# ==============================================================================
# STEP 2: CREATE DOCKER COMPOSE FILE
# ==============================================================================
echo "--> [2/4] Creating docker-compose.yml..."

cat > docker-compose.yml <<EOF
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
      OLLAMA_BASE_URL: ${OLLAMA_URL}
    volumes:
      - ./pipelines/data:/app/pipelines
    networks:
      - webui-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9099/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

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
      OLLAMA_BASE_URL: ${OLLAMA_URL}
      USE_OLLAMA_DOCKER: "false"

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
      pipelines:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

networks:
  webui-network:
    driver: bridge
EOF

echo "✅ docker-compose.yml created"

# ==============================================================================
# STEP 3: STOP EXISTING CONTAINERS (if any)
# ==============================================================================
echo "--> [3/4] Stopping existing containers (if any)..."
docker compose down 2>/dev/null || true
echo "✅ Cleanup complete"

# ==============================================================================
# STEP 4: DEPLOY STACK
# ==============================================================================
echo "--> [4/4] Deploying Open WebUI..."
echo ""
echo "⚠️  This will pull Docker images (~500MB)"
echo ""

# Deploy the stack
docker compose pull
docker compose up -d

# Wait for services to be healthy
echo ""
echo "Waiting for services to become healthy..."
sleep 10

# Check container status
PIPELINES_STATUS=$(docker inspect -f '{{.State.Health.Status}}' simple-pipelines 2>/dev/null || echo "unknown")
WEBUI_STATUS=$(docker inspect -f '{{.State.Health.Status}}' simple-open-webui 2>/dev/null || echo "unknown")

echo ""
echo "Container Health Status:"
echo "  • Pipelines: $PIPELINES_STATUS"
echo "  • Open WebUI: $WEBUI_STATUS"
echo ""

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
echo "Using shared Ollama: ${OLLAMA_URL}"
echo ""
echo "Next Steps:"
echo "  1. Open http://${USER_IP}:3000 in your browser"
echo "  2. Create your admin account (first user is admin)"
echo "  3. Start chatting with Ollama models!"
echo ""
echo "To check status:"
echo "  docker ps"
echo "  docker logs simple-open-webui -f"
echo "  docker logs simple-pipelines -f"
echo ""
echo "To check health:"
echo "  curl http://${USER_IP}:3000/health"
echo "  curl http://${USER_IP}:9099/health"
echo ""
echo "To upgrade to full stack with PostgreSQL, Redis, etc:"
echo "  bash 08b_upgrade_to_full_stack.sh"
echo ""
echo "To stop:"
echo "  cd $STACK_DIR && docker compose down"
echo ""
echo "To restart:"
echo "  cd $STACK_DIR && docker compose restart"
echo ""
echo "Stack location: $STACK_DIR"
echo "========================================================="
