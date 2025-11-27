#!/bin/bash
set -e

# ==============================================================================
# MINIMAL AI STACK DEPLOYMENT - WITHOUT SUPABASE
# ==============================================================================
# This script deploys a minimal AI stack without cloning GitHub repositories
# and without Supabase. Much lighter and faster deployment.
#
# Includes:
#   - Ollama (local LLM runtime)
#   - Open WebUI (chat interface for Ollama)
#   - Langfuse (LLM observability)
#   - N8N (workflow automation)
#
# DOES NOT INCLUDE:
#   - Supabase (saves ~4GB and 13 containers)
#   - Flowise, AnythingLLM, or other heavy services
# ==============================================================================

# Configuration
STACK_DIR="/opt/minimal-ai-stack"
AI_USER="${1:-ai-admin}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   MINIMAL AI STACK DEPLOYMENT"
echo "========================================================="
echo ""
echo "This will deploy:"
echo "  • Ollama (LLM runtime)"
echo "  • Open WebUI (chat interface with RAG)"
echo "  • Open WebUI Pipelines (plugin framework)"
echo "  • Qdrant (vector database for RAG)"
echo "  • Neo4j (graph database)"
echo "  • Jupyter Lab (notebooks)"
echo "  • Langfuse (observability)"
echo "  • N8N (workflow automation)"
echo ""
echo "Installation directory: $STACK_DIR"
echo "User: $AI_USER"
echo ""
read -p "Press ENTER to continue or Ctrl+C to cancel..."
echo ""

# ==============================================================================
# STEP 1: CREATE DIRECTORY STRUCTURE
# ==============================================================================
echo "--> [1/6] Creating directory structure..."
mkdir -p "$STACK_DIR"
cd "$STACK_DIR"

# Create necessary subdirectories
mkdir -p ollama/models
mkdir -p open-webui/data
mkdir -p pipelines/data
mkdir -p qdrant/storage
mkdir -p neo4j/data
mkdir -p neo4j/logs
mkdir -p jupyter/notebooks
mkdir -p langfuse/data
mkdir -p n8n/data
mkdir -p postgres/data

echo "✅ Directory structure created"

# ==============================================================================
# STEP 2: GENERATE SECRETS
# ==============================================================================
echo "--> [2/6] Generating secure secrets..."

generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

POSTGRES_PASSWORD=$(generate_secret)
LANGFUSE_SECRET=$(generate_secret)
LANGFUSE_SALT=$(generate_secret)
N8N_ENCRYPTION_KEY=$(generate_secret)
NEO4J_PASSWORD=$(generate_secret)
JUPYTER_TOKEN=$(generate_secret)

echo "✅ Secrets generated"

# ==============================================================================
# STEP 3: CREATE DOCKER COMPOSE FILE
# ==============================================================================
echo "--> [3/6] Creating docker-compose.yml..."

cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  # ====================
  # POSTGRESQL DATABASE
  # ====================
  postgres:
    image: postgres:15-alpine
    container_name: minimal-ai-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: aistack
      POSTGRES_USER: aistack
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - ./postgres/data:/var/lib/postgresql/data
    networks:
      - ai-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U aistack"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ====================
  # OLLAMA (LLM RUNTIME)
  # ====================
  ollama:
    image: ollama/ollama:latest
    container_name: minimal-ai-ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ./ollama/models:/root/.ollama
    networks:
      - ai-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ====================
  # QDRANT (VECTOR DATABASE)
  # ====================
  qdrant:
    image: qdrant/qdrant:latest
    container_name: minimal-ai-qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - ./qdrant/storage:/qdrant/storage
    networks:
      - ai-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6333/readyz"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ====================
  # OPEN WEBUI PIPELINES
  # ====================
  pipelines:
    image: ghcr.io/open-webui/pipelines:main
    container_name: minimal-ai-pipelines
    restart: unless-stopped
    ports:
      - "9099:9099"
    volumes:
      - ./pipelines/data:/app/pipelines
    environment:
      PIPELINES_DIR: /app/pipelines
    networks:
      - ai-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9099/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ====================
  # OPEN WEBUI
  # ====================
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: minimal-ai-open-webui
    restart: unless-stopped
    ports:
      - "3000:8080"
    environment:
      OLLAMA_BASE_URL: http://ollama:11434
      OPENAI_API_BASE_URLS: http://pipelines:9099
      OPENAI_API_KEYS: "dummy-key"
      WEBUI_AUTH: "false"
      # RAG Configuration
      ENABLE_RAG_WEB_SEARCH: "true"
      VECTOR_DB: qdrant
      QDRANT_URI: http://qdrant:6333
      RAG_EMBEDDING_ENGINE: ollama
      RAG_EMBEDDING_MODEL: nomic-embed-text:latest
      # Document Processing
      DOCS_DIR: /app/backend/data/docs
      UPLOAD_DIR: /app/backend/data/uploads
      # Enable features
      ENABLE_IMAGE_GENERATION: "true"
      ENABLE_COMMUNITY_SHARING: "false"
      ENABLE_MESSAGE_RATING: "true"
    volumes:
      - ./open-webui/data:/app/backend/data
    networks:
      - ai-network
    depends_on:
      - ollama
      - qdrant
      - pipelines

  # ====================
  # NEO4J (GRAPH DATABASE)
  # ====================
  neo4j:
    image: neo4j:5-community
    container_name: minimal-ai-neo4j
    restart: unless-stopped
    ports:
      - "7474:7474"
      - "7687:7687"
    environment:
      NEO4J_AUTH: neo4j/${NEO4J_PASSWORD}
      NEO4J_PLUGINS: '["apoc", "graph-data-science"]'
      NEO4J_dbms_security_procedures_unrestricted: apoc.*,gds.*
      NEO4J_dbms_memory_heap_initial__size: 512m
      NEO4J_dbms_memory_heap_max__size: 2G
    volumes:
      - ./neo4j/data:/data
      - ./neo4j/logs:/logs
    networks:
      - ai-network
    healthcheck:
      test: ["CMD", "cypher-shell", "-u", "neo4j", "-p", "${NEO4J_PASSWORD}", "RETURN 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  # ====================
  # JUPYTER LAB
  # ====================
  jupyter:
    image: jupyter/datascience-notebook:latest
    container_name: minimal-ai-jupyter
    restart: unless-stopped
    ports:
      - "8888:8888"
    environment:
      JUPYTER_ENABLE_LAB: "yes"
      JUPYTER_TOKEN: ${JUPYTER_TOKEN}
      GRANT_SUDO: "yes"
    volumes:
      - ./jupyter/notebooks:/home/jovyan/work
    networks:
      - ai-network
    user: root
    command: start-notebook.sh --NotebookApp.token='${JUPYTER_TOKEN}'

  # ====================
  # LANGFUSE (OBSERVABILITY)
  # ====================
  langfuse:
    image: langfuse/langfuse:latest
    container_name: minimal-ai-langfuse
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      DATABASE_URL: postgresql://aistack:${POSTGRES_PASSWORD}@postgres:5432/aistack
      NEXTAUTH_SECRET: ${LANGFUSE_SECRET}
      SALT: ${LANGFUSE_SALT}
      NEXTAUTH_URL: http://localhost:3001
      TELEMETRY_ENABLED: "false"
    networks:
      - ai-network
    depends_on:
      postgres:
        condition: service_healthy

  # ====================
  # N8N (WORKFLOW AUTOMATION)
  # ====================
  n8n:
    image: n8nio/n8n:latest
    container_name: minimal-ai-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY}
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: aistack
      DB_POSTGRESDB_USER: aistack
      DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}
      N8N_DIAGNOSTICS_ENABLED: "false"
      N8N_PERSONALIZATION_ENABLED: "false"
    volumes:
      - ./n8n/data:/home/node/.n8n
    networks:
      - ai-network
    depends_on:
      postgres:
        condition: service_healthy

networks:
  ai-network:
    driver: bridge
EOF

echo "✅ docker-compose.yml created"

# ==============================================================================
# STEP 4: CREATE .ENV FILE
# ==============================================================================
echo "--> [4/6] Creating .env file..."

cat > .env <<EOF
# Generated on $(date)
# Minimal AI Stack Configuration

# PostgreSQL
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Langfuse
LANGFUSE_SECRET=$LANGFUSE_SECRET
LANGFUSE_SALT=$LANGFUSE_SALT

# N8N
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY

# Neo4j
NEO4J_PASSWORD=$NEO4J_PASSWORD

# Jupyter
JUPYTER_TOKEN=$JUPYTER_TOKEN

# Service URLs (for integration)
OLLAMA_API_URL=http://ollama:11434
QDRANT_URL=http://qdrant:6333
NEO4J_URI=bolt://neo4j:7687
NEO4J_HTTP_URL=http://neo4j:7474
POSTGRES_URL=postgresql://aistack:$POSTGRES_PASSWORD@postgres:5432/aistack
LANGFUSE_PUBLIC_KEY=lf-pk-placeholder
LANGFUSE_SECRET_KEY=lf-sk-placeholder
LANGFUSE_HOST=http://langfuse:3000
EOF

chmod 600 .env

echo "✅ .env file created"

# ==============================================================================
# STEP 5: SET PERMISSIONS
# ==============================================================================
echo "--> [5/6] Setting permissions..."

if id "$AI_USER" &>/dev/null; then
    chown -R "$AI_USER:$AI_USER" "$STACK_DIR"
    echo "✅ Ownership set to $AI_USER"
else
    echo "⚠️  User $AI_USER does not exist - keeping root ownership"
fi

# ==============================================================================
# STEP 6: DEPLOY STACK
# ==============================================================================
echo "--> [6/6] Deploying AI stack..."
echo ""
echo "⚠️  This will pull Docker images (~2-3GB total)"
echo "⚠️  Much smaller than full stack with Supabase (~15GB)"
echo ""

# Check if we should run as user or root
if id "$AI_USER" &>/dev/null && groups "$AI_USER" | grep -q docker; then
    echo "Deploying as user: $AI_USER"
    su - "$AI_USER" -c "cd $STACK_DIR && docker compose up -d"
else
    echo "Deploying as root"
    docker compose up -d
fi

echo ""
echo "========================================================="
echo "✅ MINIMAL AI STACK DEPLOYED"
echo "========================================================="
echo ""
echo "Services are starting up. This may take 2-5 minutes."
echo ""
echo "Access your services at:"
echo "  • Open WebUI:      http://localhost:3000"
echo "  • Pipelines:       http://localhost:9099"
echo "  • Qdrant UI:       http://localhost:6333/dashboard"
echo "  • Neo4j Browser:   http://localhost:7474 (user: neo4j, pass in .env)"
echo "  • Jupyter Lab:     http://localhost:8888 (token in .env)"
echo "  • Langfuse:        http://localhost:3001"
echo "  • N8N:             http://localhost:5678"
echo "  • Ollama API:      http://localhost:11434"
echo ""
echo "Integration Details:"
echo "  • Open WebUI → Ollama (LLM inference)"
echo "  • Open WebUI → Qdrant (vector storage for RAG)"
echo "  • Open WebUI → Pipelines (custom workflows)"
echo "  • N8N → Ollama, Neo4j, Postgres (workflow automation)"
echo "  • Jupyter → All services via network (analysis & scripting)"
echo "  • Langfuse → Postgres (observability data)"
echo ""
echo "To check status:"
echo "  docker ps"
echo ""
echo "To download LLM models:"
echo "  # Small fast models"
echo "  docker exec -it minimal-ai-ollama ollama pull qwen2.5:3b"
echo "  docker exec -it minimal-ai-ollama ollama pull phi3:mini"
echo "  "
echo "  # Larger models"
echo "  docker exec -it minimal-ai-ollama ollama pull llama3.2"
echo "  docker exec -it minimal-ai-ollama ollama pull mistral"
echo "  "
echo "  # Embedding model for RAG (REQUIRED for document search)"
echo "  docker exec -it minimal-ai-ollama ollama pull nomic-embed-text:latest"
echo ""
echo "To test Neo4j connection:"
echo "  docker exec -it minimal-ai-neo4j cypher-shell -u neo4j -p \$NEO4J_PASSWORD"
echo ""
echo "To view logs:"
echo "  docker logs minimal-ai-ollama"
echo "  docker logs minimal-ai-open-webui"
echo "  docker logs minimal-ai-qdrant"
echo "  docker logs minimal-ai-neo4j"
echo "  docker logs minimal-ai-jupyter"
echo "  docker logs minimal-ai-langfuse"
echo "  docker logs minimal-ai-n8n"
echo ""
echo "To stop all services:"
echo "  cd $STACK_DIR && docker compose down"
echo ""
echo "To stop and remove all data:"
echo "  cd $STACK_DIR && docker compose down -v"
echo ""
echo "Stack location: $STACK_DIR"
echo "Secrets saved in: $STACK_DIR/.env"
echo ""
echo "Next Steps:"
echo "  1. Download embedding model for RAG (see command above)"
echo "  2. Upload documents to Open WebUI for RAG"
echo "  3. Create knowledge graphs in Neo4j"
echo "  4. Build workflows in N8N"
echo "  5. Run data analysis in Jupyter"
echo "========================================================="
