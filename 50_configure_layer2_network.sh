#!/bin/bash
set -e

# Configure Layer 2 Bridge Network for Open WebUI
# Allows Open WebUI to get IP from DHCP on the physical network
# Avoids Docker networking issues with older Docker versions
# Usage: bash 50_configure_layer2_network.sh <interface_name>

INTERFACE="${1:-ens18}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

if [ -z "$INTERFACE" ]; then
  echo "❌ Usage: bash 50_configure_layer2_network.sh <interface_name>"
  echo "Example: bash 50_configure_layer2_network.sh ens18"
  exit 1
fi

echo "=== Configuring Layer 2 Bridge Network ==="
echo "Physical interface: $INTERFACE"

# Check if interface exists
if ! ip link show $INTERFACE >/dev/null 2>&1; then
  echo "❌ Interface $INTERFACE not found"
  echo "Available interfaces:"
  ip link show | grep -E "^[0-9]+" | awk '{print $2}' | tr -d ':'
  exit 1
fi

# Install bridge-utils if not present
if ! command -v brctl >/dev/null 2>&1; then
  echo "Installing bridge-utils..."
  apt-get update
  apt-get install -y bridge-utils
fi

# Create Docker macvlan network
echo "Creating Docker macvlan network..."

# Get subnet and gateway from current interface
SUBNET=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | head -1)
GATEWAY=$(ip route | grep default | grep $INTERFACE | awk '{print $3}')

if [ -z "$SUBNET" ] || [ -z "$GATEWAY" ]; then
  echo "❌ Could not detect subnet/gateway automatically"
  echo "Please provide them manually:"
  read -p "Subnet (e.g., 10.0.5.0/24): " SUBNET
  read -p "Gateway (e.g., 10.0.5.1): " GATEWAY
fi

echo "Detected configuration:"
echo "  Subnet: $SUBNET"
echo "  Gateway: $GATEWAY"
echo "  Interface: $INTERFACE"

# Remove existing macvlan network if present
docker network rm openwebui-macvlan 2>/dev/null || true

# Create macvlan network
docker network create -d macvlan \
  --subnet=$SUBNET \
  --gateway=$GATEWAY \
  -o parent=$INTERFACE \
  openwebui-macvlan

echo "✅ Layer 2 macvlan network created"

# Create helper script for deploying Open WebUI on Layer 2
cat > /root/deploy_openwebui_layer2.sh << 'EOFSCRIPT'
#!/bin/bash
set -e

# Deploy Open WebUI instance on Layer 2 network
# Gets IP from DHCP on physical network
# Usage: bash deploy_openwebui_layer2.sh <instance_name> <ip_address>

INSTANCE_NAME="${1:-webui1}"
IP_ADDRESS="${2}"
OLLAMA_URL="${3:-http://10.0.5.100:11434}"
QDRANT_URL="${4:-http://10.0.5.101:6333}"

if [ -z "$IP_ADDRESS" ]; then
  echo "❌ Usage: bash deploy_openwebui_layer2.sh <instance_name> <ip_address> [ollama_url] [qdrant_url]"
  echo "Example: bash deploy_openwebui_layer2.sh webui1 10.0.5.200"
  exit 1
fi

echo "=== Deploying Open WebUI on Layer 2 ==="
echo "Instance: $INSTANCE_NAME"
echo "IP: $IP_ADDRESS"
echo "Ollama: $OLLAMA_URL"
echo "Qdrant: $QDRANT_URL"

mkdir -p /opt/openwebui-instances/$INSTANCE_NAME
cd /opt/openwebui-instances/$INSTANCE_NAME

# Generate secrets
WEBUI_SECRET_KEY=$(openssl rand -base64 32)

cat > docker-compose.yml << EOF
version: '3.8'

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: openwebui-$INSTANCE_NAME
    restart: unless-stopped
    networks:
      openwebui-macvlan:
        ipv4_address: $IP_ADDRESS
    volumes:
      - ./data:/app/backend/data
    environment:
      # LLM Configuration
      OLLAMA_BASE_URL: $OLLAMA_URL

      # Vector Database
      VECTOR_DB: qdrant
      QDRANT_URI: $QDRANT_URL

      # Authentication
      WEBUI_AUTH: "true"
      WEBUI_SECRET_KEY: $WEBUI_SECRET_KEY
      ENABLE_SIGNUP: "true"
      DEFAULT_USER_ROLE: "user"

      # Pipelines (if available)
      PIPELINES_URLS: '["http://10.0.5.24:9099"]'

      # RAG Configuration
      ENABLE_RAG_WEB_SEARCH: "true"
      RAG_WEB_SEARCH_ENGINE: "searxng"
      SEARXNG_QUERY_URL: "http://10.0.5.105:8080/search?q=<query>"

      # Storage (optional - MinIO)
      # S3_ENDPOINT_URL: "http://10.0.5.104:9001"
      # S3_ACCESS_KEY: "minioadmin"
      # S3_SECRET_KEY: "minioadmin"
      # S3_BUCKET_NAME: "openwebui"

networks:
  openwebui-macvlan:
    external: true

EOF

docker compose up -d

echo "✅ Open WebUI deployed on Layer 2"
echo ""
echo "Instance: $INSTANCE_NAME"
echo "IP: $IP_ADDRESS"
echo "URL: http://$IP_ADDRESS"
echo ""
echo "Configure domain in Traefik:"
echo "  Route: webui-$INSTANCE_NAME.valuechainhackers.xyz → $IP_ADDRESS:80"
EOFSCRIPT

chmod +x /root/deploy_openwebui_layer2.sh

echo ""
echo "✅ Layer 2 network configuration complete!"
echo ""
echo "Network Details:"
echo "  Name: openwebui-macvlan"
echo "  Driver: macvlan"
echo "  Subnet: $SUBNET"
echo "  Gateway: $GATEWAY"
echo "  Parent: $INTERFACE"
echo ""
echo "Deploy Open WebUI instances using:"
echo "  bash /root/deploy_openwebui_layer2.sh webui1 10.0.5.200"
echo "  bash /root/deploy_openwebui_layer2.sh webui2 10.0.5.201"
echo ""
echo "IP Range Recommendations:"
echo "  10.0.5.200-209: Open WebUI instances"
echo "  10.0.5.210-254: Other dynamic deployments"
echo ""
echo "⚠️  Note: Containers on macvlan cannot communicate with host."
echo "   Use dedicated IPs for all services that need to talk to each other."
