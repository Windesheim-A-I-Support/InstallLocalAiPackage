#!/bin/bash
set -e

# Deploy Per-User Container with ALL user services
# This script deploys ONE container per user containing:
#   - Open WebUI, n8n, Jupyter, code-server, big-AGI, ChainForge, Kotaemon, Flowise
#
# Usage: bash 52_deploy_user_container.sh <username> <user_number>
# Example: bash 52_deploy_user_container.sh alice 1
#          This creates container at 10.0.5.200 with all services for alice

USERNAME="${1}"
USER_NUM="${2}"

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

if [ -z "$USERNAME" ] || [ -z "$USER_NUM" ]; then
  echo "❌ Usage: bash 52_deploy_user_container.sh <username> <user_number>"
  echo ""
  echo "Example: bash 52_deploy_user_container.sh alice 1"
  echo "  - Creates container at 10.0.5.200"
  echo "  - Deploys all 8 user services for alice"
  echo ""
  exit 1
fi

# Calculate IP based on user number (200 + user_num)
USER_IP="10.0.5.$((200 + USER_NUM - 1))"
CONTAINER_NAME="user-${USERNAME}"

echo "=== Per-User Container Deployment ==="
echo "User: $USERNAME"
echo "User Number: $USER_NUM"
echo "IP Address: $USER_IP"
echo "Container: $CONTAINER_NAME"
echo ""

# Create directory for user
mkdir -p "/opt/users/${USERNAME}"
cd "/opt/users/${USERNAME}"

# Generate secrets for all services
WEBUI_SECRET=$(openssl rand -base64 32)
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
JUPYTER_TOKEN=$(openssl rand -base64 32)
CODE_SERVER_PASSWORD=$(openssl rand -base64 20)
FLOWISE_PASSWORD=$(openssl rand -base64 20)

# Save secrets to file for user reference
cat > secrets.txt << EOF
=== Secrets for ${USERNAME} ===
Generated: $(date)

Open WebUI:
  URL: http://${USER_IP}:8080
  Secret Key: ${WEBUI_SECRET}
  First user to register becomes admin

n8n:
  URL: http://${USER_IP}:5678
  Encryption Key: ${N8N_ENCRYPTION_KEY}
  First user to register becomes owner

Jupyter Lab:
  URL: http://${USER_IP}:8888
  Token: ${JUPYTER_TOKEN}

code-server:
  URL: http://${USER_IP}:8443
  Password: ${CODE_SERVER_PASSWORD}

big-AGI:
  URL: http://${USER_IP}:3012
  (Browser-based, no authentication)

ChainForge:
  URL: http://${USER_IP}:8000
  (No authentication)

Kotaemon:
  URL: http://${USER_IP}:7860
  (No authentication by default)

Flowise:
  URL: http://${USER_IP}:3000
  Username: admin
  Password: ${FLOWISE_PASSWORD}

=== Shared Services Connection ===
All services connect to shared infrastructure:
  - Ollama: http://10.0.5.100:11434
  - Qdrant: http://10.0.5.101:6333
  - PostgreSQL: 10.0.5.102:5432
  - Redis: 10.0.5.103:6379
  - MinIO: http://10.0.5.104:9000
  - SearXNG: http://10.0.5.105:8080

Database names:
  - PostgreSQL DB: ${USERNAME}_db
  - Qdrant Collection: ${USERNAME}_collection
  - MinIO Bucket: ${USERNAME}-bucket
EOF

chmod 600 secrets.txt

echo "Generating native installation for all user services..."

# Install Python and required packages
apt-get update
apt-get install -y python3 python3-pip python3-venv git

# 1. Open WebUI
echo "Setting up Open WebUI..."
mkdir -p openwebui
cd openwebui
python3 -m venv venv
source venv/bin/activate
pip install open-webui
cat > config.py << EOF
OLLAMA_BASE_URL = "http://10.0.5.100:11434"
VECTOR_DB = "qdrant"
QDRANT_URI = "http://10.0.5.101:6333"
QDRANT_COLLECTION = "${USERNAME}_collection"
DATABASE_URL = "postgresql://dbadmin:POSTGRES_PASSWORD_HERE@10.0.5.102:5432/${USERNAME}_db"
REDIS_URL = "redis://:REDIS_PASSWORD_HERE@10.0.5.103:6379/0"
WEBUI_AUTH = True
WEBUI_SECRET_KEY = "${WEBUI_SECRET}"
ENABLE_SIGNUP = True
DEFAULT_USER_ROLE = "user"
ENABLE_RAG_WEB_SEARCH = True
RAG_WEB_SEARCH_ENGINE = "searxng"
SEARXNG_QUERY_URL = "http://10.0.5.105:8080/search?q=<query>"
EOF

# 2. n8n
echo "Setting up n8n..."
mkdir -p ../n8n
cd ../n8n
python3 -m venv venv
source venv/bin/activate
pip install n8n
cat > config.py << EOF
N8N_ENCRYPTION_KEY = "${N8N_ENCRYPTION_KEY}"
DB_TYPE = "postgresdb"
DB_POSTGRESDB_HOST = "10.0.5.102"
DB_POSTGRESDB_PORT = 5432
DB_POSTGRESDB_DATABASE = "${USERNAME}_n8n"
DB_POSTGRESDB_USER = "dbadmin"
DB_POSTGRESDB_PASSWORD = "POSTGRES_PASSWORD_HERE"
N8N_DIAGNOSTICS_ENABLED = False
N8N_PERSONALIZATION_ENABLED = True
WEBHOOK_URL = "http://${USER_IP}:5678/"
EOF

# 3. Jupyter Lab
echo "Setting up Jupyter Lab..."
mkdir -p ../jupyter
cd ../jupyter
python3 -m venv venv
source venv/bin/activate
pip install jupyter jupyterlab
cat > jupyter_config.py << EOF
c.ServerApp.ip = "0.0.0.0"
c.ServerApp.port = 8888
c.ServerApp.token = "${JUPYTER_TOKEN}"
c.ServerApp.password = ""
c.ServerApp.open_browser = False
c.ServerApp.allow_origin = "*"
EOF

# 4. code-server
echo "Setting up code-server..."
apt-get install -y nodejs npm
npm install -g code-server
cat > code-server-config.yaml << EOF
bind-addr: 0.0.0.0:8443
auth: password
password: ${CODE_SERVER_PASSWORD}
cert: false
EOF

# 5. big-AGI
echo "Setting up big-AGI..."
mkdir -p ../big-agi
cd ../big-agi
python3 -m venv venv
source venv/bin/activate
pip install big-agi
cat > config.py << EOF
OLLAMA_API_HOST = "http://10.0.5.100:11434"
EOF

# 6. ChainForge
echo "Setting up ChainForge..."
mkdir -p ../chainforge
cd ../chainforge
python3 -m venv venv
source venv/bin/activate
pip install chainforge
cat > config.py << EOF
OLLAMA_BASE_URL = "http://10.0.5.100:11434"
EOF

# 7. Kotaemon
echo "Setting up Kotaemon..."
mkdir -p ../kotaemon
cd ../kotaemon
python3 -m venv venv
source venv/bin/activate
pip install kotaemon
cat > config.py << EOF
OLLAMA_BASE_URL = "http://10.0.5.100:11434"
QDRANT_URL = "http://10.0.5.101:6333"
QDRANT_COLLECTION = "${USERNAME}_kotaemon"
GRADIO_SERVER_NAME = "0.0.0.0"
GRADIO_SERVER_PORT = 7860
KT_ENABLE_AUTH = False
KT_ENABLE_SIGNUP = True
EOF

# 8. Flowise
echo "Setting up Flowise..."
mkdir -p ../flowise
cd ../flowise
python3 -m venv venv
source venv/bin/activate
pip install flowise
cat > config.py << EOF
FLOWISE_USERNAME = "admin"
FLOWISE_PASSWORD = "${FLOWISE_PASSWORD}"
DATABASE_TYPE = "postgres"
DATABASE_HOST = "10.0.5.102"
DATABASE_PORT = 5432
DATABASE_USER = "dbadmin"
DATABASE_PASSWORD = "POSTGRES_PASSWORD_HERE"
DATABASE_NAME = "${USERNAME}_flowise"
EOF

# Create systemd services
echo "Creating systemd services..."

# Open WebUI service
cat > /etc/systemd/system/openwebui-${USERNAME}.service << EOF
[Unit]
Description=Open WebUI for ${USERNAME}
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/users/${USERNAME}/openwebui
Environment=PATH=/opt/users/${USERNAME}/openwebui/venv/bin
ExecStart=/opt/users/${USERNAME}/openwebui/venv/bin/python -m open_webui
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# n8n service
cat > /etc/systemd/system/n8n-${USERNAME}.service << EOF
[Unit]
Description=n8n for ${USERNAME}
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/users/${USERNAME}/n8n
Environment=PATH=/opt/users/${USERNAME}/n8n/venv/bin
ExecStart=/opt/users/${USERNAME}/n8n/venv/bin/python -m n8n
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Jupyter service
cat > /etc/systemd/system/jupyter-${USERNAME}.service << EOF
[Unit]
Description=Jupyter Lab for ${USERNAME}
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/users/${USERNAME}/jupyter
Environment=PATH=/opt/users/${USERNAME}/jupyter/venv/bin
ExecStart=/opt/users/${USERNAME}/jupyter/venv/bin/jupyter lab --config=/opt/users/${USERNAME}/jupyter/jupyter_config.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# code-server service
cat > /etc/systemd/system/code-server-${USERNAME}.service << EOF
[Unit]
Description=code-server for ${USERNAME}
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/users/${USERNAME}
ExecStart=/usr/bin/code-server --config=/opt/users/${USERNAME}/code-server-config.yaml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# big-AGI service
cat > /etc/systemd/system/big-agi-${USERNAME}.service << EOF
[Unit]
Description=big-AGI for ${USERNAME}
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/users/${USERNAME}/big-agi
Environment=PATH=/opt/users/${USERNAME}/big-agi/venv/bin
ExecStart=/opt/users/${USERNAME}/big-agi/venv/bin/python -m big_agi
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# ChainForge service
cat > /etc/systemd/system/chainforge-${USERNAME}.service << EOF
[Unit]
Description=ChainForge for ${USERNAME}
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/users/${USERNAME}/chainforge
Environment=PATH=/opt/users/${USERNAME}/chainforge/venv/bin
ExecStart=/opt/users/${USERNAME}/chainforge/venv/bin/python -m chainforge
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Kotaemon service
cat > /etc/systemd/system/kotaemon-${USERNAME}.service << EOF
[Unit]
Description=Kotaemon for ${USERNAME}
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/users/${USERNAME}/kotaemon
Environment=PATH=/opt/users/${USERNAME}/kotaemon/venv/bin
ExecStart=/opt/users/${USERNAME}/kotaemon/venv/bin/python -m kotaemon
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Flowise service
cat > /etc/systemd/system/flowise-${USERNAME}.service << EOF
[Unit]
Description=Flowise for ${USERNAME}
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/users/${USERNAME}/flowise
Environment=PATH=/opt/users/${USERNAME}/flowise/venv/bin
ExecStart=/opt/users/${USERNAME}/flowise/venv/bin/python -m flowise
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable all services
systemctl daemon-reload
systemctl enable openwebui-${USERNAME} n8n-${USERNAME} jupyter-${USERNAME} code-server-${USERNAME} big-agi-${USERNAME} chainforge-${USERNAME} kotaemon-${USERNAME} flowise-${USERNAME}

# Start all services
systemctl start openwebui-${USERNAME} n8n-${USERNAME} jupyter-${USERNAME} code-server-${USERNAME} big-agi-${USERNAME} chainforge-${USERNAME} kotaemon-${USERNAME} flowise-${USERNAME}

echo "✅ All services deployed"
echo ""
echo "⚠️  IMPORTANT: You must edit configuration files and replace:"
echo "     - POSTGRES_PASSWORD_HERE with the actual PostgreSQL password"
echo "     - REDIS_PASSWORD_HERE with the actual Redis password"
echo ""
echo "Next steps:"
echo "  1. Edit configuration files in /opt/users/${USERNAME}/* directories"
echo "  2. Create user-specific databases in PostgreSQL:"
echo "     - ${USERNAME}_db (for Open WebUI)"
echo "     - ${USERNAME}_n8n (for n8n)"
echo "     - ${USERNAME}_flowise (for Flowise)"
echo "  3. Create Qdrant collections:"
echo "     - ${USERNAME}_collection (for Open WebUI)"
echo "     - ${USERNAME}_kotaemon (for Kotaemon)"
echo "  4. Create MinIO bucket: ${USERNAME}-bucket"
echo ""
echo "User credentials saved to: /opt/users/${USERNAME}/secrets.txt"
echo ""
echo "All services for ${USERNAME} will be accessible at:"
echo "  Open WebUI:   http://${USER_IP}:8080"
echo "  n8n:          http://${USER_IP}:5678"
echo "  Jupyter:      http://${USER_IP}:8888"
echo "  code-server:  http://${USER_IP}:8443"
echo "  big-AGI:      http://${USER_IP}:3012"
echo "  ChainForge:   http://${USER_IP}:8000"
echo "  Kotaemon:     http://${USER_IP}:7860"
echo "  Flowise:      http://${USER_IP}:3000"
echo ""
echo "Service management:"
echo "  Start all: systemctl start openwebui-${USERNAME} n8n-${USERNAME} jupyter-${USERNAME} code-server-${USERNAME} big-agi-${USERNAME} chainforge-${USERNAME} kotaemon-${USERNAME} flowise-${USERNAME}"
echo "  Stop all: systemctl stop openwebui-${USERNAME} n8n-${USERNAME} jupyter-${USERNAME} code-server-${USERNAME} big-agi-${USERNAME} chainforge-${USERNAME} kotaemon-${USERNAME} flowise-${USERNAME}"
echo "  Status all: systemctl status openwebui-${USERNAME} n8n-${USERNAME} jupyter-${USERNAME} code-server-${USERNAME} big-agi-${USERNAME} chainforge-${USERNAME} kotaemon-${USERNAME} flowise-${USERNAME}"
echo "  Logs: journalctl -u openwebui-${USERNAME} -f"
