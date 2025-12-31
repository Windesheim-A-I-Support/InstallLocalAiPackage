#!/bin/bash
set -e

# ==============================================================================
# JUPYTER LAB NATIVE DEPLOYMENT - For Forensic Data Analysis
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.124}"
JUPYTER_PORT="${2:-8888}"

echo "========================================================="
echo "   JUPYTER LAB DEPLOYMENT"
echo "========================================================="
echo "Container: ${CONTAINER_IP}"
echo "Port: ${JUPYTER_PORT}"
echo ""

export DEBIAN_FRONTEND=noninteractive

# Install Python and dependencies
echo "--> Installing Python and dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git curl build-essential

# Create jupyter user
if ! id jupyter &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/jupyter -m jupyter
fi

# Create directory
mkdir -p /opt/jupyter/notebooks
cd /opt/jupyter

# Create virtual environment
echo "--> Creating Python virtual environment..."
su -s /bin/bash -c "python3 -m venv /opt/jupyter/venv" jupyter

# Install JupyterLab and forensic packages
echo "--> Installing JupyterLab and data science packages (this may take several minutes)..."
su -s /bin/bash -c "/opt/jupyter/venv/bin/pip install --upgrade pip" jupyter
su -s /bin/bash -c "/opt/jupyter/venv/bin/pip install jupyterlab pandas numpy matplotlib seaborn scipy scikit-learn networkx plotly ipywidgets" jupyter

# Install database drivers
echo "--> Installing database drivers..."
su -s /bin/bash -c "/opt/jupyter/venv/bin/pip install psycopg2-binary redis pymongo neo4j qdrant-client" jupyter

# Generate Jupyter config
echo "--> Configuring JupyterLab..."
su -s /bin/bash -c "/opt/jupyter/venv/bin/jupyter lab --generate-config" jupyter

# Generate password hash (default: 'jupyter')
PASSWORD_HASH='argon2:$argon2id$v=19$m=10240,t=10,p=8$VGhpc0lzQVNhbHQ$8vxZ+RqXfJ4lOy5ld8xKzQ'

# Configure Jupyter
cat > /opt/jupyter/.jupyter/jupyter_lab_config.py << 'JUPCONFIG'
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_root = False
c.ServerApp.password = 'argon2:$argon2id$v=19$m=10240,t=10,p=8$VGhpc0lzQVNhbHQ$8vxZ+RqXfJ4lOy5ld8xKzQ'
c.ServerApp.notebook_dir = '/opt/jupyter/notebooks'
JUPCONFIG

chown -R jupyter:jupyter /opt/jupyter

# Create systemd service
echo "--> Creating systemd service..."
cat > /etc/systemd/system/jupyter.service << JUPSERVICE
[Unit]
Description=Jupyter Lab Server
After=network.target

[Service]
Type=simple
User=jupyter
Group=jupyter
WorkingDirectory=/opt/jupyter
ExecStart=/opt/jupyter/venv/bin/jupyter lab --config=/opt/jupyter/.jupyter/jupyter_lab_config.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
JUPSERVICE

# Start service
systemctl daemon-reload
systemctl enable jupyter
systemctl start jupyter

echo "Waiting for JupyterLab to start..."
sleep 5

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/jupyter.txt << CRED
=== Jupyter Lab ===
URL: http://${CONTAINER_IP}:${JUPYTER_PORT}
Password: jupyter

Service: systemctl status jupyter
Logs: journalctl -u jupyter -f

Installed Packages:
- jupyterlab, pandas, numpy, matplotlib, seaborn
- scipy, scikit-learn, networkx, plotly
- Database drivers: psycopg2, redis, neo4j, qdrant-client

Change password:
jupyter lab password
CRED

chmod 600 /root/.credentials/jupyter.txt

echo "✅ Jupyter Lab deployed at http://${CONTAINER_IP}:${JUPYTER_PORT}"
echo "   Password: jupyter (change after first login)"
