#!/bin/bash
set -e

# ==============================================================================
# UNSTRUCTURED.IO NATIVE DEPLOYMENT - Advanced Document Processing
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.127}"
UNSTRUCTURED_PORT="${2:-8000}"

echo "========================================================="
echo "   UNSTRUCTURED.IO API DEPLOYMENT"
echo "========================================================="
echo "Container: ${CONTAINER_IP}"
echo "Port: ${UNSTRUCTURED_PORT}"
echo ""

export DEBIAN_FRONTEND=noninteractive

# Install dependencies
echo "--> Installing system dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git curl build-essential \
    libmagic-dev poppler-utils tesseract-ocr pandoc

# Note: LibreOffice removed - it's 500MB+. Install manually if needed:
# apt-get install -y libreoffice-writer-nogui

# Create unstructured user
if ! id unstructured &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/unstructured -m unstructured
fi

# Create directory
mkdir -p /opt/unstructured
cd /opt/unstructured

# Create virtual environment
echo "--> Creating Python virtual environment..."
su -s /bin/bash -c "python3 -m venv /opt/unstructured/venv" unstructured

# Install unstructured and API server
echo "--> Installing Unstructured (this may take 10-15 minutes)..."
su -s /bin/bash -c "/opt/unstructured/venv/bin/pip install --upgrade pip" unstructured
su -s /bin/bash -c "/opt/unstructured/venv/bin/pip install 'unstructured[all-docs]' fastapi uvicorn python-multipart" unstructured

# Create API server
echo "--> Creating Unstructured API server..."
cat > /opt/unstructured/server.py << 'PYEOF'
#!/usr/bin/env python3
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import tempfile
import os
from unstructured.partition.auto import partition

app = FastAPI(title="Unstructured.io Document Processing API")

@app.get("/")
async def root():
    return {"service": "Unstructured.io", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.post("/process")
async def process_document(file: UploadFile = File(...)):
    """Process document and extract structured elements"""
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name

        elements = partition(filename=tmp_path)
        
        os.unlink(tmp_path)

        return JSONResponse({
            "filename": file.filename,
            "elements": [{"type": str(type(el).__name__), "text": str(el)} for el in elements],
            "count": len(elements),
            "status": "success"
        })

    except Exception as e:
        if 'tmp_path' in locals() and os.path.exists(tmp_path):
            os.unlink(tmp_path)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
PYEOF

chown unstructured:unstructured /opt/unstructured/server.py
chmod +x /opt/unstructured/server.py

# Create systemd service
echo "--> Creating systemd service..."
cat > /etc/systemd/system/unstructured.service << SVCEOF
[Unit]
Description=Unstructured.io Document Processing API
After=network.target

[Service]
Type=simple
User=unstructured
Group=unstructured
WorkingDirectory=/opt/unstructured
ExecStart=/opt/unstructured/venv/bin/python /opt/unstructured/server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SVCEOF

# Start service
systemctl daemon-reload
systemctl enable unstructured
systemctl start unstructured

echo "Waiting for Unstructured API to start..."
sleep 5

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/unstructured.txt << CRED
=== Unstructured.io API ===
URL: http://${CONTAINER_IP}:${UNSTRUCTURED_PORT}
Health: http://${CONTAINER_IP}:${UNSTRUCTURED_PORT}/health

Usage:
curl -X POST -F "file=@document.pdf" http://${CONTAINER_IP}:${UNSTRUCTURED_PORT}/process

Supported Formats:
- PDF, Word, Excel, PowerPoint
- HTML, Markdown, Plain Text
- Images (with OCR), Emails

Service: systemctl status unstructured
Logs: journalctl -u unstructured -f
CRED

chmod 600 /root/.credentials/unstructured.txt

echo "✅ Unstructured.io deployed at http://${CONTAINER_IP}:${UNSTRUCTURED_PORT}"
