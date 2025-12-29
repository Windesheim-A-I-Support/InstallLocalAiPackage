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

# Shared Langfuse LLM observability - NATIVE INSTALLATION
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 18_deploy_shared_langfuse_native.sh [--update]

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

# Get PostgreSQL password from credentials or environment
POSTGRES_HOST="${POSTGRES_HOST:-10.0.5.102}"
POSTGRES_PASS="${POSTGRES_PASS:-ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8=}"

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Langfuse ==="
  cd /opt/langfuse
  sudo -u langfuse git pull
  sudo -u langfuse npm install
  sudo -u langfuse npm run build
  systemctl restart langfuse
  echo "✅ Langfuse updated"
  exit 0
fi

echo "=== Langfuse Native Deployment ==="

# Install Node.js 20.x (Langfuse requires Node 18+)
echo "Installing Node.js 20.x..."
apt-get update
apt-get install -y ca-certificates curl gnupg
mkdir -p /etc/apt/keyrings
rm -f /etc/apt/keyrings/nodesource.gpg
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --batch --dearmor -o /etc/apt/keyrings/nodesource.gpg

NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

apt-get update
apt-get install -y nodejs git build-essential

# Create langfuse user
if ! id langfuse &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/langfuse -m langfuse
  echo "✅ Created langfuse user"
fi

# Clone Langfuse repository
echo "Cloning Langfuse repository..."
if [ ! -d /opt/langfuse/.git ]; then
  sudo -u langfuse git clone https://github.com/langfuse/langfuse.git /opt/langfuse-tmp
  mv /opt/langfuse-tmp/* /opt/langfuse/
  mv /opt/langfuse-tmp/.* /opt/langfuse/ 2>/dev/null || true
  rm -rf /opt/langfuse-tmp
  chown -R langfuse:langfuse /opt/langfuse
fi

cd /opt/langfuse

# Generate secrets
NEXTAUTH_SECRET=$(openssl rand -base64 32)
SALT=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -base64 32)

# Create database
echo "Creating Langfuse database..."
PGPASSWORD="$POSTGRES_PASS" psql -h "$POSTGRES_HOST" -U dbadmin -d postgres -c "CREATE DATABASE langfuse;" 2>/dev/null || echo "Database already exists"

# Create .env file
echo "Creating environment configuration..."
cat > /opt/langfuse/.env << EOF
# Database
DATABASE_URL=postgresql://dbadmin:${POSTGRES_PASS}@${POSTGRES_HOST}:5432/langfuse
DIRECT_URL=postgresql://dbadmin:${POSTGRES_PASS}@${POSTGRES_HOST}:5432/langfuse

# NextAuth
NEXTAUTH_SECRET=$NEXTAUTH_SECRET
NEXTAUTH_URL=http://$(hostname -I | awk '{print $1}'):3002
AUTH_DOMAINS_WITH_SSO_ENFORCEMENT=

# Salt
SALT=$SALT
ENCRYPTION_KEY=$ENCRYPTION_KEY

# Server
PORT=3002
HOSTNAME=0.0.0.0

# Telemetry
TELEMETRY_ENABLED=false
LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES=false

# S3 (optional - using MinIO)
S3_ENDPOINT=http://10.0.5.104:9000
S3_ACCESS_KEY_ID=minio
S3_SECRET_ACCESS_KEY=dBNCAttR5xXOUlszFXByEAaq2LmTecGw
S3_BUCKET_NAME=langfuse
S3_REGION=us-east-1

# Email (optional)
EMAIL_FROM_ADDRESS=
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASSWORD=
EOF

chown langfuse:langfuse /opt/langfuse/.env
chmod 600 /opt/langfuse/.env

# Install dependencies
echo "Installing Node.js dependencies (this may take several minutes)..."
sudo -u langfuse npm install

# Build the application
echo "Building Langfuse application..."
sudo -u langfuse npm run build

# Run database migrations
echo "Running database migrations..."
sudo -u langfuse npx prisma migrate deploy

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/langfuse.service << EOF
[Unit]
Description=Langfuse LLM Observability
After=network.target

[Service]
Type=simple
User=langfuse
Group=langfuse
WorkingDirectory=/opt/langfuse
EnvironmentFile=/opt/langfuse/.env
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/langfuse

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reload
systemctl enable langfuse
systemctl start langfuse

# Wait for service to start
echo "Waiting for Langfuse to start..."
sleep 10

# Check if service is running
if systemctl is-active --quiet langfuse; then
  echo "✅ Langfuse service is running"

  # Test the service
  if curl -f http://localhost:3002 >/dev/null 2>&1; then
    echo "✅ Langfuse is responding on port 3002"
  else
    echo "⚠️  Langfuse service is running but not responding yet (may need more time to start)"
  fi
else
  echo "❌ Langfuse service failed to start"
  systemctl status langfuse
  exit 1
fi

# Save credentials
mkdir -p /root/.credentials
cat >> /root/.credentials/langfuse.txt << EOF
=== Langfuse Credentials ===
URL: http://$(hostname -I | awk '{print $1}'):3002
Database: postgresql://dbadmin:REDACTED@${POSTGRES_HOST}:5432/langfuse

NEXTAUTH_SECRET: $NEXTAUTH_SECRET
SALT: $SALT
ENCRYPTION_KEY: $ENCRYPTION_KEY

First-time setup: Visit the URL above to create your admin account
EOF

chmod 600 /root/.credentials/langfuse.txt

echo ""
echo "=========================================="
echo "✅ Langfuse deployed successfully!"
echo "=========================================="
echo "Access: http://$(hostname -I | awk '{print $1}'):3002"
echo "Credentials: /root/.credentials/langfuse.txt"
echo "Service: systemctl status langfuse"
echo "Logs: journalctl -u langfuse -f"
echo ""
echo "Create your admin account on first visit"
echo "=========================================="
