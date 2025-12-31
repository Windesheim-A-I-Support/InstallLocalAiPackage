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

# Shared n8n Workflow Automation - NATIVE INSTALLATION
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 21_deploy_shared_n8n_native.sh [--update]

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

# Get PostgreSQL password from environment
POSTGRES_HOST="${POSTGRES_HOST:-10.0.5.102}"
POSTGRES_PASS="${POSTGRES_PASS:-ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8=}"

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating n8n ==="
  sudo -u n8n /opt/n8n/.n8n/node_modules/.bin/npm update -g n8n
  systemctl restart n8n
  echo "✅ n8n updated"
  exit 0
fi

echo "=== n8n Native Deployment ==="

# Install Node.js 20.x
echo "Installing Node.js 20.x..."
apt-get update
apt-get install -y ca-certificates curl gnupg
mkdir -p /etc/apt/keyrings
rm -f /etc/apt/keyrings/nodesource.gpg
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --batch --dearmor -o /etc/apt/keyrings/nodesource.gpg

NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

apt-get update
apt-get install -y nodejs postgresql-client build-essential python3

# Create n8n user
if ! id n8n &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/n8n -m n8n
  echo "✅ Created n8n user"
fi

# Create database
echo "Creating n8n database..."
N8N_DB_PASS=$(openssl rand -base64 32)
PGPASSWORD="$POSTGRES_PASS" psql -h "$POSTGRES_HOST" -U dbadmin -d postgres << EOF
CREATE USER n8n WITH PASSWORD '${N8N_DB_PASS}';
CREATE DATABASE n8n OWNER n8n;
\q
EOF

# Install n8n globally (must be root for global install)
echo "Installing n8n..."
npm install -g n8n

# Generate encryption key
ENCRYPTION_KEY=$(openssl rand -hex 32)

# Create environment file (systemd EnvironmentFile format - no 'export')
mkdir -p /opt/n8n/.n8n
cat > /opt/n8n/.n8n/config << EOF
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://$(hostname -I | awk '{print $1}'):5678/
N8N_ENCRYPTION_KEY=${ENCRYPTION_KEY}

# Database
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=${POSTGRES_HOST}
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=${N8N_DB_PASS}

# Execution
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true

# User management
N8N_USER_MANAGEMENT_DISABLED=false
EOF

chown -R n8n:n8n /opt/n8n
chmod 600 /opt/n8n/.n8n/config

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/n8n.service << 'EOF'
[Unit]
Description=n8n Workflow Automation
After=network.target

[Service]
Type=simple
User=n8n
Group=n8n
WorkingDirectory=/opt/n8n
EnvironmentFile=/opt/n8n/.n8n/config
ExecStart=/usr/bin/n8n
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/n8n

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reload
systemctl enable n8n
systemctl start n8n

# Wait for service to start
echo "Waiting for n8n to start..."
for i in {1..30}; do
  if curl -f http://localhost:5678 >/dev/null 2>&1; then
    echo "✅ n8n is responding"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ n8n failed to start within timeout"
    systemctl status n8n
    exit 1
  fi
  sleep 2
done

# Check if service is running
if systemctl is-active --quiet n8n; then
  echo "✅ n8n service is running"
else
  echo "❌ n8n service failed to start"
  systemctl status n8n
  exit 1
fi

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/n8n.txt << EOF
=== n8n Credentials ===
URL: http://$(hostname -I | awk '{print $1}'):5678

Database: postgresql://n8n:${N8N_DB_PASS}@${POSTGRES_HOST}:5432/n8n
Encryption Key: ${ENCRYPTION_KEY}

Setup:
1. Visit http://$(hostname -I | awk '{print $1}'):5678
2. Create your owner account
3. Start creating workflows!

Service: systemctl status n8n
Logs: journalctl -u n8n -f
Config: /opt/n8n/.n8n/config
Data: /opt/n8n/.n8n/
EOF

chmod 600 /root/.credentials/n8n.txt

echo ""
echo "=========================================="
echo "✅ n8n deployed successfully!"
echo "=========================================="
echo "URL: http://$(hostname -I | awk '{print $1}'):5678"
echo ""
echo "Setup:"
echo "1. Visit the URL above"
echo "2. Create your owner account"
echo "3. Start creating workflows!"
echo ""
echo "Credentials: /root/.credentials/n8n.txt"
echo "Service: systemctl status n8n"
echo "Logs: journalctl -u n8n -f"
echo "=========================================="
