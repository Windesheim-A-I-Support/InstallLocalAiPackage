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

# Shared Whisper STT (Speech-to-Text)
# Usage: bash 25_deploy_shared_whisper.sh [--update]

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
  echo "=== Updating Whisper ==="
  cd /opt/whisper
  docker compose pull
  docker compose up -d
  echo "✅ Whisper updated"
  exit 0
fi

echo "=== Whisper Shared Service Deployment ==="

mkdir -p /opt/whisper
cd /opt/whisper

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  whisper:
    image: onerahmet/openai-whisper-asr-webservice:latest
    container_name: whisper-shared
    restart: unless-stopped
    ports:
      - "9000:9000"
    environment:
      ASR_MODEL: base
      ASR_ENGINE: openai_whisper
EOF

docker compose up -d

echo "✅ Whisper deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):9000"
echo ""
echo "Connect from Open WebUI:"
echo "  AUDIO_STT_ENGINE=openai-whisper"
echo "  AUDIO_STT_OPENAI_WHISPER_API_BASE_URL=http://$(hostname -I | awk '{print $1}'):9000"
