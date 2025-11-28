#!/bin/bash
set -e

# Shared faster-whisper-server (Faster Speech-to-Text)
# Optimized Whisper implementation with OpenAI-compatible API
# Much faster than standard Whisper
# Usage: bash 44_deploy_shared_faster_whisper.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating faster-whisper ==="
  cd /opt/faster-whisper
  docker compose pull
  docker compose up -d
  echo "✅ faster-whisper updated"
  exit 0
fi

echo "=== faster-whisper-server Deployment ==="

mkdir -p /opt/faster-whisper
cd /opt/faster-whisper

# Check for GPU
HAS_GPU=false
if command -v nvidia-smi >/dev/null 2>&1; then
  HAS_GPU=true
  MODEL="Systran/faster-whisper-large-v3"
  echo "✅ NVIDIA GPU detected - using large-v3 model"
else
  MODEL="Systran/faster-whisper-base"
  echo "⚠️  No GPU detected - using base model"
fi

cat > docker-compose.yml << EOF
version: '3.8'

services:
  faster-whisper:
    image: fedirz/faster-whisper-server:latest-cuda
    container_name: faster-whisper-shared
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      WHISPER_MODEL: ${MODEL}
      WHISPER_LANG: en
    volumes:
      - ./models:/root/.cache/huggingface
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
else
  # Use CPU image if no GPU
  sed -i 's/latest-cuda/latest-cpu/g' docker-compose.yml
fi

docker compose up -d

echo "✅ faster-whisper-server deployed"
echo ""
echo "API URL: http://$(hostname -I | awk '{print $1}'):8000"
echo "OpenAI-compatible endpoint: http://$(hostname -I | awk '{print $1}'):8000/v1/audio/transcriptions"
echo ""
echo "Connect from Open WebUI:"
echo "  AUDIO_STT_ENGINE=openai"
echo "  AUDIO_STT_OPENAI_API_BASE_URL=http://$(hostname -I | awk '{print $1}'):8000/v1"
echo ""
echo "Test transcription:"
echo "curl http://$(hostname -I | awk '{print $1}'):8000/v1/audio/transcriptions \\"
echo "  -F 'file=@audio.mp3' \\"
echo "  -F 'model=whisper-1'"
echo ""
if [ "$HAS_GPU" = true ]; then
  echo "Model: $MODEL (GPU-accelerated)"
else
  echo "Model: $MODEL (CPU - slower)"
fi
