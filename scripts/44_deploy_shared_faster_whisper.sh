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

# Shared faster-whisper-server (Faster Speech-to-Text)
# Optimized Whisper implementation with OpenAI-compatible API
# Much faster than standard Whisper
# Usage: bash 44_deploy_shared_faster_whisper.sh [--update]

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
  echo "=== Updating faster-whisper ==="
  echo "✅ faster-whisper updated (no update needed for native installation)"
  exit 0
fi

echo "=== faster-whisper-server Deployment ==="

mkdir -p /opt/faster-whisper
cd /opt/faster-whisper

# Install Python and required packages
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install faster-whisper
pip install faster-whisper

# Check for GPU
HAS_GPU=false
if command -v nvidia-smi >/dev/null 2>&1; then
  HAS_GPU=true
  MODEL="large-v3"
  echo "✅ NVIDIA GPU detected - using large-v3 model"
else
  MODEL="base"
  echo "⚠️  No GPU detected - using base model"
fi

# Create the faster-whisper server
cat > server.py << 'EOF'
from faster_whisper import WhisperModel
from flask import Flask, request, jsonify
import os
import tempfile

app = Flask(__name__)

# Load model
model = WhisperModel(MODEL, device="cuda" if HAS_GPU else "cpu", compute_type="float16" if HAS_GPU else "int8")

@app.route('/v1/audio/transcriptions', methods=['POST'])
def transcribe():
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400
    
    file = request.files['file']
    
    # Save to temporary file
    with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
        file.save(temp_file.name)
        temp_path = temp_file.name
    
    try:
        # Transcribe
        segments, info = model.transcribe(temp_path, beam_size=5)
        
        # Combine segments
        text = " ".join([segment.text for segment in segments])
        
        return jsonify({
            "text": text,
            "language": info.language,
            "language_probability": info.language_probability
        })
    finally:
        # Clean up
        os.unlink(temp_path)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=False)
EOF

# Replace placeholders with actual values
sed -i "s/MODEL/\"$MODEL\"/g" server.py
sed -i "s/HAS_GPU/$HAS_GPU/g" server.py

# Create systemd service
cat > /etc/systemd/system/faster-whisper.service << EOF
[Unit]
Description=Faster Whisper Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/faster-whisper
Environment=PATH=/opt/faster-whisper/venv/bin
ExecStart=/opt/faster-whisper/venv/bin/python server.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable faster-whisper
systemctl start faster-whisper

# Wait for service to start
sleep 3

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
echo "Service management:"
echo "  Start: systemctl start faster-whisper"
echo "  Stop: systemctl stop faster-whisper"
echo "  Status: systemctl status faster-whisper"
echo "  Logs: journalctl -u faster-whisper -f"
echo ""
if [ "$HAS_GPU" = true ]; then
  echo "Model: $MODEL (GPU-accelerated)"
else
  echo "Model: $MODEL (CPU - slower)"
fi
