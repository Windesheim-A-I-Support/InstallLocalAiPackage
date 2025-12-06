#!/bin/bash
set -e

# ==============================================================================
# UPGRADE SIMPLE OPEN WEBUI TO FULL AI STACK
# ==============================================================================
# This upgrades the simple Open WebUI deployment to include:
#   - PostgreSQL database (instead of SQLite)
#   - Redis cache
#   - Qdrant vector database
#   - MinIO object storage
#   - N8N workflow automation
#   - Jupyter notebooks
#   - SearXNG search
#   - Docling document processing
#
# IMPORTANT: This will migrate your data from SQLite to PostgreSQL
# ==============================================================================

SIMPLE_DIR="/opt/simple-openwebui"
FULL_DIR="/opt/full-ai-stack"
USER_IP="${1:-10.0.5.200}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

# Check if simple stack exists
if [ ! -d "$SIMPLE_DIR" ]; then
  echo "❌ Error: Simple Open WebUI not found at $SIMPLE_DIR"
  echo "   Please run 08a_simple_openwebui.sh first"
  exit 1
fi

echo "========================================================="
echo "   UPGRADE TO FULL AI STACK"
echo "========================================================="
echo ""
echo "This will:"
echo "  ✓ Keep your existing Open WebUI data"
echo "  ✓ Migrate from SQLite to PostgreSQL"
echo "  ✓ Add Redis, Qdrant, MinIO, N8N, Jupyter, etc."
echo ""
echo "⚠️  WARNING: Make sure you have backed up your data!"
echo ""
read -p "Press ENTER to continue or Ctrl+C to cancel..."
echo ""

# ==============================================================================
# STEP 1: STOP SIMPLE STACK
# ==============================================================================
echo "--> [1/6] Stopping simple stack..."
cd "$SIMPLE_DIR"
docker compose down

echo "✅ Simple stack stopped"

# ==============================================================================
# STEP 2: BACKUP DATA
# ==============================================================================
echo "--> [2/6] Backing up data..."
BACKUP_DIR="/opt/backups/openwebui-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$SIMPLE_DIR/open-webui/data" "$BACKUP_DIR/open-webui-data"
cp -r "$SIMPLE_DIR/pipelines/data" "$BACKUP_DIR/pipelines-data"

echo "✅ Data backed up to: $BACKUP_DIR"

# ==============================================================================
# STEP 3: CREATE FULL STACK DIRECTORY
# ==============================================================================
echo "--> [3/6] Creating full stack directory..."
mkdir -p "$FULL_DIR"
cd "$FULL_DIR"

# Create directories for all services
mkdir -p open-webui/data
mkdir -p pipelines/data
mkdir -p postgres/data
mkdir -p redis/data
mkdir -p qdrant/data
mkdir -p minio/data
mkdir -p n8n/data
mkdir -p jupyter/data
mkdir -p searxng/data
mkdir -p docling/data

# Copy existing data
cp -r "$BACKUP_DIR/open-webui-data/"* open-webui/data/ 2>/dev/null || true
cp -r "$BACKUP_DIR/pipelines-data/"* pipelines/data/ 2>/dev/null || true

echo "✅ Directory structure created"

# ==============================================================================
# STEP 4: GENERATE CREDENTIALS
# ==============================================================================
echo "--> [4/6] Generating secure credentials..."

generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

POSTGRES_PASSWORD=$(generate_secret)
REDIS_PASSWORD=$(generate_secret)
MINIO_PASSWORD=$(generate_secret)
WEBUI_SECRET=$(generate_secret)
N8N_ENCRYPTION_KEY=$(generate_secret)
JUPYTER_TOKEN=$(generate_secret)

echo "✅ Credentials generated"

# ==============================================================================
# STEP 5: CREATE DOCKER COMPOSE FILE
# ==============================================================================
echo "--> [5/6] Creating full stack docker-compose.yml..."

cat > docker-compose.yml <<EOF
version: '3.8'

services:
  # ====================
  # DATABASES
  # ====================
  postgres:
    image: postgres:15-alpine
    container_name: full-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: openwebui
      POSTGRES_USER: openwebui
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - ./postgres/data:/var/lib/postgresql/data
    networks:
      - ai-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U openwebui"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: full-redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - ./redis/data:/data
    networks:
      - ai-network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  qdrant:
    image: qdrant/qdrant:latest
    container_name: full-qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
    volumes:
      - ./qdrant/data:/qdrant/storage
    networks:
      - ai-network

  minio:
    image: minio/minio:latest
    container_name: full-minio
    restart: unless-stopped
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: ${MINIO_PASSWORD}
    volumes:
      - ./minio/data:/data
    networks:
      - ai-network

  # ====================
  # OPEN WEBUI PIPELINES
  # ====================
  pipelines:
    image: ghcr.io/open-webui/pipelines:main
    container_name: full-pipelines
    restart: unless-stopped
    ports:
      - "9099:9099"
    environment:
      PIPELINES_DIR: /app/pipelines
      OLLAMA_BASE_URL: http://10.0.5.100:11434
      QDRANT_URI: http://qdrant:6333
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379/0
    volumes:
      - ./pipelines/data:/app/pipelines
    networks:
      - ai-network
    depends_on:
      - redis
      - qdrant

  # ====================
  # OPEN WEBUI
  # ====================
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: full-open-webui
    restart: unless-stopped
    ports:
      - "3000:8080"
    environment:
      # External Ollama
      OLLAMA_BASE_URL: http://10.0.5.100:11434

      # PostgreSQL database
      DATABASE_URL: postgresql://openwebui:${POSTGRES_PASSWORD}@postgres:5432/openwebui

      # Redis cache
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379/0

      # Qdrant vector database
      VECTOR_DB: qdrant
      QDRANT_URI: http://qdrant:6333

      # MinIO storage
      S3_ENDPOINT_URL: http://minio:9000
      S3_ACCESS_KEY_ID: admin
      S3_SECRET_ACCESS_KEY: ${MINIO_PASSWORD}
      S3_BUCKET_NAME: openwebui

      # Pipelines
      OPENAI_API_BASE_URLS: http://pipelines:9099
      OPENAI_API_KEYS: "dummy-key"

      # Authentication
      WEBUI_AUTH: "true"
      WEBUI_SECRET_KEY: ${WEBUI_SECRET}
      ENABLE_SIGNUP: "true"
      DEFAULT_USER_ROLE: "user"

      # RAG Configuration
      ENABLE_RAG_WEB_SEARCH: "true"
      RAG_EMBEDDING_ENGINE: ollama
      RAG_EMBEDDING_MODEL: nomic-embed-text:latest
      SEARXNG_QUERY_URL: http://searxng:8080/search?q=<query>

      # Features
      ENABLE_IMAGE_GENERATION: "false"
      ENABLE_COMMUNITY_SHARING: "false"
    volumes:
      - ./open-webui/data:/app/backend/data
    networks:
      - ai-network
    depends_on:
      - postgres
      - redis
      - qdrant
      - minio
      - pipelines

  # ====================
  # N8N WORKFLOW AUTOMATION
  # ====================
  n8n:
    image: n8nio/n8n:latest
    container_name: full-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY}
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: openwebui
      DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}
      WEBHOOK_URL: http://${USER_IP}:5678/
    volumes:
      - ./n8n/data:/home/node/.n8n
    networks:
      - ai-network
    depends_on:
      - postgres

  # ====================
  # JUPYTER NOTEBOOKS
  # ====================
  jupyter:
    image: jupyter/datascience-notebook:latest
    container_name: full-jupyter
    restart: unless-stopped
    ports:
      - "8888:8888"
    environment:
      JUPYTER_ENABLE_LAB: "yes"
      JUPYTER_TOKEN: ${JUPYTER_TOKEN}
    volumes:
      - ./jupyter/data:/home/jovyan/work
    networks:
      - ai-network

  # ====================
  # SEARXNG SEARCH
  # ====================
  searxng:
    image: searxng/searxng:latest
    container_name: full-searxng
    restart: unless-stopped
    ports:
      - "8081:8080"
    volumes:
      - ./searxng/data:/etc/searxng
    networks:
      - ai-network

  # ====================
  # DOCLING DOCUMENT PROCESSING
  # ====================
  docling:
    image: ds4sd/docling:latest
    container_name: full-docling
    restart: unless-stopped
    ports:
      - "5001:5001"
    networks:
      - ai-network

networks:
  ai-network:
    driver: bridge
EOF

echo "✅ docker-compose.yml created"

# ==============================================================================
# STEP 6: CREATE .ENV FILE
# ==============================================================================
cat > .env <<EOF
# Generated on $(date)
# Full AI Stack Configuration

POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
MINIO_PASSWORD=${MINIO_PASSWORD}
WEBUI_SECRET=${WEBUI_SECRET}
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
JUPYTER_TOKEN=${JUPYTER_TOKEN}

# Service URLs
OLLAMA_BASE_URL=http://10.0.5.100:11434
USER_IP=${USER_IP}
EOF

chmod 600 .env

echo "✅ .env file created"

# ==============================================================================
# STEP 7: DEPLOY FULL STACK
# ==============================================================================
echo "--> [6/6] Deploying full AI stack..."
echo ""
echo "⚠️  This will pull Docker images (~2-3GB total)"
echo ""

# Deploy the stack
docker compose up -d

echo ""
echo "========================================================="
echo "✅ UPGRADE TO FULL AI STACK COMPLETE"
echo "========================================================="
echo ""
echo "Services are starting up. This may take 2-3 minutes."
echo ""
echo "Access your services at:"
echo "  • Open WebUI:      http://${USER_IP}:3000"
echo "  • Pipelines:       http://${USER_IP}:9099"
echo "  • N8N:             http://${USER_IP}:5678"
echo "  • Jupyter:         http://${USER_IP}:8888 (token: ${JUPYTER_TOKEN})"
echo "  • MinIO Console:   http://${USER_IP}:9001 (admin/${MINIO_PASSWORD})"
echo "  • Qdrant:          http://${USER_IP}:6333"
echo ""
echo "🔐 Important Credentials:"
echo "  • PostgreSQL password: ${POSTGRES_PASSWORD}"
echo "  • Redis password:      ${REDIS_PASSWORD}"
echo "  • MinIO password:      ${MINIO_PASSWORD}"
echo "  • Jupyter token:       ${JUPYTER_TOKEN}"
echo ""
echo "📦 Data Migration:"
echo "  • Old data backed up to: $BACKUP_DIR"
echo "  • SQLite data copied to: $FULL_DIR/open-webui/data"
echo "  • PostgreSQL will auto-migrate on first startup"
echo ""
echo "To check status:"
echo "  docker ps"
echo ""
echo "To view logs:"
echo "  docker logs full-open-webui -f"
echo ""
echo "To stop all services:"
echo "  cd $FULL_DIR && docker compose down"
echo ""
echo "Stack location: $FULL_DIR"
echo "Credentials saved in: $FULL_DIR/.env"
echo "========================================================="
