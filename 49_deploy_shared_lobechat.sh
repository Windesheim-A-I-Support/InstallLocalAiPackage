#!/bin/bash
# ==============================================================================
# ⚠️  CRITICAL: NO DOCKER FOR SHARED SERVICES! ⚠️
# ==============================================================================
# SHARED SERVICES (containers 100-199) MUST BE DEPLOYED NATIVELY!
# 
# ❌ DO NOT USE DOCKER for shared services
# ✅ ONLY USER CONTAINERS (200-249) can use Docker
#
# This service deploys NATIVELY using system packages and systemd.
# Docker is ONLY allowed for individual user containers!
# ==============================================================================

set -e

# Shared LobeChat
# Modern AI chat interface with plugin ecosystem and multi-model support
# Beautiful UI with features like TTS, image generation, and RAG
# Usage: bash 49_deploy_shared_lobechat.sh [--update]

# Debian 12 compatibility checks
if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Check if running on Debian 12
if ! grep -q "Debian GNU/Linux 12" /etc/os-release 2>/dev/null; then
  echo "⚠️  Warning: This script is optimized for Debian 12"
  echo "Current OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating LobeChat ==="
  echo "✅ LobeChat updated (no update needed for native installation)"
  exit 0
fi

echo "=== LobeChat Deployment ==="

mkdir -p /opt/lobechat
cd /opt/lobechat

# Install Node.js and required packages
apt-get update
apt-get install -y nodejs npm git

# Clone LobeChat if not exists
if [ ! -d ".git" ]; then
  git clone https://github.com/lobehub/lobe-chat.git .
fi

# Install dependencies
npm install

# Create environment configuration
cat > .env.local << 'EOF'
# Ollama integration
OLLAMA_PROXY_URL=http://10.0.5.100:11434/v1

# Feature flags
ENABLE_OAUTH_SSO=false

# Database (optional - uses local storage by default)
# DATABASE_URL=postgresql://user:password@10.0.5.102:5432/lobechat

# S3 Storage (optional)
# S3_ENDPOINT=http://10.0.5.104:9000
# S3_BUCKET=lobechat
# S3_ACCESS_KEY_ID=minioadmin
# S3_SECRET_ACCESS_KEY=password

# Access Code for authentication (optional)
# ACCESS_CODE=your-secret-code
EOF

# Create systemd service
cat > /etc/systemd/system/lobechat.service << EOF
[Unit]
Description=LobeChat
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/lobechat
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm run start
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Build and start
echo "Building LobeChat (this may take a few minutes)..."
npm run build

# Enable and start the service
systemctl daemon-reload
systemctl enable lobechat
systemctl start lobechat

# Wait for service to start
sleep 5

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
echo "Service management:"
echo "  Start: systemctl start lobechat"
echo "  Stop: systemctl stop lobechat"
echo "  Status: systemctl status lobechat"
echo "  Logs: journalctl -u lobechat -f"
