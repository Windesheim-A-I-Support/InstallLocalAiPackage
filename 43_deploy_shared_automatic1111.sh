#!/bin/bash
set -e

# Shared AUTOMATIC1111 (Stable Diffusion WebUI)
# Classic feature-rich image generation interface
# Requires GPU for best performance
# Usage: bash 43_deploy_shared_automatic1111.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating AUTOMATIC1111 ==="
  cd /opt/automatic1111
  docker compose pull
  docker compose up -d
  echo "✅ AUTOMATIC1111 updated"
  exit 0
fi

echo "=== AUTOMATIC1111 WebUI Deployment ==="

mkdir -p /opt/automatic1111/{models,outputs,extensions}
cd /opt/automatic1111

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
  automatic1111:
    image: atinoda/text-generation-webui:default-nightly
    container_name: automatic1111-shared
    restart: unless-stopped
    ports:
      - "7860:7860"
    environment:
      CLI_ARGS: "--listen --api --enable-insecure-extension-access"
    volumes:
      - ./models:/app/stable-diffusion-webui/models
      - ./outputs:/app/stable-diffusion-webui/outputs
      - ./extensions:/app/stable-diffusion-webui/extensions
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

# Alternative: Use AbdBarho's container (more actively maintained for SD)
cat > docker-compose.yml << EOF
version: '3.8'

services:
  automatic1111:
    image: abdbarho/stable-diffusion-webui:latest
    container_name: automatic1111-shared
    restart: unless-stopped
    ports:
      - "7860:7860"
    environment:
      CLI_ARGS: "--listen --api --enable-insecure-extension-access --xformers"
    volumes:
      - ./data:/data
      - ./output:/output
EOF

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

echo "✅ AUTOMATIC1111 deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):7860"
echo "API: http://$(hostname -I | awk '{print $1}'):7860/sdapi/v1"
echo ""
echo "Models directory: /opt/automatic1111/data/models"
echo ""
echo "Download models:"
echo "  SD 1.5: https://huggingface.co/runwayml/stable-diffusion-v1-5"
echo "  SDXL: https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0"
echo ""
if [ "$HAS_GPU" = false ]; then
  echo "⚠️  CPU mode is VERY slow. Install nvidia-docker for GPU support."
fi
