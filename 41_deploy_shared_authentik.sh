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

# Shared Authentik SSO
# Single Sign-On and identity provider
# Requires PostgreSQL (13_deploy_shared_postgres.sh) and Redis (14_deploy_shared_redis.sh)
# Usage: bash 41_deploy_shared_authentik.sh [--update] <postgres_host> <postgres_password> <redis_host> <redis_password>

POSTGRES_HOST="${2:-10.0.5.24}"
POSTGRES_PASS="${3}"
REDIS_HOST="${4:-10.0.5.24}"
REDIS_PASS="${5}"

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

if [ -z "$POSTGRES_PASS" ] && [ "$1" != "--update" ]; then
  echo "❌ Usage: bash 41_deploy_shared_authentik.sh <postgres_host> <postgres_password> <redis_host> <redis_password>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Authentik ==="
  echo "✅ Authentik updated (no update needed for native installation)"
  exit 0
fi

echo "=== Authentik SSO Deployment ==="

mkdir -p /opt/authentik/{media,custom-templates}
cd /opt/authentik

# Install Python and required packages
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Authentik
pip install authentik

# Generate secrets
AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60)
AUTHENTIK_BOOTSTRAP_PASSWORD=$(openssl rand -base64 32)
AUTHENTIK_BOOTSTRAP_TOKEN=$(openssl rand -base64 32)

# Create configuration
cat > config.yml << EOF
# Authentik Configuration
secret_key: $AUTHENTIK_SECRET_KEY

# Database Configuration
postgresql:
  user: dbadmin
  password: $POSTGRES_PASS
  name: authentik
  host: $POSTGRES_HOST
  port: 5432

# Redis Configuration
redis:
  host: $REDIS_HOST
  port: 6379
  password: $REDIS_PASS

# Bootstrap Configuration
bootstrap:
  password: $AUTHENTIK_BOOTSTRAP_PASSWORD
  token: $AUTHENTIK_BOOTSTRAP_TOKEN

# Server Configuration
web:
  bind_port: 9000
  bind_host: 0.0.0.0

api:
  bind_port: 9443
  bind_host: 0.0.0.0

# Logging
logging:
  level: info
EOF

# Create systemd service for server
cat > /etc/systemd/system/authentik-server.service << EOF
[Unit]
Description=Authentik Server
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/authentik
Environment=PATH=/opt/authentik/venv/bin
Environment=AUTHENTIK_CONFIG=/opt/authentik/config.yml
ExecStart=/opt/authentik/venv/bin/authentik-server
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for worker
cat > /etc/systemd/system/authentik-worker.service << EOF
[Unit]
Description=Authentik Worker
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/authentik
Environment=PATH=/opt/authentik/venv/bin
Environment=AUTHENTIK_CONFIG=/opt/authentik/config.yml
ExecStart=/opt/authentik/venv/bin/authentik-worker
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Create database
PGPASSWORD=$POSTGRES_PASS psql -h $POSTGRES_HOST -U dbadmin -d postgres -c "CREATE DATABASE authentik;" 2>/dev/null || true

# Enable and start services
systemctl daemon-reload
systemctl enable authentik-server authentik-worker
systemctl start authentik-server authentik-worker

# Wait for services to start
sleep 5

echo "✅ Authentik deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):9000"
echo "Email: akadmin"
echo "Password: $AUTHENTIK_BOOTSTRAP_PASSWORD"
echo ""
echo "⚠️  SAVE THIS PASSWORD - it won't be shown again!"
echo ""
echo "Bootstrap Token (for API): $AUTHENTIK_BOOTSTRAP_TOKEN"
echo ""
echo "Service management:"
echo "  Start: systemctl start authentik-server authentik-worker"
echo "  Stop: systemctl stop authentik-server authentik-worker"
echo "  Status: systemctl status authentik-server authentik-worker"
echo "  Logs: journalctl -u authentik-server -f"
echo ""
echo "Next steps:"
echo "1. Log in and change password"
echo "2. Create applications for each service (Gitea, Grafana, etc.)"
echo "3. Configure OAuth2/OIDC for each service"
echo "4. See AUTHENTICATION_STRATEGY.md for integration guides"
