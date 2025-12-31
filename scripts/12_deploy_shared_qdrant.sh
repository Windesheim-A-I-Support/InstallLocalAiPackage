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

# Shared Qdrant vector database (native install)
# Usage: bash 12_deploy_shared_qdrant.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Qdrant ==="
  systemctl stop qdrant
  cp /usr/local/bin/qdrant /usr/local/bin/qdrant.backup
  VERSION=$(curl -s https://api.github.com/repos/qdrant/qdrant/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  wget -q https://github.com/qdrant/qdrant/releases/download/v${VERSION}/qdrant-x86_64-unknown-linux-musl.tar.gz
  tar xzf qdrant-x86_64-unknown-linux-musl.tar.gz
  mv qdrant /usr/local/bin/
  chmod +x /usr/local/bin/qdrant
  rm qdrant-x86_64-unknown-linux-musl.tar.gz
  systemctl start qdrant
  echo "✅ Qdrant updated to v$VERSION"
  exit 0
fi

echo "=== Qdrant Shared Service Deployment ==="

# Install build dependencies
apt update
apt install -y build-essential pkg-config libssl-dev wget

# Download and install Qdrant
VERSION="1.12.5"
wget https://github.com/qdrant/qdrant/releases/download/v${VERSION}/qdrant-x86_64-unknown-linux-musl.tar.gz
tar xzf qdrant-x86_64-unknown-linux-musl.tar.gz
mv qdrant /usr/local/bin/
chmod +x /usr/local/bin/qdrant

# Create data directory
mkdir -p /var/lib/qdrant
useradd -r -s /bin/false qdrant || true
chown -R qdrant:qdrant /var/lib/qdrant

# Create systemd service
cat > /etc/systemd/system/qdrant.service << 'EOF'
[Unit]
Description=Qdrant Vector Database
After=network.target

[Service]
Type=simple
User=qdrant
WorkingDirectory=/var/lib/qdrant
ExecStart=/usr/local/bin/qdrant --config-path /etc/qdrant/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Create config
mkdir -p /etc/qdrant
cat > /etc/qdrant/config.yaml << 'EOF'
service:
  host: 0.0.0.0
  http_port: 6333
  grpc_port: 6334

storage:
  storage_path: /var/lib/qdrant/storage
  snapshots_path: /var/lib/qdrant/snapshots
EOF

chown -R qdrant:qdrant /etc/qdrant

systemctl daemon-reload
systemctl enable qdrant
systemctl start qdrant

echo "✅ Qdrant deployed at port 6333"
echo ""
echo "Connect from Open WebUI:"
echo "  QDRANT_URI=http://$(hostname -I | awk '{print $1}'):6333"
echo ""
echo "Dashboard: http://$(hostname -I | awk '{print $1}'):6333/dashboard"
