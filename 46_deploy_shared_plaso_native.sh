#!/bin/bash
set -e

# ==============================================================================
# PLASO/LOG2TIMELINE NATIVE DEPLOYMENT - Forensic Timeline Generation
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.131}"
PLASO_PORT="${2:-8000}"

echo "========================================================="
echo "   PLASO/LOG2TIMELINE DEPLOYMENT"
echo "========================================================="
echo "Container: ${CONTAINER_IP}"
echo "Port: ${PLASO_PORT}"
echo ""

export DEBIAN_FRONTEND=noninteractive

# Install Python and dependencies
echo "--> Installing Python and dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git curl build-essential \
    python3-dev libbz2-dev libsqlite3-dev

# Create plaso user
if ! id plaso &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/plaso -m plaso
fi

# Create directory
mkdir -p /opt/plaso/evidence /opt/plaso/timelines
cd /opt/plaso

# Create virtual environment
echo "--> Creating Python virtual environment..."
su -s /bin/bash -c "python3 -m venv /opt/plaso/venv" plaso

# Install Plaso
echo "--> Installing Plaso (this may take 10-15 minutes)..."
su -s /bin/bash -c "/opt/plaso/venv/bin/pip install --upgrade pip" plaso
su -s /bin/bash -c "/opt/plaso/venv/bin/pip install plaso fastapi uvicorn python-multipart psycopg2-binary" plaso

# Create API server
echo "--> Creating Plaso API server..."
cat > /opt/plaso/server.py << 'PYEOF'
#!/usr/bin/env python3
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import tempfile
import os
import subprocess

app = FastAPI(title="Plaso Timeline Generation API")

@app.get("/")
async def root():
    return {"service": "Plaso/log2timeline", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "tool": "log2timeline"}

@app.post("/process")
async def process_evidence(file: UploadFile = File(...)):
    """Process evidence file and generate timeline"""
    try:
        evidence_path = f"/opt/plaso/evidence/{file.filename}"
        timeline_path = f"/opt/plaso/timelines/{file.filename}.plaso"
        
        # Save uploaded file
        with open(evidence_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        return JSONResponse({
            "filename": file.filename,
            "evidence_path": evidence_path,
            "timeline_path": timeline_path,
            "status": "queued",
            "message": "Use log2timeline.py manually for processing large files"
        })

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
PYEOF

chown -R plaso:plaso /opt/plaso
chmod +x /opt/plaso/server.py

# Create systemd service
echo "--> Creating systemd service..."
cat > /etc/systemd/system/plaso.service << SVCEOF
[Unit]
Description=Plaso Timeline API
After=network.target

[Service]
Type=simple
User=plaso
Group=plaso
WorkingDirectory=/opt/plaso
ExecStart=/opt/plaso/venv/bin/python /opt/plaso/server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SVCEOF

# Start service
systemctl daemon-reload
systemctl enable plaso
systemctl start plaso

echo "Waiting for Plaso API to start..."
sleep 5

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/plaso.txt << CRED
=== Plaso/log2timeline ===
URL: http://${CONTAINER_IP}:${PLASO_PORT}
Health: http://${CONTAINER_IP}:${PLASO_PORT}/health

CLI Usage:
# Generate timeline
su - plaso
source /opt/plaso/venv/bin/activate
log2timeline.py /opt/plaso/timelines/output.plaso /path/to/evidence

# Export to CSV
psort.py -o l2tcsv -w /opt/plaso/timelines/output.csv /opt/plaso/timelines/output.plaso

# Export to PostgreSQL
psort.py -o postgresql --server 10.0.5.102 --port 5432 --db forensics /opt/plaso/timelines/output.plaso

Evidence: /opt/plaso/evidence/
Timelines: /opt/plaso/timelines/

Service: systemctl status plaso
Logs: journalctl -u plaso -f
CRED

chmod 600 /root/.credentials/plaso.txt

echo "✅ Plaso deployed at http://${CONTAINER_IP}:${PLASO_PORT}"
