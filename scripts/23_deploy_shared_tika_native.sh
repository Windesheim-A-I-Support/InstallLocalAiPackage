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

# Shared Apache Tika Document Parser - NATIVE INSTALLATION
# Usage: bash 23_deploy_shared_tika_native.sh [--update]

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

TIKA_VERSION="3.0.0"

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Apache Tika ==="
  cd /opt/tika
  wget -O tika-server.jar "https://archive.apache.org/dist/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar"
  systemctl restart tika
  echo "✅ Tika updated to version ${TIKA_VERSION}"
  exit 0
fi

echo "=== Apache Tika Native Deployment ==="

# Install Java (Tika requires Java 11+)
echo "Installing Java 17..."
apt-get update
apt-get install -y openjdk-17-jre-headless wget curl

# Create tika user
if ! id tika &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/tika -m tika
  echo "✅ Created tika user"
fi

# Create directory
mkdir -p /opt/tika
cd /opt/tika

# Download Tika Server
echo "Downloading Apache Tika Server ${TIKA_VERSION}..."
wget -O tika-server.jar "https://archive.apache.org/dist/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar"

chown -R tika:tika /opt/tika

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/tika.service << 'EOF'
[Unit]
Description=Apache Tika Server
After=network.target

[Service]
Type=simple
User=tika
Group=tika
WorkingDirectory=/opt/tika
ExecStart=/usr/bin/java -jar /opt/tika/tika-server.jar --host 0.0.0.0 --port 9998
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/tika

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reload
systemctl enable tika
systemctl start tika

# Wait for service to start
echo "Waiting for Tika to start..."
for i in {1..30}; do
  if curl -f http://localhost:9998/tika >/dev/null 2>&1; then
    echo "✅ Tika is responding"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Tika failed to start within timeout"
    systemctl status tika
    exit 1
  fi
  sleep 2
done

# Check if service is running
if systemctl is-active --quiet tika; then
  echo "✅ Tika service is running"
else
  echo "❌ Tika service failed to start"
  systemctl status tika
  exit 1
fi

# Test the service
TIKA_VERSION_OUTPUT=$(curl -s http://localhost:9998/version)
echo "Tika version: $TIKA_VERSION_OUTPUT"

# Save information
mkdir -p /root/.credentials
cat > /root/.credentials/tika.txt << EOF
=== Apache Tika Server ===
URL: http://$(hostname -I | awk '{print $1}'):9998
Version Endpoint: http://$(hostname -I | awk '{print $1}'):9998/version
Tika Endpoint: http://$(hostname -I | awk '{print $1}'):9998/tika

Version: $TIKA_VERSION_OUTPUT

Usage Examples:
# Extract text from document
curl -T document.pdf http://$(hostname -I | awk '{print $1}'):9998/tika

# Get metadata
curl -T document.pdf http://$(hostname -I | awk '{print $1}'):9998/meta

# Detect content type
curl -T document.pdf http://$(hostname -I | awk '{print $1}'):9998/detect/stream

Service: systemctl status tika
Logs: journalctl -u tika -f
JAR: /opt/tika/tika-server.jar
EOF

chmod 600 /root/.credentials/tika.txt

echo ""
echo "=========================================="
echo "✅ Apache Tika deployed successfully!"
echo "=========================================="
echo "URL: http://$(hostname -I | awk '{print $1}'):9998"
echo "Version: $TIKA_VERSION_OUTPUT"
echo ""
echo "Test: curl http://$(hostname -I | awk '{print $1}'):9998/version"
echo "Credentials: /root/.credentials/tika.txt"
echo "Service: systemctl status tika"
echo "Logs: journalctl -u tika -f"
echo "=========================================="
