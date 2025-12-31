#!/bin/bash
set -e

# ==============================================================================
# VOLATILITY3 NATIVE DEPLOYMENT - Memory Forensics Framework
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.133}"
VOLATILITY_PORT="${2:-8000}"

echo "========================================================="
echo "   VOLATILITY3 DEPLOYMENT"
echo "========================================================="
echo "Container: ${CONTAINER_IP}"
echo "Port: ${VOLATILITY_PORT}"
echo ""

export DEBIAN_FRONTEND=noninteractive

# Install Python and dependencies
echo "--> Installing Python and dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git curl build-essential \
    python3-dev

# Create volatility user
if ! id volatility &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/volatility -m volatility
fi

# Create directory
mkdir -p /opt/volatility/dumps /opt/volatility/analysis
cd /opt/volatility

# Clone Volatility3
echo "--> Cloning Volatility3..."
su -s /bin/bash -c "git clone https://github.com/volatilityfoundation/volatility3.git /opt/volatility/volatility3" volatility

# Create virtual environment
echo "--> Creating Python virtual environment..."
su -s /bin/bash -c "python3 -m venv /opt/volatility/venv" volatility

# Install Volatility3
echo "--> Installing Volatility3 (this may take several minutes)..."
su -s /bin/bash -c "/opt/volatility/venv/bin/pip install --upgrade pip" volatility
su -s /bin/bash -c "cd /opt/volatility/volatility3 && /opt/volatility/venv/bin/pip install -r requirements.txt" volatility
su -s /bin/bash -c "/opt/volatility/venv/bin/pip install fastapi uvicorn python-multipart psycopg2-binary" volatility

# Create API server
echo "--> Creating Volatility API server..."
cat > /opt/volatility/server.py << 'PYEOF'
#!/usr/bin/env python3
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import os

app = FastAPI(title="Volatility3 Memory Forensics API")

@app.get("/")
async def root():
    return {"service": "Volatility3", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "tool": "volatility3"}

@app.get("/plugins")
async def list_plugins():
    """List available Volatility3 plugins"""
    return {
        "categories": {
            "windows": ["pslist", "pstree", "dlllist", "handles", "cmdline", "netscan"],
            "linux": ["pslist", "bash", "lsof", "check_syscall"],
            "mac": ["pslist", "bash", "lsmod"]
        }
    }

@app.post("/upload")
async def upload_memory_dump(file: UploadFile = File(...)):
    """Upload memory dump for analysis"""
    try:
        dump_path = f"/opt/volatility/dumps/{file.filename}"
        
        with open(dump_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        return JSONResponse({
            "filename": file.filename,
            "path": dump_path,
            "size": os.path.getsize(dump_path),
            "status": "uploaded",
            "message": "Use CLI for analysis: vol3 -f /opt/volatility/dumps/<file> <plugin>"
        })

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
PYEOF

chown -R volatility:volatility /opt/volatility
chmod +x /opt/volatility/server.py

# Create systemd service
echo "--> Creating systemd service..."
cat > /etc/systemd/system/volatility.service << SVCEOF
[Unit]
Description=Volatility3 Memory Forensics API
After=network.target

[Service]
Type=simple
User=volatility
Group=volatility
WorkingDirectory=/opt/volatility
ExecStart=/opt/volatility/venv/bin/python /opt/volatility/server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SVCEOF

# Start service
systemctl daemon-reload
systemctl enable volatility
systemctl start volatility

echo "Waiting for Volatility API to start..."
sleep 5

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/volatility.txt << CRED
=== Volatility3 ===
URL: http://${CONTAINER_IP}:${VOLATILITY_PORT}
Health: http://${CONTAINER_IP}:${VOLATILITY_PORT}/health
Plugins: http://${CONTAINER_IP}:${VOLATILITY_PORT}/plugins

CLI Usage:
su - volatility
source /opt/volatility/venv/bin/activate
cd /opt/volatility/volatility3

# List processes
python3 vol.py -f /opt/volatility/dumps/memory.raw windows.pslist

# Network connections
python3 vol.py -f /opt/volatility/dumps/memory.raw windows.netscan

# Command line
python3 vol.py -f /opt/volatility/dumps/memory.raw windows.cmdline

Dumps: /opt/volatility/dumps/
Analysis: /opt/volatility/analysis/

Service: systemctl status volatility
Logs: journalctl -u volatility -f
CRED

chmod 600 /root/.credentials/volatility.txt

echo "✅ Volatility3 deployed at http://${CONTAINER_IP}:${VOLATILITY_PORT}"
