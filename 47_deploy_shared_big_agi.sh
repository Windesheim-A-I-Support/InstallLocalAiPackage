#!/bin/bash
set -e

# Shared big-AGI
# Advanced AI interface with multi-model support, personas, and beam search
# Modern alternative to Open WebUI with advanced features
# Usage: bash 47_deploy_shared_big_agi.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating big-AGI ==="
  cd /opt/big-agi
  docker compose pull
  docker compose up -d
  echo "✅ big-AGI updated"
  exit 0
fi

echo "=== big-AGI Deployment ==="

mkdir -p /opt/big-agi
cd /opt/big-agi

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  big-agi:
    image: ghcr.io/enricoros/big-agi:latest
    container_name: big-agi-shared
    restart: unless-stopped
    ports:
      - "3012:3000"
    environment:
      # Enable Ollama integration
      OLLAMA_API_HOST: http://host.docker.internal:11434
      # Optional: Set API keys for other providers
      # OPENAI_API_KEY: your-key-here
      # ANTHROPIC_API_KEY: your-key-here
      # GOOGLE_API_KEY: your-key-here
    extra_hosts:
      - "host.docker.internal:host-gateway"
EOF

docker compose up -d

echo "✅ big-AGI deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3012"
echo ""
echo "big-AGI Features:"
echo "  ✨ Multi-Model Support: Use multiple AI models simultaneously"
echo "  🎭 Personas: Pre-configured AI personalities and roles"
echo "  🔍 Beam Search: Compare responses from different models"
echo "  📊 Advanced Chat: Code highlighting, diagrams, LaTeX support"
echo "  🎨 Modern UI: Clean, responsive, feature-rich interface"
echo "  🔗 Multi-Provider: Ollama, OpenAI, Anthropic, Google, Azure, etc."
echo ""
echo "Connect to local Ollama:"
echo "  1. Open big-AGI at the URL above"
echo "  2. Go to Models settings"
echo "  3. Add Ollama endpoint: http://host.docker.internal:11434"
echo "  4. Your local models will appear automatically"
echo ""
echo "Advanced Features:"
echo "  - Split view for comparing model responses"
echo "  - Conversation branching and forking"
echo "  - Voice input/output support"
echo "  - Paste images for vision models"
echo "  - Export conversations to Markdown"
echo "  - Custom instructions and system prompts"
