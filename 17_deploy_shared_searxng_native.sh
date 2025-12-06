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

# Shared SearXNG meta-search engine (NATIVE installation)
# Usage: bash 17_deploy_shared_searxng_native.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating SearXNG ==="
  cd /opt/searxng
  sudo -u searxng bash << 'EOSCRIPT'
source venv/bin/activate
pip install --upgrade searxng
EOSCRIPT
  systemctl restart searxng
  echo "✅ SearXNG updated"
  exit 0
fi

echo "=== SearXNG Native Service Deployment ==="

# Install dependencies
apt update
apt install -y python3 python3-pip python3-venv python3-dev \
  uwsgi uwsgi-plugin-python3 git build-essential \
  libxslt-dev zlib1g-dev libffi-dev libssl-dev

# Create user
useradd -r -s /bin/false searxng || true

# Create directories
mkdir -p /opt/searxng
cd /opt/searxng

# Clone SearXNG
if [ ! -d "searxng-src" ]; then
  git clone https://github.com/searxng/searxng.git searxng-src
fi

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install SearXNG
cd searxng-src
pip install --upgrade pip setuptools wheel
pip install -e .

# Generate secret
SECRET=$(openssl rand -hex 32)

# Create settings
mkdir -p /etc/searxng
cat > /etc/searxng/settings.yml << EOF
use_default_settings: true

general:
  instance_name: "Shared Search"
  contact_url: false

search:
  safe_search: 0
  autocomplete: "google"
  default_lang: "en"

server:
  secret_key: "$SECRET"
  bind_address: "0.0.0.0"
  port: 8080
  base_url: false
  image_proxy: true

ui:
  static_use_hash: true
  default_theme: simple
  default_locale: en

enabled_plugins:
  - 'Hash plugin'
  - 'Search on category select'
  - 'Self Information'
  - 'Tracker URL remover'
  - 'Ahmia blacklist'

engines:
  - name: google
    disabled: false
  - name: duckduckgo
    disabled: false
  - name: wikipedia
    disabled: false
  - name: github
    disabled: false
EOF

chown -R searxng:searxng /opt/searxng
chown -R searxng:searxng /etc/searxng

# Create systemd service
cat > /etc/systemd/system/searxng.service << 'EOF'
[Unit]
Description=SearXNG Meta Search Engine
After=network.target

[Service]
Type=simple
User=searxng
Group=searxng
WorkingDirectory=/opt/searxng/searxng-src
Environment="SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml"
ExecStart=/opt/searxng/venv/bin/python /opt/searxng/searxng-src/searx/webapp.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable searxng
systemctl start searxng

echo "✅ SearXNG deployed (native)"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):8080"
echo "Secret: $SECRET"
echo ""
echo "Connect from Open WebUI:"
echo "  RAG_WEB_SEARCH_ENGINE=searxng"
echo "  SEARXNG_QUERY_URL=http://$(hostname -I | awk '{print $1}'):8080/search?q=<query>"
echo ""
echo "Configuration: /etc/searxng/settings.yml"
echo "Service: systemctl status searxng"
