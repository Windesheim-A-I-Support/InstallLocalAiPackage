#!/bin/bash
set -e

# Shared openedai-speech (Fast Text-to-Speech)
# OpenAI TTS API compatible with multiple fast engines (Piper, etc.)
# Usage: bash 45_deploy_shared_openedai_speech.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating openedai-speech ==="
  cd /opt/openedai-speech
  docker compose pull
  docker compose up -d
  echo "✅ openedai-speech updated"
  exit 0
fi

echo "=== openedai-speech Deployment ==="

mkdir -p /opt/openedai-speech/{voices,config}
cd /opt/openedai-speech

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  openedai-speech:
    image: ghcr.io/matatonic/openedai-speech:latest
    container_name: openedai-speech-shared
    restart: unless-stopped
    ports:
      - "8001:8000"
    environment:
      TTS_HOME: /app/voices
      HF_HOME: /app/voices
      # Default voice engine: piper (fast), coqui (better quality), or parler (best quality)
      DEFAULT_VOICE: af_sky
      PRELOAD_MODEL: "false"
    volumes:
      - ./voices:/app/voices
      - ./config:/app/config
EOF

docker compose up -d

# Wait for container to start
sleep 5

echo "✅ openedai-speech deployed"
echo ""
echo "API URL: http://$(hostname -I | awk '{print $1}'):8001"
echo "OpenAI-compatible endpoint: http://$(hostname -I | awk '{print $1}'):8001/v1/audio/speech"
echo ""
echo "Connect from Open WebUI:"
echo "  AUDIO_TTS_ENGINE=openai"
echo "  AUDIO_TTS_OPENAI_API_BASE_URL=http://$(hostname -I | awk '{print $1}'):8001/v1"
echo ""
echo "Available voices (OpenAI compatible):"
echo "  - alloy, echo, fable, onyx, nova, shimmer (OpenAI voice names)"
echo "  - af_* (fast Piper voices)"
echo ""
echo "Test speech synthesis:"
echo "curl http://$(hostname -I | awk '{print $1}'):8001/v1/audio/speech \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"model\": \"tts-1\", \"input\": \"Hello world\", \"voice\": \"alloy\"}' \\"
echo "  --output speech.mp3"
echo ""
echo "Voices directory: /opt/openedai-speech/voices"
