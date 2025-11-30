#!/bin/bash
set -e

# Shared LobeChat
# Modern AI chat interface with plugin ecosystem and multi-model support
# Beautiful UI with features like TTS, image generation, and RAG
# Usage: bash 49_deploy_shared_lobechat.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating LobeChat ==="
  cd /opt/lobechat
  docker compose pull
  docker compose up -d
  echo "✅ LobeChat updated"
  exit 0
fi

echo "=== LobeChat Deployment ==="

mkdir -p /opt/lobechat
cd /opt/lobechat

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  lobechat:
    image: lobehub/lobe-chat:latest
    container_name: lobechat-shared
    restart: unless-stopped
    ports:
      - "3210:3210"
    environment:
      # Access Code for authentication (optional)
      # ACCESS_CODE: your-secret-code

      # Ollama integration
      OLLAMA_PROXY_URL: http://10.0.5.100:11434/v1

      # Feature flags
      ENABLE_OAUTH_SSO: false
      NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: ""

      # Database (optional - uses local storage by default)
      # DATABASE_URL: postgresql://user:password@10.0.5.102:5432/lobechat

      # S3 Storage (optional)
      # S3_ENDPOINT: http://10.0.5.104:9000
      # S3_BUCKET: lobechat
      # S3_ACCESS_KEY_ID: minioadmin
      # S3_SECRET_ACCESS_KEY: password

    volumes:
      - ./data:/app/data
    extra_hosts:
      - "host.docker.internal:host-gateway"
EOF

docker compose up -d

echo "✅ LobeChat deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3210"
echo ""
echo "LobeChat Features:"
echo "  🎨 Beautiful UI: Modern, clean interface with dark mode"
echo "  🤖 Multi-Model: Support for Ollama, OpenAI, Anthropic, etc."
echo "  🔌 Plugin System: Extensible with plugins (web search, code interpreter)"
echo "  🗣️ TTS/STT: Text-to-speech and speech-to-text support"
echo "  🖼️ Image Generation: Integrated DALL-E and Midjourney support"
echo "  📚 Knowledge Base: RAG support for document Q&A"
echo "  🌐 PWA: Install as progressive web app"
echo "  🔐 Authentication: Optional access code protection"
echo ""
echo "Connect to local Ollama:"
echo "  Ollama is pre-configured at: http://10.0.5.100:11434/v1"
echo "  Your local models will appear automatically in the model selector"
echo ""
echo "Optional Enhancements:"
echo "  - Set ACCESS_CODE environment variable for password protection"
echo "  - Configure DATABASE_URL to use PostgreSQL for persistence"
echo "  - Configure S3 for file storage (images, documents)"
echo "  - Enable SSO with OAuth providers"
echo ""
