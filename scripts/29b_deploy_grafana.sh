#!/bin/bash
set -e

# Grafana - Visualization Dashboard (Native)
# Container: 10.0.5.122
# Usage: bash 29b_deploy_grafana.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Grafana ==="
  apt update
  apt install --only-upgrade grafana -y
  systemctl restart grafana-server
  echo "✅ Grafana updated"
  exit 0
fi

echo "=== Grafana Deployment (Native) ==="

# Add Grafana APT repository
apt update
apt install -y apt-transport-https software-properties-common wget

# Add GPG key
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null

# Add repository
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

# Install Grafana
apt update
apt install grafana -y

# Configure Grafana
cat >> /etc/grafana/grafana.ini << 'EOF'

[server]
http_addr = 0.0.0.0
http_port = 3000

[security]
admin_user = admin
admin_password = admin

[auth.anonymous]
enabled = false
EOF

# Enable and start
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

# Wait for Grafana to start
sleep 5

# Add Prometheus datasource
cat > /tmp/datasource.json << 'EOF'
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://10.0.5.121:9090",
  "access": "proxy",
  "isDefault": true
}
EOF

curl -X POST http://admin:admin@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d @/tmp/datasource.json || echo "Datasource might already exist"

# Add Loki datasource
cat > /tmp/loki-datasource.json << 'EOF'
{
  "name": "Loki",
  "type": "loki",
  "url": "http://10.0.5.123:3100",
  "access": "proxy"
}
EOF

curl -X POST http://admin:admin@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d @/tmp/loki-datasource.json || echo "Loki datasource might already exist"

rm /tmp/datasource.json /tmp/loki-datasource.json

echo "✅ Grafana deployed (native)"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3000"
echo "Username: admin"
echo "Password: admin"
echo ""
echo "Datasources configured:"
echo "  - Prometheus: http://10.0.5.121:9090"
echo "  - Loki: http://10.0.5.123:3100"
echo ""
echo "⚠️  Change the admin password after first login!"
