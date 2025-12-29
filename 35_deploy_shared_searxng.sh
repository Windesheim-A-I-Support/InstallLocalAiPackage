#!/bin/bash
set -e

# ==============================================================================
# SEARXNG META SEARCH ENGINE DEPLOYMENT
# ==============================================================================
# Based on official SearXNG Docker deployment
# Sources:
#   - https://github.com/searxng/searxng-docker
#   - https://docs.searxng.org/admin/installation-docker.html
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.105}"
SEARXNG_SECRET="${2:-$(openssl rand -hex 32)}"
SEARXNG_PORT="${3:-8888}"
INSTALL_DIR="/opt/searxng"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   SEARXNG META SEARCH ENGINE DEPLOYMENT"
echo "========================================================="
echo ""
echo "This deploys:"
echo "  • SearXNG (privacy-respecting metasearch engine)"
echo "  • Valkey (Redis fork for caching)"
echo "  • Caddy (reverse proxy with auto-HTTPS)"
echo ""
echo "Container: ${CONTAINER_IP}"
echo "Access at: http://${CONTAINER_IP}:${SEARXNG_PORT}"
echo ""
echo ""

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# STEP 0: CHECK DOCKER INSTALLATION
# ==============================================================================
echo "--> [0/6] Checking Docker installation..."

if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker not found. Installing Docker..."

    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl start docker
    systemctl enable docker

    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Verify docker compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Error: docker compose plugin not available"
    exit 1
fi

echo "✅ Docker prerequisites satisfied"

# ==============================================================================
# STEP 1: CLONE SEARXNG-DOCKER REPOSITORY
# ==============================================================================
echo "--> [1/6] Cloning SearXNG Docker repository..."

# Install git if needed
if ! command -v git &> /dev/null; then
    apt-get install -y git
fi

# Remove existing directory if present
rm -rf "$INSTALL_DIR"

# Clone repository (using IPv4)
git -c http.version=HTTP/1.1 clone https://github.com/searxng/searxng-docker.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "✅ Repository cloned"

# ==============================================================================
# STEP 2: GENERATE SECRET KEY
# ==============================================================================
echo "--> [2/6] Generating secret key..."

# Replace the ultrasecretkey with a generated one
sed -i "s|ultrasecretkey|${SEARXNG_SECRET}|g" searxng/settings.yml

echo "✅ Secret key generated and configured"

# ==============================================================================
# STEP 3: CONFIGURE ENVIRONMENT
# ==============================================================================
echo "--> [3/6] Configuring environment..."

# Update .env file with container IP
cat > .env <<EOF
# SearXNG Configuration
SEARXNG_HOSTNAME=${CONTAINER_IP}
SEARXNG_PORT=${SEARXNG_PORT}
LETSENCRYPT_EMAIL=admin@${CONTAINER_IP}
EOF

echo "✅ Environment configured"

# ==============================================================================
# STEP 4: CUSTOMIZE DOCKER COMPOSE FOR INTERNAL NETWORK
# ==============================================================================
echo "--> [4/6] Customizing Docker Compose..."

# Create simplified docker-compose for internal network (no Caddy HTTPS)
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  # ====================
  # VALKEY (Redis fork)
  # ====================
  valkey:
    container_name: searxng-valkey
    image: valkey/valkey:8-alpine
    restart: unless-stopped
    command: valkey-server --save 30 1 --loglevel warning
    networks:
      - searxng
    volumes:
      - valkey-data:/data
    cap_drop:
      - ALL
    cap_add:
      - SETGID
      - SETUID
      - DAC_OVERRIDE
    logging:
      driver: "json-file"
      options:
        max-size: "1m"
        max-file: "1"

  # ====================
  # SEARXNG
  # ====================
  searxng:
    container_name: searxng
    image: searxng/searxng:latest
    restart: unless-stopped
    ports:
      - "${SEARXNG_PORT}:8080"
    networks:
      - searxng
    volumes:
      - ./searxng:/etc/searxng:rw
    environment:
      - SEARXNG_BASE_URL=http://${CONTAINER_IP}:${SEARXNG_PORT}/
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
    logging:
      driver: "json-file"
      options:
        max-size: "1m"
        max-file: "1"

networks:
  searxng:
    driver: bridge

volumes:
  valkey-data:
EOF

echo "✅ Docker Compose configured for internal network"

# ==============================================================================
# STEP 5: CUSTOMIZE SEARXNG SETTINGS
# ==============================================================================
echo "--> [5/6] Customizing SearXNG settings..."

# Update settings.yml with better defaults for internal network
cat >> searxng/settings.yml <<EOF

# Custom settings for internal deployment
general:
  instance_name: "SearXNG"
  privacypolicy_url: false
  donation_url: false
  contact_url: false
  enable_metrics: false

server:
  secret_key: "${SEARXNG_SECRET}"
  limiter: false  # Disable rate limiting for internal use
  image_proxy: true
  method: "GET"

search:
  safe_search: 0
  autocomplete: "google"
  default_lang: "en"

ui:
  static_use_hash: true
  default_theme: simple
  theme_args:
    simple_style: dark

redis:
  url: redis://valkey:6379/0
EOF

echo "✅ Settings customized"

# ==============================================================================
# STEP 6: START SERVICES
# ==============================================================================
echo "--> [6/6] Starting SearXNG services..."

# Pull images
docker compose pull

# Start services
docker compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 10

# Check service status
VALKEY_STATUS=$(docker inspect -f '{{.State.Status}}' searxng-valkey 2>/dev/null || echo "unknown")
SEARXNG_STATUS=$(docker inspect -f '{{.State.Status}}' searxng 2>/dev/null || echo "unknown")

echo ""
echo "Container Status:"
echo "  • Valkey (cache): $VALKEY_STATUS"
echo "  • SearXNG: $SEARXNG_STATUS"
echo ""

# Wait for SearXNG to be ready
MAX_ATTEMPTS=15
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:${SEARXNG_PORT} > /dev/null 2>&1; then
        echo "✅ SearXNG is responding"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo "⚠️  SearXNG may still be starting"
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
cat > /root/.credentials/searxng.txt <<CRED
=== SearXNG Meta Search Engine ===

Web Interface:
  URL: http://${CONTAINER_IP}:${SEARXNG_PORT}

Configuration:
  Secret Key: ${SEARXNG_SECRET}
  Base URL: http://${CONTAINER_IP}:${SEARXNG_PORT}/

Docker Management:
  cd ${INSTALL_DIR}
  docker compose ps
  docker compose logs -f
  docker compose logs -f searxng
  docker compose logs -f valkey
  docker compose restart
  docker compose down

Update SearXNG:
  cd ${INSTALL_DIR}
  git pull
  docker compose pull
  docker compose up -d

Settings:
  File: ${INSTALL_DIR}/searxng/settings.yml
  After changes: docker compose restart

Search Engines:
  Configure enabled engines in settings.yml

Cache:
  Type: Valkey (Redis fork)
  Connection: redis://valkey:6379/0

Features:
  - Privacy-respecting metasearch
  - No tracking or profiling
  - Aggregates results from 70+ search engines
  - Customizable interface
  - JSON API available

API Usage:
  Search: http://${CONTAINER_IP}:${SEARXNG_PORT}/search?q=your+query&format=json

  Example:
  curl "http://${CONTAINER_IP}:${SEARXNG_PORT}/search?q=debian+linux&format=json"
CRED

chmod 600 /root/.credentials/searxng.txt

echo ""
echo "========================================================="
echo "✅ SEARXNG DEPLOYED SUCCESSFULLY"
echo "========================================================="
echo ""
echo "Access SearXNG at: http://${CONTAINER_IP}:${SEARXNG_PORT}"
echo ""
echo "Services running:"
echo "  • SearXNG (metasearch): http://${CONTAINER_IP}:${SEARXNG_PORT}"
echo "  • Valkey (cache): Internal only"
echo ""
echo "Features:"
echo "  ✓ Privacy-respecting search"
echo "  ✓ 70+ search engines aggregated"
echo "  ✓ No tracking or profiling"
echo "  ✓ JSON API available"
echo ""
echo "Docker Management:"
echo "  cd ${INSTALL_DIR}"
echo "  docker compose ps"
echo "  docker compose logs -f searxng"
echo "  docker compose restart"
echo ""
echo "Configuration:"
echo "  Settings: ${INSTALL_DIR}/searxng/settings.yml"
echo "  After changes: docker compose restart"
echo ""
echo "Information saved to: /root/.credentials/searxng.txt"
echo "========================================================="
