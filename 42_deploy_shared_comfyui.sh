#!/bin/bash
set -e

# Shared ComfyUI (Stable Diffusion)
# Modern node-based image generation interface
# Requires GPU for best performance
# Usage: bash 42_deploy_shared_comfyui.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating ComfyUI ==="
  cd /opt/comfyui
  docker compose pull
  docker compose up -d
  echo "✅ ComfyUI updated"
  exit 0
fi

echo "=== ComfyUI Deployment ==="

mkdir -p /opt/comfyui/{models,input,output,custom_nodes}
cd /opt/comfyui

# Check for NVIDIA GPU
HAS_GPU=false
if command -v nvidia-smi >/dev/null 2>&1; then
  HAS_GPU=true
  echo "✅ NVIDIA GPU detected"
else
  echo "⚠️  No GPU detected - will use CPU (slow)"
fi

cat > docker-compose.yml << EOF
version: '3.8'

services:
  comfyui:
    image: yanwk/comfyui-boot:latest
    container_name: comfyui-shared
    restart: unless-stopped
    ports:
      - "8188:8188"
    environment:
      CLI_ARGS: "--listen 0.0.0.0 --port 8188"
    volumes:
      - ./models:/opt/ComfyUI/models
      - ./input:/opt/ComfyUI/input
      - ./output:/opt/ComfyUI/output
      - ./custom_nodes:/opt/ComfyUI/custom_nodes
EOF

# Add GPU support if available
if [ "$HAS_GPU" = true ]; then
  cat >> docker-compose.yml << 'EOF'
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
EOF
fi

docker compose up -d

echo "✅ ComfyUI deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):8188"
echo ""
echo "Models directory: /opt/comfyui/models"
echo ""
echo "Download models:"
echo "  SD 1.5: https://huggingface.co/runwayml/stable-diffusion-v1-5"
echo "  SDXL: https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0"
echo ""
echo "Place .safetensors/.ckpt files in:"
echo "  /opt/comfyui/models/checkpoints/"
echo ""
if [ "$HAS_GPU" = false ]; then
  echo "⚠️  CPU mode is VERY slow. Install nvidia-docker for GPU support."
fi
