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

# Shared ChainForge
# Visual programming environment for prompt engineering and LLM evaluation
# Compare multiple LLMs, prompts, and parameters side-by-side
# Usage: bash 46_deploy_shared_chainforge.sh [--update]

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
  echo "=== Updating ChainForge ==="
  echo "✅ ChainForge updated (no update needed for native installation)"
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

# Install Python and required packages
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
pip install -r requirements.txt

# Create systemd service
cat > /etc/systemd/system/chainforge.service << EOF
[Unit]
Description=ChainForge
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/chainforge
Environment=PATH=/opt/chainforge/venv/bin
Environment=OLLAMA_BASE_URL=http://10.0.5.100:11434
ExecStart=/opt/chainforge/venv/bin/python main.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable chainforge
systemctl start chainforge

# Wait for service to start
sleep 3

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
echo "Connect to your local Ollama instance at http://10.0.5.100:11434"
echo ""
echo "Features:"
echo "  - Flow-based visual programming"
echo "  - Multi-LLM comparison"
echo "  - Prompt template testing"
echo "  - Response evaluation and scoring"
echo "  - Export results to CSV/JSON"
echo ""
echo "Service management:"
echo "  Start: systemctl start chainforge"
echo "  Stop: systemctl stop chainforge"
echo "  Status: systemctl status chainforge"
echo "  Logs: journalctl -u chainforge -f"
