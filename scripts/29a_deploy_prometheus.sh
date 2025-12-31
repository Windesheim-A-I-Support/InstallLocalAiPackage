#!/bin/bash
set -e

# Prometheus - Metrics Collection (Native)
# Container: 10.0.5.121
# Usage: bash 29a_deploy_prometheus.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Prometheus ==="
  systemctl stop prometheus
  VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  wget -q https://github.com/prometheus/prometheus/releases/download/v${VERSION}/prometheus-${VERSION}.linux-amd64.tar.gz
  tar xzf prometheus-${VERSION}.linux-amd64.tar.gz
  cp prometheus-${VERSION}.linux-amd64/prometheus /usr/local/bin/
  cp prometheus-${VERSION}.linux-amd64/promtool /usr/local/bin/
  rm -rf prometheus-${VERSION}.linux-amd64*
  systemctl start prometheus
  echo "✅ Prometheus updated to v$VERSION"
  exit 0
fi

echo "=== Prometheus Deployment (Native) ==="

# Download latest Prometheus
VERSION="2.54.1"
wget https://github.com/prometheus/prometheus/releases/download/v${VERSION}/prometheus-${VERSION}.linux-amd64.tar.gz
tar xzf prometheus-${VERSION}.linux-amd64.tar.gz

# Install binaries
cp prometheus-${VERSION}.linux-amd64/prometheus /usr/local/bin/
cp prometheus-${VERSION}.linux-amd64/promtool /usr/local/bin/
chmod +x /usr/local/bin/prometheus /usr/local/bin/promtool

# Create user and directories
useradd -r -s /bin/false prometheus || true
mkdir -p /etc/prometheus /var/lib/prometheus
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Copy console files
cp -r prometheus-${VERSION}.linux-amd64/consoles /etc/prometheus/
cp -r prometheus-${VERSION}.linux-amd64/console_libraries /etc/prometheus/
rm -rf prometheus-${VERSION}.linux-amd64*

# Create configuration
cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'shared-monitor'

# Scrape configurations
scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          instance: 'prometheus'

  # Add other services here
  - job_name: 'shared-services'
    static_configs:
      - targets:
          - '10.0.5.100:11434'  # Ollama
          - '10.0.5.101:6333'   # Qdrant
          - '10.0.5.102:5432'   # PostgreSQL
          - '10.0.5.103:6379'   # Redis
          - '10.0.5.104:9000'   # MinIO
        labels:
          group: 'infrastructure'
EOF

chown -R prometheus:prometheus /etc/prometheus

# Create systemd service
cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus Monitoring System
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

echo "✅ Prometheus deployed (native)"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):9090"
echo "Config: /etc/prometheus/prometheus.yml"
echo "Data: /var/lib/prometheus"
echo ""
echo "Add scrape targets to /etc/prometheus/prometheus.yml"
echo "Then reload: systemctl reload prometheus"
