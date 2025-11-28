#!/bin/bash
set -e

# Shared ChainForge
# Visual programming environment for prompt engineering and LLM evaluation
# Compare multiple LLMs, prompts, and parameters side-by-side
# Usage: bash 46_deploy_shared_chainforge.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating ChainForge ==="
  cd /opt/chainforge
  git pull
  docker compose down
  docker compose build
  docker compose up -d
  echo "✅ ChainForge updated"
  exit 0
fi

echo "=== ChainForge Deployment ==="

# Install git if needed
command -v git >/dev/null 2>&1 || apt-get install -y git

mkdir -p /opt/chainforge
cd /opt/chainforge

# Clone the repo if not exists
if [ ! -d ".git" ]; then
  git clone https://github.com/Value-Chain-Hacking/ChainForge .
fi

# Create docker-compose if it doesn't exist
if [ ! -f "docker-compose.yml" ]; then
  cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  chainforge:
    build: .
    container_name: chainforge-shared
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - ./data:/app/data
    environment:
      # Connect to local Ollama
      OLLAMA_BASE_URL: http://host.docker.internal:11434
    extra_hosts:
      - "host.docker.internal:host-gateway"
EOF
fi

# Build and start
docker compose build
docker compose up -d

echo "✅ ChainForge deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):8000"
echo ""
echo "ChainForge is a visual programming environment for:"
echo "  - Prompt engineering and testing"
echo "  - Comparing multiple LLMs side-by-side"
echo "  - Evaluating prompt variations"
echo "  - Analyzing model outputs"
echo ""
echo "Connect to your local Ollama instance at http://10.0.5.24:11434"
echo ""
echo "Features:"
echo "  - Flow-based visual programming"
echo "  - Multi-LLM comparison"
echo "  - Prompt template testing"
echo "  - Response evaluation and scoring"
echo "  - Export results to CSV/JSON"
