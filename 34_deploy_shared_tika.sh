#!/bin/bash
set -e

# ==============================================================================
# APACHE TIKA SERVER NATIVE DEPLOYMENT
# ==============================================================================
# Based on official Apache Tika documentation
# Sources:
#   - https://tika.apache.org/download.html
#   - https://cwiki.apache.org/confluence/display/TIKA/TikaServer
#   - https://github.com/apache/tika/tree/master/tika-server
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.111}"
TIKA_VERSION="${2:-3.2.3}"
TIKA_PORT="${3:-9998}"
TIKA_USER="tika"
TIKA_HOME="/opt/tika"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   APACHE TIKA SERVER DEPLOYMENT"
echo "========================================================="
echo ""
echo "This deploys:"
echo "  • Apache Tika Server v${TIKA_VERSION}"
echo "  • Text and metadata extraction service"
echo "  • Systemd service"
echo ""
echo "Container: ${CONTAINER_IP}"
echo "Access at: http://${CONTAINER_IP}:${TIKA_PORT}"
echo ""
echo ""

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# STEP 1: INSTALL JAVA 21
# ==============================================================================
echo "--> [1/6] Installing Java 21..."

apt-get update
apt-get install -y openjdk-21-jre-headless wget curl unzip

# Verify Java installation
JAVA_VERSION=$(java -version 2>&1 | head -n1)
echo "✅ Java installed: $JAVA_VERSION"

# ==============================================================================
# STEP 2: CREATE TIKA USER
# ==============================================================================
echo "--> [2/6] Creating Tika user..."

if ! id -u "$TIKA_USER" >/dev/null 2>&1; then
    useradd --system --shell /bin/false --home-dir "$TIKA_HOME" \
            --create-home "$TIKA_USER"
    echo "✅ User created: $TIKA_USER"
else
    echo "ℹ️  User already exists: $TIKA_USER"
fi

# ==============================================================================
# STEP 3: DOWNLOAD TIKA SERVER
# ==============================================================================
echo "--> [3/6] Downloading Tika Server v${TIKA_VERSION}..."

mkdir -p "$TIKA_HOME"
cd "$TIKA_HOME"

# Download Tika Server JAR (using IPv4 to avoid network issues)
TIKA_JAR="tika-server-standard-${TIKA_VERSION}.jar"
DOWNLOAD_URL="https://dlcdn.apache.org/tika/${TIKA_VERSION}/${TIKA_JAR}"

wget -4 -O "$TIKA_JAR" "$DOWNLOAD_URL"

# Verify download
if [ ! -f "$TIKA_JAR" ]; then
    echo "❌ Error: Failed to download Tika Server JAR"
    exit 1
fi

# Set ownership
chown -R "$TIKA_USER":"$TIKA_USER" "$TIKA_HOME"

echo "✅ Tika Server downloaded: $TIKA_JAR"

# ==============================================================================
# STEP 4: CREATE TIKA CONFIGURATION
# ==============================================================================
echo "--> [4/6] Creating Tika configuration..."

# Create config directory
mkdir -p "$TIKA_HOME/config"
mkdir -p "$TIKA_HOME/logs"

# Create basic configuration file
cat > "$TIKA_HOME/config/tika-config.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<properties>
  <server>
    <params>
      <port>9998</port>
      <host>0.0.0.0</host>
      <enableCors>true</enableCors>
      <enableUnsecureFeatures>false</enableUnsecureFeatures>
      <maxFiles>10000</maxFiles>
    </params>
  </server>
</properties>
EOF

chown -R "$TIKA_USER":"$TIKA_USER" "$TIKA_HOME"

echo "✅ Configuration created"

# ==============================================================================
# STEP 5: CREATE SYSTEMD SERVICE
# ==============================================================================
echo "--> [5/6] Creating systemd service..."

cat > /etc/systemd/system/tika.service <<EOF
[Unit]
Description=Apache Tika Server
Documentation=https://tika.apache.org/
After=network.target

[Service]
Type=simple
User=$TIKA_USER
Group=$TIKA_USER
WorkingDirectory=$TIKA_HOME

# Java options
Environment="JAVA_OPTS=-Xms512m -Xmx1g"

# Start Tika Server
ExecStart=/usr/bin/java \$JAVA_OPTS -jar $TIKA_HOME/$TIKA_JAR --host 0.0.0.0 --port $TIKA_PORT

# Restart on failure
Restart=on-failure
RestartSec=10s

# Security settings
NoNewPrivileges=true
PrivateTmp=true

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=tika

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Systemd service created"

# ==============================================================================
# STEP 6: START TIKA SERVICE
# ==============================================================================
echo "--> [6/6] Starting Tika service..."

systemctl daemon-reload
systemctl enable tika
systemctl start tika

# Wait for service to start
echo "Waiting for Tika to start..."
sleep 5

# Check service status
if systemctl is-active --quiet tika; then
    echo "✅ Tika service is running"
else
    echo "⚠️  Tika service may still be starting"
fi

# Wait for Tika to be ready (check HTTP endpoint)
MAX_ATTEMPTS=15
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:${TIKA_PORT}/tika > /dev/null 2>&1; then
        echo "✅ Tika HTTP endpoint is responding"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo "⚠️  Tika may still be initializing"
    else
        sleep 2
    fi
done

# ==============================================================================
# SAVE CREDENTIALS
# ==============================================================================
echo ""
echo "Saving information..."

mkdir -p /root/.credentials
cat > /root/.credentials/tika.txt <<CRED
=== Apache Tika Server Information ===

API Endpoint:
  URL: http://${CONTAINER_IP}:${TIKA_PORT}

API Endpoints:
  Health check:  GET  http://${CONTAINER_IP}:${TIKA_PORT}/tika
  Version:       GET  http://${CONTAINER_IP}:${TIKA_PORT}/version
  Detect type:   PUT  http://${CONTAINER_IP}:${TIKA_PORT}/detect/stream
  Extract text:  PUT  http://${CONTAINER_IP}:${TIKA_PORT}/tika (body: file)
  Extract meta:  PUT  http://${CONTAINER_IP}:${TIKA_PORT}/meta (body: file)
  Extract all:   PUT  http://${CONTAINER_IP}:${TIKA_PORT}/rmeta (body: file)

Usage Examples:
  # Detect file type
  curl -T document.pdf http://${CONTAINER_IP}:${TIKA_PORT}/detect/stream

  # Extract text
  curl -T document.pdf http://${CONTAINER_IP}:${TIKA_PORT}/tika --header "Accept: text/plain"

  # Extract metadata
  curl -T document.pdf http://${CONTAINER_IP}:${TIKA_PORT}/meta --header "Accept: application/json"

  # Python example
  import requests
  with open('document.pdf', 'rb') as f:
      response = requests.put('http://${CONTAINER_IP}:${TIKA_PORT}/tika', data=f)
      text = response.text

Service Management:
  systemctl status tika
  systemctl restart tika
  systemctl stop tika
  journalctl -u tika -f

Configuration:
  JAR: $TIKA_HOME/$TIKA_JAR
  Config: $TIKA_HOME/config/tika-config.xml
  Logs: journalctl -u tika

Supported Formats:
  Documents: PDF, Word, Excel, PowerPoint
  Images: JPEG, PNG, GIF, TIFF
  Archives: ZIP, TAR, GZIP
  Web: HTML, XML
  And 1000+ more formats!

Version: ${TIKA_VERSION}
CRED

chmod 600 /root/.credentials/tika.txt

echo ""
echo "========================================================="
echo "✅ APACHE TIKA SERVER DEPLOYED SUCCESSFULLY"
echo "========================================================="
echo ""
echo "Access Tika at: http://${CONTAINER_IP}:${TIKA_PORT}"
echo ""
echo "API Endpoints:"
echo "  Version:      GET  http://${CONTAINER_IP}:${TIKA_PORT}/version"
echo "  Extract text: PUT  http://${CONTAINER_IP}:${TIKA_PORT}/tika"
echo "  Extract meta: PUT  http://${CONTAINER_IP}:${TIKA_PORT}/meta"
echo ""
echo "Test the service:"
echo "  curl http://${CONTAINER_IP}:${TIKA_PORT}/version"
echo ""
echo "Service Management:"
echo "  systemctl status tika"
echo "  systemctl restart tika"
echo "  journalctl -u tika -f"
echo ""
echo "Information saved to: /root/.credentials/tika.txt"
echo "========================================================="
