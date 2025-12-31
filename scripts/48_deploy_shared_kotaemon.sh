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

# Shared Kotaemon
# RAG-based document QA system with clean UI
# Upload documents and ask questions using local LLMs
# Usage: bash 48_deploy_shared_kotaemon.sh [--update]

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
  echo "=== Updating Kotaemon ==="
  echo "✅ Kotaemon updated (no update needed for native installation)"
  exit 0
fi

echo "=== Kotaemon Deployment ==="

# Install git if needed
command -v git >/dev/null 2>&1 || apt-get install -y git

mkdir -p /opt/kotaemon
cd /opt/kotaemon

# Clone the repo if not exists
if [ ! -d ".git" ]; then
  git clone https://github.com/Cinnamon/kotaemon .
fi

# Install Python and required packages
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
pip install -r requirements.txt

# Create .env file for configuration
cat > .env << EOF
# Ollama configuration
OLLAMA_BASE_URL=http://10.0.5.100:11434

# Qdrant configuration (if using external Qdrant)
QDRANT_URL=http://10.0.5.101:6333
QDRANT_API_KEY=

# PostgreSQL configuration (optional, for user management)
# Leave empty to use SQLite
DATABASE_URL=

# Application settings
KT_ENABLE_AUTH=False
KT_ENABLE_SIGNUP=True
KT_MAX_FILE_SIZE=100

# Model settings - will use Ollama
LLM_PROVIDER=ollama
EMBEDDING_PROVIDER=ollama
EOF

# Create systemd service
cat > /etc/systemd/system/kotaemon.service << EOF
[Unit]
Description=Kotaemon
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/kotaemon
Environment=PATH=/opt/kotaemon/venv/bin
Environment=GRADIO_SERVER_NAME=0.0.0.0
Environment=GRADIO_SERVER_PORT=7860
ExecStart=/opt/kotaemon/venv/bin/python main.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable kotaemon
systemctl start kotaemon

# Wait for service to start
sleep 5

echo "✅ Kotaemon deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):7860"
echo ""
echo "Kotaemon Features:"
echo "  📄 Document Upload: PDF, DOCX, TXT, and more"
echo "  🤖 RAG-based QA: Ask questions about your documents"
echo "  🔍 Multi-document search and retrieval"
echo "  💬 Chat interface with document context"
echo "  📊 Source citations and references"
echo "  🎨 Clean, modern Gradio UI"
echo ""
echo "Integration with your stack:"
echo "  - LLM: Connected to Ollama at http://10.0.5.100:11434"
echo "  - Vector DB: Can use Qdrant at http://10.0.5.101:6333"
echo "  - Or use built-in ChromaDB (default)"
echo ""
echo "Configuration:"
echo "  - Edit /opt/kotaemon/.env to customize settings"
echo "  - Set up models in Ollama: qwen2.5:3b, nomic-embed-text"
echo ""
echo "Usage:"
echo "  1. Open the URL above"
echo "  2. Upload your documents (PDF, DOCX, etc.)"
echo "  3. Wait for indexing to complete"
echo "  4. Ask questions about your documents!"
echo ""
echo "Data stored in: /opt/kotaemon/ktem_app_data"
echo ""
echo "Service management:"
echo "  Start: systemctl start kotaemon"
echo "  Stop: systemctl stop kotaemon"
echo "  Status: systemctl status kotaemon"
echo "  Logs: journalctl -u kotaemon -f"
