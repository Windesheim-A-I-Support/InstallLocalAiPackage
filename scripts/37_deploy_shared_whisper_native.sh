#!/bin/bash
set -e

# ==============================================================================
# WHISPER NATIVE DEPLOYMENT (OpenAI Whisper Speech-to-Text)
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.113}"
WHISPER_PORT="${2:-9000}"

echo "========================================================="
echo "   WHISPER SPEECH-TO-TEXT DEPLOYMENT"
echo "========================================================="
echo "Container: ${CONTAINER_IP}"
echo "Port: ${WHISPER_PORT}"
echo ""

export DEBIAN_FRONTEND=noninteractive

# Install Python and dependencies
echo "--> Installing Python and dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git curl build-essential ffmpeg

# Create whisper user
if ! id whisper &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/whisper -m whisper
fi

# Create directory
mkdir -p /opt/whisper
cd /opt/whisper

# Create virtual environment
echo "--> Creating Python virtual environment..."
su -s /bin/bash -c "python3 -m venv /opt/whisper/venv" whisper

# Install openai-whisper and API server
echo "--> Installing Whisper (this may take several minutes)..."
su -s /bin/bash -c "/opt/whisper/venv/bin/pip install --upgrade pip" whisper
su -s /bin/bash -c "/opt/whisper/venv/bin/pip install openai-whisper fastapi uvicorn python-multipart" whisper

# Create API server
echo "--> Creating Whisper API server..."
cat > /opt/whisper/server.py << 'EOF'
#!/usr/bin/env python3
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import tempfile
import os
import whisper

app = FastAPI(title="Whisper Speech-to-Text API")

# Load model on startup
print("Loading Whisper model...")
model = whisper.load_model("base")
print("Model loaded successfully")

@app.get("/")
async def root():
    return {"service": "Whisper", "status": "running", "model": "base"}

@app.get("/health")
async def health():
    return {"status": "healthy", "model": "base"}

@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...), language: str = None):
    """Transcribe audio file to text"""
    try:
        # Save uploaded file
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name

        # Transcribe
        result = model.transcribe(tmp_path, language=language)

        # Clean up
        os.unlink(tmp_path)

        return JSONResponse({
            "filename": file.filename,
            "text": result["text"],
            "language": result.get("language"),
            "status": "success"
        })

    except Exception as e:
        if 'tmp_path' in locals() and os.path.exists(tmp_path):
            os.unlink(tmp_path)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=9000)
EOF

chown whisper:whisper /opt/whisper/server.py
chmod +x /opt/whisper/server.py

# Create systemd service
echo "--> Creating systemd service..."
cat > /etc/systemd/system/whisper.service << EOF
[Unit]
Description=Whisper Speech-to-Text API
After=network.target

[Service]
Type=simple
User=whisper
Group=whisper
WorkingDirectory=/opt/whisper
ExecStart=/opt/whisper/venv/bin/python /opt/whisper/server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start service
systemctl daemon-reload
systemctl enable whisper
systemctl start whisper

echo "Waiting for Whisper to start..."
sleep 10

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/whisper.txt << CRED
=== Whisper Speech-to-Text ===
URL: http://${CONTAINER_IP}:${WHISPER_PORT}
Health: http://${CONTAINER_IP}:${WHISPER_PORT}/health

Usage:
curl -X POST -F "file=@audio.mp3" http://${CONTAINER_IP}:${WHISPER_PORT}/transcribe

Service: systemctl status whisper
Logs: journalctl -u whisper -f
CRED

chmod 600 /root/.credentials/whisper.txt

echo "✅ Whisper deployed at http://${CONTAINER_IP}:${WHISPER_PORT}"
