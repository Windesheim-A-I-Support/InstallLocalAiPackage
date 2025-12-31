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

# Shared Metabase Business Intelligence - NATIVE INSTALLATION
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 31_deploy_shared_metabase_native.sh [--update]

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

# Get PostgreSQL password from environment
POSTGRES_HOST="${POSTGRES_HOST:-10.0.5.102}"
POSTGRES_PASS="${POSTGRES_PASS:-ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8=}"

METABASE_VERSION="v0.51.3"

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Metabase ==="
  cd /opt/metabase
  wget -O metabase.jar "https://downloads.metabase.com/${METABASE_VERSION}/metabase.jar"
  systemctl restart metabase
  echo "✅ Metabase updated to ${METABASE_VERSION}"
  exit 0
fi

echo "=== Metabase Native Deployment ==="

# Install Java (Metabase requires Java 11+)
echo "Installing Java 17..."
apt-get update
apt-get install -y openjdk-17-jre-headless wget curl postgresql-client

# Create metabase user
if ! id metabase &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/metabase -m metabase
  echo "✅ Created metabase user"
fi

# Create directory
mkdir -p /opt/metabase
cd /opt/metabase

# Download Metabase
echo "Downloading Metabase ${METABASE_VERSION}..."
su -s /bin/bash -c "wget -4 -O /opt/metabase/metabase.jar 'https://downloads.metabase.com/${METABASE_VERSION}/metabase.jar'" metabase

# Create database
echo "Creating Metabase database..."
METABASE_DB_PASS=$(openssl rand -base64 32)
PGPASSWORD="$POSTGRES_PASS" psql -h "$POSTGRES_HOST" -U dbadmin -d postgres << EOF
CREATE USER metabase WITH PASSWORD '${METABASE_DB_PASS}';
CREATE DATABASE metabase OWNER metabase;
\q
EOF

# Create environment file
echo "Creating environment configuration..."
cat > /opt/metabase/metabase.env << EOF
MB_DB_TYPE=postgres
MB_DB_DBNAME=metabase
MB_DB_PORT=5432
MB_DB_USER=metabase
MB_DB_PASS=${METABASE_DB_PASS}
MB_DB_HOST=${POSTGRES_HOST}
MB_JETTY_HOST=0.0.0.0
MB_JETTY_PORT=3001
EOF

chown metabase:metabase /opt/metabase/metabase.env
chmod 600 /opt/metabase/metabase.env

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/metabase.service << 'EOF'
[Unit]
Description=Metabase Business Intelligence
After=network.target postgresql.service

[Service]
Type=simple
User=metabase
Group=metabase
WorkingDirectory=/opt/metabase
EnvironmentFile=/opt/metabase/metabase.env
ExecStart=/usr/bin/java -jar /opt/metabase/metabase.jar
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/metabase

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reload
systemctl enable metabase
systemctl start metabase

# Wait for service to start (Metabase takes a while to initialize)
echo "Waiting for Metabase to start (this may take 1-2 minutes)..."
for i in {1..60}; do
  if curl -f http://localhost:3001/api/health >/dev/null 2>&1; then
    echo "✅ Metabase is responding"
    break
  fi
  if [ $i -eq 60 ]; then
    echo "⚠️  Metabase may still be initializing"
    echo "Check logs: journalctl -u metabase -f"
  fi
  sleep 3
done

# Check if service is running
if systemctl is-active --quiet metabase; then
  echo "✅ Metabase service is running"
else
  echo "❌ Metabase service failed to start"
  systemctl status metabase
  exit 1
fi

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/metabase.txt << EOF
=== Metabase Credentials ===
URL: http://$(hostname -I | awk '{print $1}'):3001
Health: http://$(hostname -I | awk '{print $1}'):3001/api/health

Database: postgresql://metabase:${METABASE_DB_PASS}@${POSTGRES_HOST}:5432/metabase

Setup:
1. Visit http://$(hostname -I | awk '{print $1}'):3001
2. Complete the initial setup wizard
3. Create your admin account
4. Connect to your data sources

Service: systemctl status metabase
Logs: journalctl -u metabase -f
JAR: /opt/metabase/metabase.jar
Config: /opt/metabase/metabase.env
EOF

chmod 600 /root/.credentials/metabase.txt

echo ""
echo "=========================================="
echo "✅ Metabase deployed successfully!"
echo "=========================================="
echo "URL: http://$(hostname -I | awk '{print $1}'):3001"
echo ""
echo "Complete setup:"
echo "1. Visit the URL above"
echo "2. Complete the setup wizard"
echo "3. Create your admin account"
echo ""
echo "Note: Metabase may take 1-2 minutes to fully initialize"
echo ""
echo "Credentials: /root/.credentials/metabase.txt"
echo "Service: systemctl status metabase"
echo "Logs: journalctl -u metabase -f"
echo "=========================================="
