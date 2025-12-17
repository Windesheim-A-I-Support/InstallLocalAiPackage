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

# Shared Gitea Git Server - NATIVE INSTALLATION
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 28_deploy_shared_gitea_native.sh [--update]

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

GITEA_VERSION="1.22.6"

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Gitea ==="
  cd /tmp
  wget -O gitea "https://dl.gitea.io/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64"
  chmod +x gitea
  systemctl stop gitea
  mv gitea /usr/local/bin/gitea
  systemctl start gitea
  echo "✅ Gitea updated to version ${GITEA_VERSION}"
  exit 0
fi

echo "=== Gitea Native Deployment ==="

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y git wget curl postgresql-client

# Create git user
if ! id git &>/dev/null; then
  adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git git
  echo "✅ Created git user"
fi

# Create required directories
mkdir -p /var/lib/gitea/{custom,data,log}
chown -R git:git /var/lib/gitea/
chmod -R 750 /var/lib/gitea/

mkdir -p /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea

# Download Gitea binary
echo "Downloading Gitea ${GITEA_VERSION}..."
cd /tmp
wget -O gitea "https://dl.gitea.io/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64"
chmod +x gitea
mv gitea /usr/local/bin/gitea

# Create database
echo "Creating Gitea database..."
GITEA_DB_PASS=$(openssl rand -base64 32)
PGPASSWORD="$POSTGRES_PASS" psql -h "$POSTGRES_HOST" -U dbadmin -d postgres << EOF
CREATE USER gitea WITH PASSWORD '${GITEA_DB_PASS}';
CREATE DATABASE gitea OWNER gitea;
\q
EOF

# Create initial configuration
echo "Creating Gitea configuration..."
cat > /etc/gitea/app.ini << EOF
APP_NAME = Gitea: Git with a cup of tea
RUN_MODE = prod
RUN_USER = git
WORK_PATH = /var/lib/gitea

[repository]
ROOT = /var/lib/gitea/data/gitea-repositories

[server]
DOMAIN = $(hostname -I | awk '{print $1}')
HTTP_PORT = 3000
ROOT_URL = http://$(hostname -I | awk '{print $1}'):3000/
DISABLE_SSH = false
SSH_PORT = 22
LFS_START_SERVER = true

[database]
DB_TYPE = postgres
HOST = ${POSTGRES_HOST}:5432
NAME = gitea
USER = gitea
PASSWD = ${GITEA_DB_PASS}
SSL_MODE = disable

[security]
INSTALL_LOCK = false
SECRET_KEY = $(gitea generate secret SECRET_KEY)
INTERNAL_TOKEN = $(gitea generate secret INTERNAL_TOKEN)
PASSWORD_HASH_ALGO = pbkdf2

[service]
DISABLE_REGISTRATION = false
REQUIRE_SIGNIN_VIEW = false
ENABLE_NOTIFY_MAIL = false

[mailer]
ENABLED = false

[log]
MODE = file
LEVEL = Info
ROOT_PATH = /var/lib/gitea/log

[session]
PROVIDER = file

[picture]
DISABLE_GRAVATAR = true
ENABLE_FEDERATED_AVATAR = false
EOF

chown git:git /etc/gitea/app.ini
chmod 640 /etc/gitea/app.ini

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/gitea.service << 'EOF'
[Unit]
Description=Gitea (Git with a cup of tea)
After=network.target postgresql.service

[Service]
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea/
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
RestartSec=10
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/gitea /etc/gitea

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reload
systemctl enable gitea
systemctl start gitea

# Wait for service to start
echo "Waiting for Gitea to start..."
for i in {1..30}; do
  if curl -f http://localhost:3000 >/dev/null 2>&1; then
    echo "✅ Gitea is responding"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Gitea failed to start within timeout"
    systemctl status gitea
    exit 1
  fi
  sleep 2
done

# Check if service is running
if systemctl is-active --quiet gitea; then
  echo "✅ Gitea service is running"
else
  echo "❌ Gitea service failed to start"
  systemctl status gitea
  exit 1
fi

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/gitea.txt << EOF
=== Gitea Credentials ===
URL: http://$(hostname -I | awk '{print $1}'):3000
SSH: git@$(hostname -I | awk '{print $1}'):22

Database: postgresql://gitea:${GITEA_DB_PASS}@${POSTGRES_HOST}:5432/gitea

Installation:
1. Visit http://$(hostname -I | awk '{print $1}'):3000
2. Complete the initial setup wizard
3. Create your admin account

Service: systemctl status gitea
Logs: journalctl -u gitea -f
Config: /etc/gitea/app.ini
Data: /var/lib/gitea/
EOF

chmod 600 /root/.credentials/gitea.txt

echo ""
echo "=========================================="
echo "✅ Gitea deployed successfully!"
echo "=========================================="
echo "URL: http://$(hostname -I | awk '{print $1}'):3000"
echo ""
echo "Complete setup:"
echo "1. Visit the URL above"
echo "2. Complete the installation wizard"
echo "3. Create your admin account"
echo ""
echo "Credentials: /root/.credentials/gitea.txt"
echo "Service: systemctl status gitea"
echo "Logs: journalctl -u gitea -f"
echo "=========================================="
