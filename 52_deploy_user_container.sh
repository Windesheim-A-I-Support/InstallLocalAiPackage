#!/bin/bash
set -e

# Deploy Per-User Container with ALL user services
# This script deploys ONE container per user containing:
#   - Open WebUI, n8n, Jupyter, code-server, big-AGI, ChainForge, Kotaemon, Flowise
#
# Usage: bash 52_deploy_user_container.sh <username> <user_number>
# Example: bash 52_deploy_user_container.sh alice 1
#          This creates container at 10.0.5.200 with all services for alice

USERNAME="${1}"
USER_NUM="${2}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

if [ -z "$USERNAME" ] || [ -z "$USER_NUM" ]; then
  echo "❌ Usage: bash 52_deploy_user_container.sh <username> <user_number>"
  echo ""
  echo "Example: bash 52_deploy_user_container.sh alice 1"
  echo "  - Creates container at 10.0.5.200"
  echo "  - Deploys all 8 user services for alice"
  echo ""
  exit 1
fi

# Calculate IP based on user number (200 + user_num)
USER_IP="10.0.5.$((200 + USER_NUM - 1))"
CONTAINER_NAME="user-${USERNAME}"

echo "=== Per-User Container Deployment ==="
echo "User: $USERNAME"
echo "User Number: $USER_NUM"
echo "IP Address: $USER_IP"
echo "Container: $CONTAINER_NAME"
echo ""

# Create directory for user
mkdir -p "/opt/users/${USERNAME}"
cd "/opt/users/${USERNAME}"

# Generate secrets for all services
WEBUI_SECRET=$(openssl rand -base64 32)
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
JUPYTER_TOKEN=$(openssl rand -base64 32)
CODE_SERVER_PASSWORD=$(openssl rand -base64 20)
FLOWISE_PASSWORD=$(openssl rand -base64 20)

# Save secrets to file for user reference
cat > secrets.txt << EOF
=== Secrets for ${USERNAME} ===
Generated: $(date)

Open WebUI:
  URL: http://${USER_IP}:8080
  Secret Key: ${WEBUI_SECRET}
  First user to register becomes admin

n8n:
  URL: http://${USER_IP}:5678
  Encryption Key: ${N8N_ENCRYPTION_KEY}
  First user to register becomes owner

Jupyter Lab:
  URL: http://${USER_IP}:8888
  Token: ${JUPYTER_TOKEN}

code-server:
  URL: http://${USER_IP}:8443
  Password: ${CODE_SERVER_PASSWORD}

big-AGI:
  URL: http://${USER_IP}:3012
  (Browser-based, no authentication)

ChainForge:
  URL: http://${USER_IP}:8000
  (No authentication)

Kotaemon:
  URL: http://${USER_IP}:7860
  (No authentication by default)

Flowise:
  URL: http://${USER_IP}:3000
  Username: admin
  Password: ${FLOWISE_PASSWORD}

=== Shared Services Connection ===
All services connect to shared infrastructure:
  - Ollama: http://10.0.5.100:11434
  - Qdrant: http://10.0.5.101:6333
  - PostgreSQL: 10.0.5.102:5432
  - Redis: 10.0.5.103:6379
  - MinIO: http://10.0.5.104:9000
  - SearXNG: http://10.0.5.105:8080

Database names:
  - PostgreSQL DB: ${USERNAME}_db
  - Qdrant Collection: ${USERNAME}_collection
  - MinIO Bucket: ${USERNAME}-bucket
EOF

chmod 600 secrets.txt

echo "Generating docker-compose.yml for all user services..."

# Create comprehensive docker-compose with all 8 services
cat > docker-compose.yml << EOF
version: '3.8'

services:
  # 1. Open WebUI - Primary AI chat interface
  openwebui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: openwebui-${USERNAME}
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      # Shared services
      OLLAMA_BASE_URL: http://10.0.5.100:11434
      VECTOR_DB: qdrant
      QDRANT_URI: http://10.0.5.101:6333
      QDRANT_COLLECTION: ${USERNAME}_collection

      # Database - dedicated DB in shared PostgreSQL
      DATABASE_URL: postgresql://dbadmin:POSTGRES_PASSWORD_HERE@10.0.5.102:5432/${USERNAME}_db

      # Redis for caching
      REDIS_URL: redis://:REDIS_PASSWORD_HERE@10.0.5.103:6379/0

      # Authentication
      WEBUI_AUTH: "true"
      WEBUI_SECRET_KEY: ${WEBUI_SECRET}
      ENABLE_SIGNUP: "true"
      DEFAULT_USER_ROLE: "user"

      # RAG settings
      ENABLE_RAG_WEB_SEARCH: "true"
      RAG_EMBEDDING_ENGINE: ollama
      RAG_EMBEDDING_MODEL: nomic-embed-text:latest
      ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION: "false"

      # Search integration
      SEARXNG_QUERY_URL: http://10.0.5.105:8080/search?q=<query>

      # Features
      ENABLE_IMAGE_GENERATION: "false"
      ENABLE_COMMUNITY_SHARING: "false"
    volumes:
      - ./openwebui-data:/app/backend/data
    extra_hosts:
      - "host.docker.internal:host-gateway"
    networks:
      - usernetwork

  # 2. n8n - Workflow automation
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n-${USERNAME}
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY}
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: 10.0.5.102
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: ${USERNAME}_n8n
      DB_POSTGRESDB_USER: dbadmin
      DB_POSTGRESDB_PASSWORD: POSTGRES_PASSWORD_HERE
      N8N_DIAGNOSTICS_ENABLED: "false"
      N8N_PERSONALIZATION_ENABLED: "true"
      WEBHOOK_URL: http://${USER_IP}:5678/
    volumes:
      - ./n8n-data:/home/node/.n8n
    networks:
      - usernetwork

  # 3. Jupyter Lab - Data science notebooks
  jupyter:
    image: jupyter/datascience-notebook:latest
    container_name: jupyter-${USERNAME}
    restart: unless-stopped
    ports:
      - "8888:8888"
    environment:
      JUPYTER_ENABLE_LAB: "yes"
      JUPYTER_TOKEN: ${JUPYTER_TOKEN}
      GRANT_SUDO: "yes"
    volumes:
      - ./jupyter-notebooks:/home/jovyan/work
    user: root
    command: start-notebook.sh --NotebookApp.token='${JUPYTER_TOKEN}'
    networks:
      - usernetwork

  # 4. code-server - VS Code in browser
  code-server:
    image: lscr.io/linuxserver/code-server:latest
    container_name: code-server-${USERNAME}
    restart: unless-stopped
    ports:
      - "8443:8443"
    environment:
      PUID: 1000
      PGID: 1000
      PASSWORD: ${CODE_SERVER_PASSWORD}
      SUDO_PASSWORD: ${CODE_SERVER_PASSWORD}
    volumes:
      - ./code-server-config:/config
      - ./code-server-projects:/config/workspace
    networks:
      - usernetwork

  # 5. big-AGI - Advanced AI interface
  big-agi:
    image: ghcr.io/enricoros/big-agi:latest
    container_name: big-agi-${USERNAME}
    restart: unless-stopped
    ports:
      - "3012:3000"
    environment:
      OLLAMA_API_HOST: http://10.0.5.100:11434
    networks:
      - usernetwork

  # 6. ChainForge - Prompt engineering tool
  chainforge:
    image: chainforge/chainforge:latest
    container_name: chainforge-${USERNAME}
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      OLLAMA_BASE_URL: http://10.0.5.100:11434
    volumes:
      - ./chainforge-data:/app/data
    networks:
      - usernetwork

  # 7. Kotaemon - RAG document QA
  kotaemon:
    image: cinnamon/kotaemon:latest
    container_name: kotaemon-${USERNAME}
    restart: unless-stopped
    ports:
      - "7860:7860"
    environment:
      OLLAMA_BASE_URL: http://10.0.5.100:11434
      QDRANT_URL: http://10.0.5.101:6333
      QDRANT_COLLECTION: ${USERNAME}_kotaemon
      GRADIO_SERVER_NAME: 0.0.0.0
      GRADIO_SERVER_PORT: 7860
      KT_ENABLE_AUTH: "False"
      KT_ENABLE_SIGNUP: "True"
    volumes:
      - ./kotaemon-data:/app/ktem_app_data
    networks:
      - usernetwork

  # 8. Flowise - AI workflow builder
  flowise:
    image: flowiseai/flowise:latest
    container_name: flowise-${USERNAME}
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      FLOWISE_USERNAME: admin
      FLOWISE_PASSWORD: ${FLOWISE_PASSWORD}
      DATABASE_TYPE: postgres
      DATABASE_HOST: 10.0.5.102
      DATABASE_PORT: 5432
      DATABASE_USER: dbadmin
      DATABASE_PASSWORD: POSTGRES_PASSWORD_HERE
      DATABASE_NAME: ${USERNAME}_flowise
    volumes:
      - ./flowise-data:/root/.flowise
    networks:
      - usernetwork

networks:
  usernetwork:
    driver: bridge

volumes:
  openwebui-data:
  n8n-data:
  jupyter-notebooks:
  code-server-config:
  code-server-projects:
  chainforge-data:
  kotaemon-data:
  flowise-data:
EOF

echo "✅ docker-compose.yml created"
echo ""
echo "⚠️  IMPORTANT: You must edit docker-compose.yml and replace:"
echo "     - POSTGRES_PASSWORD_HERE with the actual PostgreSQL password"
echo "     - REDIS_PASSWORD_HERE with the actual Redis password"
echo ""
echo "Next steps:"
echo "  1. Edit docker-compose.yml with correct passwords"
echo "  2. Create user-specific databases in PostgreSQL:"
echo "     - ${USERNAME}_db (for Open WebUI)"
echo "     - ${USERNAME}_n8n (for n8n)"
echo "     - ${USERNAME}_flowise (for Flowise)"
echo "  3. Create Qdrant collections:"
echo "     - ${USERNAME}_collection (for Open WebUI)"
echo "     - ${USERNAME}_kotaemon (for Kotaemon)"
echo "  4. Create MinIO bucket: ${USERNAME}-bucket"
echo "  5. Run: cd /opt/users/${USERNAME} && docker compose up -d"
echo ""
echo "User credentials saved to: /opt/users/${USERNAME}/secrets.txt"
echo ""
echo "All services for ${USERNAME} will be accessible at:"
echo "  Open WebUI:   http://${USER_IP}:8080"
echo "  n8n:          http://${USER_IP}:5678"
echo "  Jupyter:      http://${USER_IP}:8888"
echo "  code-server:  http://${USER_IP}:8443"
echo "  big-AGI:      http://${USER_IP}:3012"
echo "  ChainForge:   http://${USER_IP}:8000"
echo "  Kotaemon:     http://${USER_IP}:7860"
echo "  Flowise:      http://${USER_IP}:3000"
echo ""
