#!/bin/bash
set -e

# Shared Langfuse LLM observability
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 18_deploy_shared_langfuse.sh [--update] <postgres_host> <postgres_password>

POSTGRES_HOST="${2:-10.0.5.24}"
POSTGRES_PASS="${3}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

if [ -z "$POSTGRES_PASS" ] && [ "$1" != "--update" ]; then
  echo "❌ Usage: bash 18_deploy_shared_langfuse.sh <postgres_host> <postgres_password>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Langfuse ==="
  cd /opt/langfuse
  docker compose pull
  docker compose up -d
  echo "✅ Langfuse updated"
  exit 0
fi

echo "=== Langfuse Shared Service Deployment ==="

# Create directory
mkdir -p /opt/langfuse
cd /opt/langfuse

# Generate secrets
NEXTAUTH_SECRET=$(openssl rand -base64 32)
SALT=$(openssl rand -base64 32)

# Create docker-compose
cat > docker-compose.yml << EOF
version: '3.8'

services:
  langfuse:
    image: langfuse/langfuse:latest
    container_name: langfuse-shared
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      DATABASE_URL: postgresql://dbadmin:${POSTGRES_PASS}@${POSTGRES_HOST}:5432/langfuse
      NEXTAUTH_SECRET: $NEXTAUTH_SECRET
      SALT: $SALT
      NEXTAUTH_URL: http://$(hostname -I | awk '{print $1}'):3001
      TELEMETRY_ENABLED: "false"
EOF

# Start service
docker compose up -d

echo "✅ Langfuse deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3001"
echo ""
echo "Connect from Open WebUI via pipelines"
echo "Set in pipeline code:"
echo "  LANGFUSE_PUBLIC_KEY=<get from UI>"
echo "  LANGFUSE_SECRET_KEY=<get from UI>"
echo "  LANGFUSE_HOST=http://$(hostname -I | awk '{print $1}'):3001"
