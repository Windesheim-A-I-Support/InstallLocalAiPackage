#!/bin/bash
set -e

# Shared Qdrant vector database (native install)
# Shared across multiple Open WebUI instances for RAG

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== Qdrant Shared Service Deployment ==="

# Install Rust (needed for compilation)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Install build dependencies
apt update
apt install -y build-essential pkg-config libssl-dev

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
