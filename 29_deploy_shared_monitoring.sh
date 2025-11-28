#!/bin/bash
set -e

# Shared Monitoring Stack (Prometheus + Grafana + Loki)
# Usage: bash 29_deploy_shared_monitoring.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Monitoring Stack ==="
  cd /opt/monitoring
  docker compose pull
  docker compose up -d
  echo "✅ Monitoring updated"
  exit 0
fi

echo "=== Monitoring Stack Deployment ==="

mkdir -p /opt/monitoring/{prometheus,grafana,loki}
cd /opt/monitoring

# Prometheus config
cat > prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

# Loki config
cat > loki/loki-config.yml << 'EOF'
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb:
    directory: /loki/index
  filesystem:
    directory: /loki/chunks
EOF

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus-shared
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana-shared
    restart: unless-stopped
    ports:
      - "3004:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
      GF_INSTALL_PLUGINS: grafana-piechart-panel
    volumes:
      - grafana-data:/var/lib/grafana

  loki:
    image: grafana/loki:latest
    container_name: loki-shared
    restart: unless-stopped
    ports:
      - "3100:3100"
    volumes:
      - ./loki:/etc/loki
      - loki-data:/loki
    command: -config.file=/etc/loki/loki-config.yml

volumes:
  prometheus-data:
  grafana-data:
  loki-data:
EOF

docker compose up -d

echo "✅ Monitoring Stack deployed"
echo ""
echo "Prometheus: http://$(hostname -I | awk '{print $1}'):9090"
echo "Grafana: http://$(hostname -I | awk '{print $1}'):3004 (admin/admin)"
echo "Loki: http://$(hostname -I | awk '{print $1}'):3100"
