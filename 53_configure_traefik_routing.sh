#!/bin/bash
set -e

# Traefik Dynamic Configuration Generator
# Creates individual dynamic config files for each service
# Naming: 205{last_octet}.yml (e.g., 205100.yml for 10.0.5.100)
# Usage: bash 53_configure_traefik_routing.sh

# Root check removed - uses SSH to configure remote Traefik server

echo "=== Traefik Dynamic Configuration Generator ==="
echo ""

# Traefik container IP (from ARCHITECTURE.md)
TRAEFIK_IP="10.0.4.10"
TRAEFIK_CONFIG_DIR="/opt/traefik-stack/dynamic"

# SSH to Traefik container to create configs
echo "Connecting to Traefik container at $TRAEFIK_IP..."

# Create directory on Traefik server
ssh root@${TRAEFIK_IP} "mkdir -p ${TRAEFIK_CONFIG_DIR}"

echo "Creating Traefik dynamic configurations in: $TRAEFIK_CONFIG_DIR"
echo ""

# Function to create Traefik config
create_traefik_config() {
  local SERVICE_NAME="$1"
  local SERVICE_IP="$2"
  local SERVICE_PORT="$3"
  local SUBDOMAIN="$4"
  local ENTRYPOINT="${5:-websecure}"  # Default to HTTPS

  # Extract last octet from IP
  local LAST_OCTET=$(echo "$SERVICE_IP" | awk -F'.' '{print $NF}')
  local CONFIG_FILE="${TRAEFIK_CONFIG_DIR}/205${LAST_OCTET}.yml"

  echo "  → ${SUBDOMAIN}.valuechainhackers.xyz → ${SERVICE_IP}:${SERVICE_PORT}"

  ssh root@${TRAEFIK_IP} "cat > ${CONFIG_FILE}" << EOF
# Traefik Dynamic Configuration
# Service: ${SERVICE_NAME}
# Backend: ${SERVICE_IP}:${SERVICE_PORT}
# Domain: ${SUBDOMAIN}.valuechainhackers.xyz

http:
  routers:
    ${SERVICE_NAME}-router:
      rule: "Host(\`${SUBDOMAIN}.valuechainhackers.xyz\`)"
      service: ${SERVICE_NAME}-service
      entryPoints:
        - ${ENTRYPOINT}
      tls:
        certResolver: letsencrypt

  services:
    ${SERVICE_NAME}-service:
      loadBalancer:
        servers:
          - url: "http://${SERVICE_IP}:${SERVICE_PORT}"
EOF
}

# Core Infrastructure (100-105)
echo "Core Infrastructure:"
create_traefik_config "ollama" "10.0.5.100" "11434" "ollama"
create_traefik_config "qdrant" "10.0.5.101" "6333" "qdrant"
create_traefik_config "postgres" "10.0.5.102" "5432" "postgres" "tcp"  # PostgreSQL uses TCP
create_traefik_config "redis" "10.0.5.103" "6379" "redis" "tcp"  # Redis uses TCP
create_traefik_config "minio" "10.0.5.104" "9001" "minio"  # MinIO Console
create_traefik_config "minio-api" "10.0.5.104" "9000" "s3"  # MinIO API
create_traefik_config "searxng" "10.0.5.105" "8080" "search"

# Monitoring Stack (121-123)
echo "Monitoring Stack:"
create_traefik_config "prometheus" "10.0.5.121" "9090" "prometheus"
create_traefik_config "grafana" "10.0.5.122" "3000" "grafana"
create_traefik_config "loki" "10.0.5.123" "3100" "loki"

# Optional: Langfuse (106)
if ping -c 1 10.0.5.106 &>/dev/null; then
  echo "Observability:"
  create_traefik_config "langfuse" "10.0.5.106" "3000" "langfuse"
fi

# Optional: Gitea (120)
if ping -c 1 10.0.5.120 &>/dev/null; then
  echo "DevOps:"
  create_traefik_config "gitea" "10.0.5.120" "3000" "git"
fi

echo ""
echo "✅ Traefik dynamic configurations created"
echo ""
echo "Configuration files:"
ssh root@${TRAEFIK_IP} "ls -lh ${TRAEFIK_CONFIG_DIR}/205*.yml"
echo ""
echo "⚠️  IMPORTANT: Restart Traefik to apply changes:"
echo "   ssh root@${TRAEFIK_IP} 'cd /opt/traefik-stack && docker compose restart traefik'"
echo ""
echo "⚠️  DNS Records Required:"
echo "   Add CNAME/A records pointing to Traefik IP ($TRAEFIK_IP):"
echo ""
echo "   ollama.valuechainhackers.xyz     → $TRAEFIK_IP"
echo "   qdrant.valuechainhackers.xyz     → $TRAEFIK_IP"
echo "   minio.valuechainhackers.xyz      → $TRAEFIK_IP"
echo "   s3.valuechainhackers.xyz         → $TRAEFIK_IP"
echo "   search.valuechainhackers.xyz     → $TRAEFIK_IP"
echo "   prometheus.valuechainhackers.xyz → $TRAEFIK_IP"
echo "   grafana.valuechainhackers.xyz    → $TRAEFIK_IP"
echo "   loki.valuechainhackers.xyz       → $TRAEFIK_IP"
