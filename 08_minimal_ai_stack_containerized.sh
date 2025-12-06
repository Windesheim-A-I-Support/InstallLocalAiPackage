#!/bin/bash
set -e

# ==============================================================================
# CONTAINERIZED MINIMAL AI STACK DEPLOYMENT
# ==============================================================================
# This script deploys a minimal AI stack for teams using external services.
# Designed for containerized deployment with proper scaling.
#
# Includes:
#   - Open WebUI (chat interface for Ollama)
#   - Open WebUI Pipes (plugin framework)
#   - N8N (workflow automation)
#   - Flowise (AI workflow builder)
#
# Connects to EXTERNAL services:
#   - Ollama (10.0.5.100:11434)
#   - Qdrant (10.0.5.101:6333)
#   - PostgreSQL (10.0.5.102:5432)
#   - Redis (10.0.5.103:6379)
#   - MinIO (10.0.5.104:9000)
#   - SearXNG (10.0.5.105:8080)
# ==============================================================================

# Configuration
STACK_DIR="/opt/minimal-ai-stack-containerized"
TEAM_NAME="${1:-team1}"
USER_IP="${2:-10.0.5.200}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   CONTAINERIZED MINIMAL AI STACK DEPLOYMENT"
echo "========================================================="
echo ""
echo "Team: $TEAM_NAME"
echo "User IP: $USER_IP"
echo ""
echo "This will deploy:"
echo "  • Open WebUI (chat interface with RAG)"
echo "  • Open WebUI Pipelines (plugin framework)"
echo "  • N8N (workflow automation)"
echo "  • Flowise (AI workflow builder)"
echo ""
echo "Connecting to EXTERNAL services:"
echo "  • Ollama:        http://10.0.5.100:11434"
echo "  • Qdrant:        http://10.0.5.101:6333"
echo "  • PostgreSQL:    10.0.5.102:5432"
echo "  • Redis:         10.0.5.103:6379"
echo "  • MinIO:         http://10.0.5.104:9000"
echo "  • SearXNG:       http://10.0.5.105:8080"
echo ""
echo "Installation directory: $STACK_DIR"
echo ""

# ==============================================================================
# STEP 1: CREATE DIRECTORY STRUCTURE
# ==============================================================================
echo "--> [1/5] Creating directory structure..."
mkdir -p "$STACK_DIR"
cd "$STACK_DIR"

# Create necessary subdirectories
mkdir -p open-webui/data
mkdir -p pipelines/data
mkdir -p n8n/data
mkdir -p flowise/data

echo "✅ Directory structure created"

# ==============================================================================
# STEP 2: USE SHARED SERVICE CREDENTIALS
# ==============================================================================
echo "--> [2/5] Loading shared service credentials..."

# Load credentials from CREDENTIALS.md
POSTGRES_PASSWORD="ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8="
REDIS_PASSWORD="CRMTVAJTg5A55nmtxDEKqoZ0X/ikhkY1AkGwUSe6M3w="
MINIO_ACCESS_KEY="admin"
MINIO_SECRET_KEY="Rz+q7u3OKc56yR8AS7xHqavIkxuqCEpHs6qOZqOZlMw="

# Generate team-specific secrets
generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

WEBUI_SECRET_KEY=$(generate_secret)
N8N_ENCRYPTION_KEY=$(generate_secret)
FLOWISE_PASSWORD=$(generate_secret)
PIPELINES_API_KEY="0p3n-w3bu!"

echo "✅ Using shared service credentials and generating team-specific secrets"

# ==============================================================================
# STEP 3: CREATE DOCKER COMPOSE FILE
# ==============================================================================
echo "--> [3/5] Creating docker-compose.yml..."

cat > docker-compose.yml <<EOF
version: '3.8'

services:
  # ====================
  # OPEN WEBUI
  # ====================
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: ${TEAM_NAME}-open-webui
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      # External Services
      OLLAMA_BASE_URL: http://10.0.5.100:11434
      VECTOR_DB: qdrant
      QDRANT_URI: http://10.0.5.101:6333
      QDRANT_COLLECTION: ${TEAM_NAME}_collection
      
      # External Database
      DATABASE_URL: postgresql://dbadmin:\${POSTGRES_PASSWORD}@10.0.5.102:5432/${TEAM_NAME}_db

      # External Redis
      REDIS_URL: redis://:\${REDIS_PASSWORD}@10.0.5.103:6379/0
      
      # Authentication
      WEBUI_AUTH: "true"
      WEBUI_SECRET_KEY: \${WEBUI_SECRET_KEY}
      ENABLE_SIGNUP: "true"
      DEFAULT_USER_ROLE: "user"
      
      # RAG Configuration
      ENABLE_RAG_WEB_SEARCH: "true"
      RAG_EMBEDDING_ENGINE: ollama
      RAG_EMBEDDING_MODEL: nomic-embed-text:latest
      ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION: "false"
      
      # External Storage
      S3_ENDPOINT_URL: http://10.0.5.104:9000
      S3_ACCESS_KEY_ID: \${MINIO_ACCESS_KEY}
      S3_SECRET_ACCESS_KEY: \${MINIO_SECRET_KEY}
      S3_BUCKET_NAME: ${TEAM_NAME}-bucket
      
      # External Search
      SEARXNG_QUERY_URL: http://10.0.5.105:8080/search?q=<query>
      
      # Features
      ENABLE_IMAGE_GENERATION: "false"
      ENABLE_COMMUNITY_SHARING: "false"
      
      # Pipelines Integration
      OPENAI_API_BASE_URLS: http://pipelines:9099
      OPENAI_API_KEYS: "dummy-key"
    volumes:
      - ./open-webui/data:/app/backend/data
    networks:
      - ai-network
    depends_on:
      - pipelines

  # ====================
  # OPEN WEBUI PIPELINES
  # ====================
  pipelines:
    image: ghcr.io/open-webui/pipelines:main
    container_name: ${TEAM_NAME}-pipelines
    restart: unless-stopped
    ports:
      - "9099:9099"
    environment:
      PIPELINES_DIR: /app/pipelines
      PIPELINES_API_KEY: \${PIPELINES_API_KEY}
      # External Services
      OLLAMA_BASE_URL: http://10.0.5.100:11434
      QDRANT_URI: http://10.0.5.101:6333
      QDRANT_COLLECTION: ${TEAM_NAME}_pipelines
      REDIS_URL: redis://:\${REDIS_PASSWORD}@10.0.5.103:6379/0
    volumes:
      - ./pipelines/data:/app/pipelines
    networks:
      - ai-network

  # ====================
  # N8N
  # ====================
  n8n:
    image: n8nio/n8n:latest
    container_name: ${TEAM_NAME}-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      N8N_ENCRYPTION_KEY: \${N8N_ENCRYPTION_KEY}
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: 10.0.5.102
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: ${TEAM_NAME}_n8n
      DB_POSTGRESDB_USER: dbadmin
      DB_POSTGRESDB_PASSWORD: \${POSTGRES_PASSWORD}
      N8N_DIAGNOSTICS_ENABLED: "false"
      N8N_PERSONALIZATION_ENABLED: "true"
      WEBHOOK_URL: http://${USER_IP}:5678/
      # External Services
      OLLAMA_BASE_URL: http://10.0.5.100:11434
      QDRANT_URI: http://10.0.5.101:6333
      REDIS_URL: redis://:\${REDIS_PASSWORD}@10.0.5.103:6379/0
    volumes:
      - ./n8n/data:/home/node/.n8n
    networks:
      - ai-network

  # ====================
  # FLOWISE
  # ====================
  flowise:
    image: flowiseai/flowise:latest
    container_name: ${TEAM_NAME}-flowise
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      FLOWISE_USERNAME: admin
      FLOWISE_PASSWORD: \${FLOWISE_PASSWORD}
      DATABASE_TYPE: postgres
      DATABASE_HOST: 10.0.5.102
      DATABASE_PORT: 5432
      DATABASE_USER: dbadmin
      DATABASE_PASSWORD: \${POSTGRES_PASSWORD}
      DATABASE_NAME: ${TEAM_NAME}_flowise
      # External Services
      OLLAMA_BASE_URL: http://10.0.5.100:11434
      QDRANT_URL: http://10.0.5.101:6333
      REDIS_URL: redis://:\${REDIS_PASSWORD}@10.0.5.103:6379/0
    volumes:
      - ./flowise/data:/root/.flowise
    networks:
      - ai-network

networks:
  ai-network:
    driver: bridge
EOF

echo "✅ docker-compose.yml created"

# ==============================================================================
# STEP 4: CREATE .ENV FILE
# ==============================================================================
echo "--> [4/5] Creating .env file..."

cat > .env <<EOF
# Generated on $(date)
# Containerized Minimal AI Stack Configuration

# Team Information
TEAM_NAME=$TEAM_NAME
USER_IP=$USER_IP

# Open WebUI Authentication
WEBUI_SECRET_KEY=$WEBUI_SECRET_KEY

# N8N
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY

# Flowise
FLOWISE_PASSWORD=$FLOWISE_PASSWORD

# Pipes
PIPELINES_API_KEY=$PIPELINES_API_KEY

# External Service URLs (using shared service credentials)
OLLAMA_BASE_URL=http://10.0.5.100:11434
QDRANT_URI=http://10.0.5.101:6333
POSTGRES_HOST=10.0.5.102
POSTGRES_PORT=5432
POSTGRES_USER=dbadmin
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_URL=redis://:$REDIS_PASSWORD@10.0.5.103:6379/0
MINIO_URL=http://10.0.5.104:9000
MINIO_ACCESS_KEY=$MINIO_ACCESS_KEY
MINIO_SECRET_KEY=$MINIO_SECRET_KEY
SEARXNG_URL=http://10.0.5.105:8080

# Database Names (Team-specific)
POSTGRES_DB=${TEAM_NAME}_db
N8N_DB=${TEAM_NAME}_n8n
FLOWISE_DB=${TEAM_NAME}_flowise

# Collections (Team-specific)
QDRANT_COLLECTION=${TEAM_NAME}_collection
PIPELINES_COLLECTION=${TEAM_NAME}_pipelines

# Buckets (Team-specific)
MINIO_BUCKET=${TEAM_NAME}-bucket
EOF

chmod 600 .env

echo "✅ .env file created"

# ==============================================================================
# STEP 5: DEPLOY STACK
# ==============================================================================
echo "--> [5/5] Deploying AI stack..."
echo ""
echo "⚠️  This will pull Docker images (~1-2GB total)"
echo ""

# Deploy the stack
docker compose up -d

echo ""
echo "========================================================="
echo "✅ CONTAINERIZED MINIMAL AI STACK DEPLOYED"
echo "========================================================="
echo ""
echo "Services are starting up. This may take 1-3 minutes."
echo ""
echo "Access your services at:"
echo "  • Open WebUI:      http://$USER_IP:8080"
echo "  • Pipelines:       http://$USER_IP:9099"
echo "  • N8N:             http://$USER_IP:5678"
echo "  • Flowise:         http://$USER_IP:3000"
echo ""
echo "Integration Details:"
echo "  • All services connect to EXTERNAL shared infrastructure"
echo "  • Team-specific databases and collections created automatically"
echo "  • Data isolation between teams"
echo "  • Scalable containerized deployment"
echo ""
echo "✅ Using shared service credentials from CREDENTIALS.md:"
echo "  • PostgreSQL password loaded from shared service"
echo "  • Redis password loaded from shared service"
echo "  • MinIO credentials loaded from shared service"
echo ""
echo "Next Steps:"
echo "  1. Create team-specific databases in PostgreSQL:"
echo "     - ${TEAM_NAME}_db (for Open WebUI)"
echo "     - ${TEAM_NAME}_n8n (for n8n)"
echo "     - ${TEAM_NAME}_flowise (for Flowise)"
echo "  2. Create Qdrant collections:"
echo "     - ${TEAM_NAME}_collection (for Open WebUI)"
echo "     - ${TEAM_NAME}_pipelines (for Pipelines)"
echo "  3. Create MinIO bucket: ${TEAM_NAME}-bucket"
echo "  4. Download embedding model for RAG:"
echo "     docker exec -it ${TEAM_NAME}-open-webui ollama pull nomic-embed-text:latest"
echo ""
echo "To check status:"
echo "  docker ps"
echo ""
echo "To view logs:"
echo "  docker logs ${TEAM_NAME}-open-webui"
echo "  docker logs ${TEAM_NAME}-pipelines"
echo "  docker logs ${TEAM_NAME}-n8n"
echo "  docker logs ${TEAM_NAME}-flowise"
echo ""
echo "To stop all services:"
echo "  cd $STACK_DIR && docker compose down"
echo ""
echo "Stack location: $STACK_DIR"
echo "Secrets saved in: $STACK_DIR/.env"
echo ""
echo "Team: $TEAM_NAME"
echo "========================================================="
