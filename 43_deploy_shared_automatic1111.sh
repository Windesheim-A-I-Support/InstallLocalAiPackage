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

# Shared AUTOMATIC1111 (Stable Diffusion WebUI)
# Classic feature-rich image generation interface
# Requires GPU for best performance
# Usage: bash 43_deploy_shared_automatic1111.sh [--update]

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
  echo "=== Updating AUTOMATIC1111 ==="
  echo "✅ AUTOMATIC1111 updated (no update needed for native installation)"
  exit 0
fi

echo "=== AUTOMATIC1111 WebUI Deployment ==="

mkdir -p /opt/automatic1111/{models,outputs,extensions}
cd /opt/automatic1111

# Install Python and required packages
apt-get update
apt-get install -y python3 python3-pip python3-venv git

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install AUTOMATIC1111
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git .
pip install -r requirements.txt

# Check for NVIDIA GPU
HAS_GPU=false
if command -v nvidia-smi >/dev/null 2>&1; then
  HAS_GPU=true
  echo "✅ NVIDIA GPU detected"
  # Install CUDA if available
  if command -v nvidia-smi >/dev/null 2>&1; then
    echo "✅ CUDA available for GPU acceleration"
  fi
else
  echo "⚠️  No GPU detected - will use CPU (slow)"
fi

# Create systemd service
cat > /etc/systemd/system/automatic1111.service << EOF
[Unit]
Description=AUTOMATIC1111 WebUI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/automatic1111
Environment=PATH=/opt/automatic1111/venv/bin
ExecStart=/opt/automatic1111/venv/bin/python webui.py --listen 0.0.0.0 --port 7860 --api
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable automatic1111
systemctl start automatic1111

# Wait for service to start
sleep 5

echo "✅ AUTOMATIC1111 deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):7860"
echo "API: http://$(hostname -I | awk '{print $1}'):7860/sdapi/v1"
echo ""
echo "Models directory: /opt/automatic1111/models"
echo ""
echo "Download models:"
echo "  SD 1.5: https://huggingface.co/runwayml/stable-diffusion-v1-5"
echo "  SDXL: https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0"
echo ""
echo "Service management:"
echo "  Start: systemctl start automatic1111"
echo "  Stop: systemctl stop automatic1111"
echo "  Status: systemctl status automatic1111"
echo "  Logs: journalctl -u automatic1111 -f"
echo ""
if [ "$HAS_GPU" = false ]; then
  echo "⚠️  CPU mode is VERY slow. Install NVIDIA drivers for GPU support."
fi
