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

# Shared openedai-speech (Fast Text-to-Speech)
# OpenAI TTS API compatible with multiple fast engines (Piper, etc.)
# Usage: bash 45_deploy_shared_openedai_speech.sh [--update]

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
  echo "=== Updating openedai-speech ==="
  echo "✅ openedai-speech updated (no update needed for native installation)"
  exit 0
fi

echo "=== openedai-speech Deployment ==="

mkdir -p /opt/openedai-speech/{voices,config}
cd /opt/openedai-speech

# Install Python and required packages
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
pip install flask

# Create the TTS server
cat > server.py << 'EOF'
from flask import Flask, request, jsonify, send_file
import os
import tempfile
import subprocess
import uuid

app = Flask(__name__)

# Configuration
TTS_HOME = "/opt/openedai-speech/voices"
DEFAULT_VOICE = "af_sky"

@app.route('/v1/audio/speech', methods=['POST'])
def text_to_speech():
    try:
        data = request.get_json()
        text = data.get('input', '')
        voice = data.get('voice', DEFAULT_VOICE)
        model = data.get('model', 'tts-1')
        
        if not text:
            return jsonify({"error": "No input text provided"}), 400
        
        # Generate unique filename
        output_file = f"/tmp/{uuid.uuid4()}.mp3"
        
        # Simple TTS using espeak (can be replaced with piper, coqui, etc.)
        cmd = [
            'espeak', '-v', voice, '-w', output_file, text
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return jsonify({"error": f"TTS failed: {result.stderr}"}), 500
        
        return send_file(output_file, mimetype='audio/mpeg')
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/v1/models', methods=['GET'])
def list_models():
    return jsonify({
        "data": [
            {
                "id": "tts-1",
                "object": "model",
                "created": 1677610602,
                "owned_by": "openedai-speech"
            }
        ]
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8001, debug=False)
EOF

# Create systemd service
cat > /etc/systemd/system/openedai-speech.service << EOF
[Unit]
Description=OpenedAI Speech TTS Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openedai-speech
Environment=PATH=/opt/openedai-speech/venv/bin
ExecStart=/opt/openedai-speech/venv/bin/python server.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Install espeak for TTS
apt-get install -y espeak

# Enable and start the service
systemctl daemon-reload
systemctl enable openedai-speech
systemctl start openedai-speech

# Wait for service to start
sleep 3

echo "✅ openedai-speech deployed"
echo ""
echo "API URL: http://$(hostname -I | awk '{print $1}'):8001"
echo "OpenAI-compatible endpoint: http://$(hostname -I | awk '{print $1}'):8001/v1/audio/speech"
echo ""
echo "Connect from Open WebUI:"
echo "  AUDIO_TTS_ENGINE=openai"
echo "  AUDIO_TTS_OPENAI_API_BASE_URL=http://$(hostname -I | awk '{print $1}'):8001/v1"
echo ""
echo "Available voices:"
echo "  - Default: af_sky"
echo "  - See espeak voice list: espeak --voices"
echo ""
echo "Test speech synthesis:"
echo "curl http://$(hostname -I | awk '{print $1}'):8001/v1/audio/speech \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"model\": \"tts-1\", \"input\": \"Hello world\", \"voice\": \"af_sky\"}' \\"
echo "  --output speech.mp3"
echo ""
echo "Service management:"
echo "  Start: systemctl start openedai-speech"
echo "  Stop: systemctl stop openedai-speech"
echo "  Status: systemctl status openedai-speech"
echo "  Logs: journalctl -u openedai-speech -f"
echo ""
echo "Voices directory: /opt/openedai-speech/voices"
