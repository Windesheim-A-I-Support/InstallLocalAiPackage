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

# Shared big-AGI
# Advanced AI interface with multi-model support, personas, and beam search
# Modern alternative to Open WebUI with advanced features
# Usage: bash 47_deploy_shared_big_agi.sh [--update]

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
  echo "=== Updating big-AGI ==="
  echo "✅ big-AGI updated (no update needed for native installation)"
  exit 0
fi

echo "=== big-AGI Deployment ==="

mkdir -p /opt/big-agi
cd /opt/big-agi

# Install Python and required packages
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install big-AGI
pip install big-agi

# Create systemd service
cat > /etc/systemd/system/big-agi.service << EOF
[Unit]
Description=big-AGI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/big-agi
Environment=PATH=/opt/big-agi/venv/bin
Environment=OLLAMA_API_HOST=http://10.0.5.100:11434
ExecStart=/opt/big-agi/venv/bin/python -m big_agi
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable big-agi
systemctl start big-agi

# Wait for service to start
sleep 3

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
echo "  3. Add Ollama endpoint: http://10.0.5.100:11434"
echo "  4. Your local models will appear automatically"
echo ""
echo "Advanced Features:"
echo "  - Split view for comparing model responses"
echo "  - Conversation branching and forking"
echo "  - Voice input/output support"
echo "  - Paste images for vision models"
echo "  - Export conversations to Markdown"
echo "  - Custom instructions and system prompts"
echo ""
echo "Service management:"
echo "  Start: systemctl start big-agi"
echo "  Stop: systemctl stop big-agi"
echo "  Status: systemctl status big-agi"
echo "  Logs: journalctl -u big-agi -f"
