#!/bin/bash
set -e

# Shared Matrix + Element chat server
# Secure, decentralized team communication
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 38_deploy_shared_matrix.sh [--update] <postgres_host> <postgres_password> <server_name>

POSTGRES_HOST="${2:-10.0.5.24}"
POSTGRES_PASS="${3}"
SERVER_NAME="${4:-matrix.valuechainhackers.xyz}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

if [ -z "$POSTGRES_PASS" ] && [ "$1" != "--update" ]; then
  echo "❌ Usage: bash 38_deploy_shared_matrix.sh <postgres_host> <postgres_password> <server_name>"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Matrix ===\"
  cd /opt/matrix
  docker compose pull
  docker compose up -d
  echo "✅ Matrix updated"
  exit 0
fi

echo "=== Matrix + Element Deployment ==="

mkdir -p /opt/matrix/{synapse,element}
cd /opt/matrix

# Generate Matrix config if not exists
if [ ! -f "synapse/homeserver.yaml" ]; then
  docker run -it --rm \
    -v $(pwd)/synapse:/data \
    -e SYNAPSE_SERVER_NAME=$SERVER_NAME \
    -e SYNAPSE_REPORT_STATS=no \
    matrixdotorg/synapse:latest generate
fi

cat > docker-compose.yml << EOF
version: '3.8'

services:
  synapse:
    image: matrixdotorg/synapse:latest
    container_name: matrix-synapse
    restart: unless-stopped
    ports:
      - "8008:8008"
      - "8448:8448"
    volumes:
      - ./synapse:/data
    environment:
      POSTGRES_HOST: ${POSTGRES_HOST}
      POSTGRES_PORT: 5432
      POSTGRES_DB: synapse
      POSTGRES_USER: dbadmin
      POSTGRES_PASSWORD: ${POSTGRES_PASS}
      SYNAPSE_SERVER_NAME: ${SERVER_NAME}

  element:
    image: vectorim/element-web:latest
    container_name: matrix-element
    restart: unless-stopped
    ports:
      - "3010:80"
    volumes:
      - ./element/config.json:/app/config.json
EOF

# Create database
PGPASSWORD=$POSTGRES_PASS psql -h $POSTGRES_HOST -U dbadmin -d postgres -c "CREATE DATABASE synapse ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE template0;" 2>/dev/null || true

# Configure Element
cat > element/config.json << EOF
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "http://$(hostname -I | awk '{print $1}'):8008",
      "server_name": "$SERVER_NAME"
    }
  },
  "brand": "Element",
  "integrations_ui_url": "https://scalar.vector.im/",
  "integrations_rest_url": "https://scalar.vector.im/api",
  "integrations_widgets_urls": [
    "https://scalar.vector.im/_matrix/integrations/v1",
    "https://scalar.vector.im/api",
    "https://scalar-staging.vector.im/_matrix/integrations/v1",
    "https://scalar-staging.vector.im/api",
    "https://scalar-staging.riot.im/scalar/api"
  ],
  "hosting_signup_link": "",
  "bug_report_endpoint_url": "",
  "showLabsSettings": true,
  "roomDirectory": {
    "servers": ["$SERVER_NAME"]
  }
}
EOF

# Update synapse config for PostgreSQL
if [ -f "synapse/homeserver.yaml" ]; then
  cat >> synapse/homeserver.yaml << EOF

# PostgreSQL Database
database:
  name: psycopg2
  args:
    user: dbadmin
    password: ${POSTGRES_PASS}
    database: synapse
    host: ${POSTGRES_HOST}
    port: 5432
    cp_min: 5
    cp_max: 10
EOF
fi

docker compose up -d

echo "✅ Matrix + Element deployed"
echo ""
echo "Element Web UI: http://$(hostname -I | awk '{print $1}'):3010"
echo "Matrix Homeserver: http://$(hostname -I | awk '{print $1}'):8008"
echo "Server Name: $SERVER_NAME"
echo ""
echo "Create admin user:"
echo "docker exec -it matrix-synapse register_new_matrix_user -c /data/homeserver.yaml -a http://localhost:8008"
