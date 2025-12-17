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

# Shared LibreTranslate Machine Translation - NATIVE INSTALLATION
# Usage: bash 26_deploy_shared_libretranslate_native.sh [--update]

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
  echo "=== Updating LibreTranslate ==="
  cd /opt/libretranslate
  sudo -u libretranslate /opt/libretranslate/venv/bin/pip install --upgrade libretranslate
  systemctl restart libretranslate
  echo "✅ LibreTranslate updated"
  exit 0
fi

echo "=== LibreTranslate Native Deployment ==="

# Install Python and dependencies
echo "Installing Python and dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git curl build-essential

# Create libretranslate user
if ! id libretranslate &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/libretranslate -m libretranslate
  echo "✅ Created libretranslate user"
fi

# Create directory and virtual environment
mkdir -p /opt/libretranslate
mkdir -p /opt/libretranslate/data
chown -R libretranslate:libretranslate /opt/libretranslate
cd /opt/libretranslate

# Create virtual environment
echo "Creating Python virtual environment..."
su -s /bin/bash -c "python3 -m venv /opt/libretranslate/venv" libretranslate

# Install LibreTranslate
echo "Installing LibreTranslate (this may take several minutes)..."
su -s /bin/bash -c "/opt/libretranslate/venv/bin/pip install --upgrade pip" libretranslate
su -s /bin/bash -c "/opt/libretranslate/venv/bin/pip install libretranslate" libretranslate

# Generate API key
API_KEY=$(openssl rand -hex 32)

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/libretranslate.service << EOF
[Unit]
Description=LibreTranslate Machine Translation API
After=network.target

[Service]
Type=simple
User=libretranslate
Group=libretranslate
WorkingDirectory=/opt/libretranslate
Environment="LT_HOST=0.0.0.0"
Environment="LT_PORT=5000"
Environment="LT_API_KEYS=true"
Environment="LT_REQUIRE_API_KEY_SECRET=${API_KEY}"
Environment="LT_LOAD_ONLY=en,es,fr,de,it,pt,nl,ru,ja,zh,ar"
ExecStart=/opt/libretranslate/venv/bin/libretranslate
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/libretranslate

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reload
systemctl enable libretranslate
systemctl start libretranslate

# Wait for service to start (LibreTranslate downloads models on first start, so this can take a while)
echo "Waiting for LibreTranslate to start (this may take several minutes on first run)..."
echo "LibreTranslate is downloading language models..."
for i in {1..120}; do
  if curl -f http://localhost:5000/languages >/dev/null 2>&1; then
    echo "✅ LibreTranslate is responding"
    break
  fi
  if [ $i -eq 120 ]; then
    echo "⚠️  LibreTranslate may still be downloading models"
    echo "Check logs: journalctl -u libretranslate -f"
  fi
  sleep 5
done

# Check if service is running
if systemctl is-active --quiet libretranslate; then
  echo "✅ LibreTranslate service is running"
else
  echo "❌ LibreTranslate service failed to start"
  systemctl status libretranslate
  exit 1
fi

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/libretranslate.txt << EOF
=== LibreTranslate Credentials ===
URL: http://$(hostname -I | awk '{print $1}'):5000
API Key: ${API_KEY}

Usage Examples:
# List available languages
curl http://$(hostname -I | awk '{print $1}'):5000/languages

# Translate text (with API key)
curl -X POST http://$(hostname -I | awk '{print $1}'):5000/translate \\
  -H "Content-Type: application/json" \\
  -d '{
    "q": "Hello world",
    "source": "en",
    "target": "es",
    "api_key": "${API_KEY}"
  }'

# Detect language
curl -X POST http://$(hostname -I | awk '{print $1}'):5000/detect \\
  -H "Content-Type: application/json" \\
  -d '{
    "q": "Hello world",
    "api_key": "${API_KEY}"
  }'

Supported Languages: en, es, fr, de, it, pt, nl, ru, ja, zh, ar

Service: systemctl status libretranslate
Logs: journalctl -u libretranslate -f
Data: /opt/libretranslate/data
EOF

chmod 600 /root/.credentials/libretranslate.txt

echo ""
echo "=========================================="
echo "✅ LibreTranslate deployed successfully!"
echo "=========================================="
echo "URL: http://$(hostname -I | awk '{print $1}'):5000"
echo "API Key: ${API_KEY}"
echo ""
echo "Note: LibreTranslate may still be downloading language models"
echo "Monitor progress: journalctl -u libretranslate -f"
echo ""
echo "Credentials: /root/.credentials/libretranslate.txt"
echo "Service: systemctl status libretranslate"
echo "=========================================="
