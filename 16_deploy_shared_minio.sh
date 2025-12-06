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

# Shared MinIO S3-compatible storage
# Usage: bash 16_deploy_shared_minio.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating MinIO ==="
  systemctl stop minio
  wget -q https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio
  chmod +x /usr/local/bin/minio
  systemctl start minio
  echo "✅ MinIO updated"
  exit 0
fi

echo "=== MinIO Shared Service Deployment ==="

# Download MinIO
wget -q https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio
chmod +x /usr/local/bin/minio

# Create user and directories
useradd -r -s /bin/false minio || true
mkdir -p /var/lib/minio/data
chown -R minio:minio /var/lib/minio

# Generate credentials
ROOT_USER="admin"
ROOT_PASS=$(openssl rand -base64 32)

# Create environment file
cat > /etc/default/minio << EOF
MINIO_ROOT_USER=$ROOT_USER
MINIO_ROOT_PASSWORD=$ROOT_PASS
MINIO_VOLUMES=/var/lib/minio/data
MINIO_OPTS="--console-address :9001"
EOF

# Create systemd service
cat > /etc/systemd/system/minio.service << 'EOF'
[Unit]
Description=MinIO Object Storage
After=network.target

[Service]
Type=notify
User=minio
Group=minio
EnvironmentFile=/etc/default/minio
ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable minio
systemctl start minio

echo "✅ MinIO deployed"
echo ""
echo "API: http://$(hostname -I | awk '{print $1}'):9000"
echo "Console: http://$(hostname -I | awk '{print $1}'):9001"
echo "User: $ROOT_USER"
echo "Password: $ROOT_PASS"
echo ""
echo "Connect from Open WebUI:"
echo "  S3_ENDPOINT_URL=http://$(hostname -I | awk '{print $1}'):9000"
echo "  S3_ACCESS_KEY_ID=$ROOT_USER"
echo "  S3_SECRET_ACCESS_KEY=$ROOT_PASS"
