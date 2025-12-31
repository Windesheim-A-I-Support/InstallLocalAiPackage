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

# Shared Docling Document Conversion - NATIVE INSTALLATION
# Usage: bash 24_deploy_shared_docling_native.sh [--update]

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
  echo "=== Updating Docling ==="
  cd /opt/docling
  sudo -u docling /opt/docling/venv/bin/pip install --upgrade docling
  systemctl restart docling
  echo "✅ Docling updated"
  exit 0
fi

echo "=== Docling Native Deployment ==="

# Install Python 3.11+ and dependencies
echo "Installing Python and dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git curl build-essential

# Create docling user
if ! id docling &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/docling -m docling
  echo "✅ Created docling user"
fi

# Create directory and virtual environment
mkdir -p /opt/docling
cd /opt/docling

# Create virtual environment
echo "Creating Python virtual environment..."
su -s /bin/bash -c "python3 -m venv /opt/docling/venv" docling

# Install docling
echo "Installing Docling (this may take several minutes)..."
su -s /bin/bash -c "/opt/docling/venv/bin/pip install --upgrade pip" docling
su -s /bin/bash -c "/opt/docling/venv/bin/pip install docling fastapi uvicorn python-multipart" docling

# Create simple API server
echo "Creating Docling API server..."
cat > /opt/docling/server.py << 'EOF'
#!/usr/bin/env python3
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import tempfile
import os
from pathlib import Path

try:
    from docling.document_converter import DocumentConverter
except ImportError:
    print("ERROR: docling not installed. Run: pip install docling")
    exit(1)

app = FastAPI(title="Docling Document Conversion API")

@app.get("/")
async def root():
    return {"service": "Docling", "status": "running", "version": "1.0"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.post("/convert")
async def convert_document(file: UploadFile = File(...)):
    """Convert document to markdown"""
    try:
        # Save uploaded file to temp location
        with tempfile.NamedTemporaryFile(delete=False, suffix=Path(file.filename).suffix) as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name

        # Convert document
        converter = DocumentConverter()
        result = converter.convert(tmp_path)

        # Get markdown output
        markdown_output = result.document.export_to_markdown()

        # Clean up
        os.unlink(tmp_path)

        return JSONResponse({
            "filename": file.filename,
            "markdown": markdown_output,
            "status": "success"
        })

    except Exception as e:
        if 'tmp_path' in locals():
            os.unlink(tmp_path)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/convert/text")
async def convert_to_text(file: UploadFile = File(...)):
    """Convert document to plain text"""
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=Path(file.filename).suffix) as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name

        converter = DocumentConverter()
        result = converter.convert(tmp_path)

        # Export to text
        text_output = result.document.export_to_markdown()  # Docling doesn't have plain text, using markdown

        os.unlink(tmp_path)

        return JSONResponse({
            "filename": file.filename,
            "text": text_output,
            "status": "success"
        })

    except Exception as e:
        if 'tmp_path' in locals():
            os.unlink(tmp_path)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001)
EOF

chown docling:docling /opt/docling/server.py
chmod +x /opt/docling/server.py

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/docling.service << EOF
[Unit]
Description=Docling Document Conversion API
After=network.target

[Service]
Type=simple
User=docling
Group=docling
WorkingDirectory=/opt/docling
ExecStart=/opt/docling/venv/bin/python /opt/docling/server.py
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/docling

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reload
systemctl enable docling
systemctl start docling

# Wait for service to start
echo "Waiting for Docling to start..."
for i in {1..30}; do
  if curl -f http://localhost:5001/health >/dev/null 2>&1; then
    echo "✅ Docling is responding"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Docling failed to start within timeout"
    systemctl status docling
    exit 1
  fi
  sleep 2
done

# Check if service is running
if systemctl is-active --quiet docling; then
  echo "✅ Docling service is running"
else
  echo "❌ Docling service failed to start"
  systemctl status docling
  exit 1
fi

# Save information
mkdir -p /root/.credentials
cat > /root/.credentials/docling.txt << EOF
=== Docling Document Conversion API ===
URL: http://$(hostname -I | awk '{print $1}'):5001
Health: http://$(hostname -I | awk '{print $1}'):5001/health
API Docs: http://$(hostname -I | awk '{print $1}'):5001/docs

Usage Examples:
# Convert document to markdown
curl -X POST -F "file=@document.pdf" http://$(hostname -I | awk '{print $1}'):5001/convert

# Convert document to text
curl -X POST -F "file=@document.pdf" http://$(hostname -I | awk '{print $1}'):5001/convert/text

Service: systemctl status docling
Logs: journalctl -u docling -f
Python: /opt/docling/venv/bin/python
EOF

chmod 600 /root/.credentials/docling.txt

echo ""
echo "=========================================="
echo "✅ Docling deployed successfully!"
echo "=========================================="
echo "URL: http://$(hostname -I | awk '{print $1}'):5001"
echo "API Docs: http://$(hostname -I | awk '{print $1}'):5001/docs"
echo ""
echo "Test: curl http://$(hostname -I | awk '{print $1}'):5001/health"
echo "Credentials: /root/.credentials/docling.txt"
echo "Service: systemctl status docling"
echo "Logs: journalctl -u docling -f"
echo "=========================================="
