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

# Shared Flowise LLM Flow Builder - NATIVE INSTALLATION
# Usage: bash 22_deploy_shared_flowise_native.sh [--update]

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
  echo "=== Updating Flowise ==="
  sudo -u flowise npm update -g flowise
  systemctl restart flowise
  echo "✅ Flowise updated"
  exit 0
fi

echo "=== Flowise Native Deployment ==="

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
apt-get install -y nodejs python3 make g++

# Create flowise user
if ! id flowise &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/flowise -m flowise
  echo "✅ Created flowise user"
fi

# Install Flowise globally (must be root for global install)
echo "Installing Flowise..."
npm install -g flowise

# Create data directory
mkdir -p /opt/flowise/.flowise
chown -R flowise:flowise /opt/flowise

# Generate credentials
FLOWISE_USERNAME="admin"
FLOWISE_PASSWORD=$(openssl rand -base64 16)
FLOWISE_SECRETKEY=$(openssl rand -hex 32)

# Create environment file
cat > /opt/flowise/.flowise/config << EOF
export PORT=3003
export FLOWISE_USERNAME=${FLOWISE_USERNAME}
export FLOWISE_PASSWORD=${FLOWISE_PASSWORD}
export FLOWISE_SECRETKEY_OVERWRITE=${FLOWISE_SECRETKEY}
export DATABASE_PATH=/opt/flowise/.flowise
export APIKEY_PATH=/opt/flowise/.flowise
export LOG_PATH=/opt/flowise/.flowise/logs
export BLOB_STORAGE_PATH=/opt/flowise/.flowise/storage
export CORS_ORIGINS=*
EOF

chown flowise:flowise /opt/flowise/.flowise/config
chmod 600 /opt/flowise/.flowise/config

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/flowise.service << 'EOF'
[Unit]
Description=Flowise LLM Flow Builder
After=network.target

[Service]
Type=simple
User=flowise
Group=flowise
WorkingDirectory=/opt/flowise
EnvironmentFile=/opt/flowise/.flowise/config
ExecStart=/usr/bin/npx flowise start
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/flowise

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reload
systemctl enable flowise
systemctl start flowise

# Wait for service to start
echo "Waiting for Flowise to start..."
for i in {1..30}; do
  if curl -f http://localhost:3003 >/dev/null 2>&1; then
    echo "✅ Flowise is responding"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Flowise failed to start within timeout"
    systemctl status flowise
    exit 1
  fi
  sleep 2
done

# Check if service is running
if systemctl is-active --quiet flowise; then
  echo "✅ Flowise service is running"
else
  echo "❌ Flowise service failed to start"
  systemctl status flowise
  exit 1
fi

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/flowise.txt << EOF
=== Flowise Credentials ===
URL: http://$(hostname -I | awk '{print $1}'):3003

Login:
Username: ${FLOWISE_USERNAME}
Password: ${FLOWISE_PASSWORD}

Secret Key: ${FLOWISE_SECRETKEY}

Service: systemctl status flowise
Logs: journalctl -u flowise -f
Config: /opt/flowise/.flowise/config
Data: /opt/flowise/.flowise/
EOF

chmod 600 /root/.credentials/flowise.txt

echo ""
echo "=========================================="
echo "✅ Flowise deployed successfully!"
echo "=========================================="
echo "URL: http://$(hostname -I | awk '{print $1}'):3003"
echo ""
echo "Login:"
echo "  Username: ${FLOWISE_USERNAME}"
echo "  Password: ${FLOWISE_PASSWORD}"
echo ""
echo "Credentials: /root/.credentials/flowise.txt"
echo "Service: systemctl status flowise"
echo "Logs: journalctl -u flowise -f"
echo "=========================================="
