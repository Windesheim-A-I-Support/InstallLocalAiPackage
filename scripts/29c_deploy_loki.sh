#!/bin/bash
set -e

# Loki - Log Aggregation (Native)
# Container: 10.0.5.123
# Usage: bash 29c_deploy_loki.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Loki ==="
  systemctl stop loki
  VERSION=$(curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  wget -q https://github.com/grafana/loki/releases/download/v${VERSION}/loki-linux-amd64.zip
  unzip -o loki-linux-amd64.zip
  mv loki-linux-amd64 /usr/local/bin/loki
  chmod +x /usr/local/bin/loki
  rm loki-linux-amd64.zip
  systemctl start loki
  echo "✅ Loki updated to v$VERSION"
  exit 0
fi

echo "=== Loki Deployment (Native) ==="

# Install dependencies
apt update
apt install -y unzip

# Download Loki
VERSION="3.0.0"
wget https://github.com/grafana/loki/releases/download/v${VERSION}/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
mv loki-linux-amd64 /usr/local/bin/loki
chmod +x /usr/local/bin/loki
rm loki-linux-amd64.zip

# Create user and directories
useradd -r -s /bin/false loki || true
mkdir -p /etc/loki /var/lib/loki/{chunks,index}
chown -R loki:loki /etc/loki /var/lib/loki

# Create configuration
cat > /etc/loki/loki-config.yml << 'EOF'
auth_enabled: false

server:
  http_listen_address: 0.0.0.0
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  instance_addr: 127.0.0.1
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093

analytics:
  reporting_enabled: false
EOF

chown -R loki:loki /etc/loki

# Create systemd service
cat > /etc/systemd/system/loki.service << 'EOF'
[Unit]
Description=Loki Log Aggregation System
After=network.target

[Service]
Type=simple
User=loki
Group=loki
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/loki-config.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable loki
systemctl start loki

echo "✅ Loki deployed (native)"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3100"
echo "Config: /etc/loki/loki-config.yml"
echo "Data: /var/lib/loki"
echo ""
echo "Send logs to Loki:"
echo "  curl -H 'Content-Type: application/json' \\"
echo "    -XPOST http://$(hostname -I | awk '{print $1}'):3100/loki/api/v1/push \\"
echo "    --data '{\"streams\":[{\"stream\":{\"job\":\"test\"},\"values\":[[\"$(date +%s)000000000\",\"test message\"]]}]}'"
echo ""
echo "Query logs via Grafana at http://10.0.5.122:3000"
