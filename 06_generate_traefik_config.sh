#!/bin/bash
set -e

# ==============================================================================
# STEP 6: GENERATE TRAEFIK CONFIGURATION
# This script generates a Traefik dynamic configuration file
# for routing external traffic to your AI stack
# ==============================================================================

# Check if running as the AI user (not root)
if [ "$EUID" -eq 0 ]; then
  echo "❌ Error: Do NOT run this script as root."
  exit 1
fi

echo "========================================================="
echo "   STEP 6: GENERATE TRAEFIK CONFIGURATION"
echo "========================================================="
echo ""

# Gather information
read -p "Team/Instance Name (e.g., team1, myteam): " TEAM_NAME
TEAM_NAME=$(echo "$TEAM_NAME" | tr '[:upper:]' '[:lower:]' | tr -d ' ')

read -p "Root Domain (e.g., valuechainhackers.xyz): " DOMAIN_ROOT

read -p "Host IP address (e.g., 10.0.5.7): " HOST_IP

# Get LAN IP automatically as default
DEFAULT_IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}' || echo "127.0.0.1")
if [ -z "$HOST_IP" ]; then
    HOST_IP="$DEFAULT_IP"
fi

echo ""
echo "Configuration:"
echo "  Team: $TEAM_NAME"
echo "  Domain: $DOMAIN_ROOT"
echo "  Host IP: $HOST_IP"
echo ""
read -p "Is this correct? (Y/n): " confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "Cancelled. Please run again."
    exit 0
fi

# Generate Traefik YAML
OUTPUT_FILE="traefik_${TEAM_NAME}.yml"

cat > "$OUTPUT_FILE" << EOF
# ==============================================================================
# Traefik Dynamic Configuration for: $TEAM_NAME
# Generated: $(date)
# ==============================================================================

http:
  routers:
    ${TEAM_NAME}-webui:
      rule: "Host(\`${TEAM_NAME}-chat.${DOMAIN_ROOT}\`)"
      service: ${TEAM_NAME}-webui
      tls:
        certResolver: myresolver

    ${TEAM_NAME}-n8n:
      rule: "Host(\`${TEAM_NAME}-n8n.${DOMAIN_ROOT}\`)"
      service: ${TEAM_NAME}-n8n
      tls:
        certResolver: myresolver

    ${TEAM_NAME}-flowise:
      rule: "Host(\`${TEAM_NAME}-flowise.${DOMAIN_ROOT}\`)"
      service: ${TEAM_NAME}-flowise
      tls:
        certResolver: myresolver

    ${TEAM_NAME}-supabase:
      rule: "Host(\`${TEAM_NAME}-supabase.${DOMAIN_ROOT}\`)"
      service: ${TEAM_NAME}-supabase
      tls:
        certResolver: myresolver

    ${TEAM_NAME}-langfuse:
      rule: "Host(\`${TEAM_NAME}-langfuse.${DOMAIN_ROOT}\`)"
      service: ${TEAM_NAME}-langfuse
      tls:
        certResolver: myresolver

    ${TEAM_NAME}-search:
      rule: "Host(\`${TEAM_NAME}-search.${DOMAIN_ROOT}\`)"
      service: ${TEAM_NAME}-search
      tls:
        certResolver: myresolver

    ${TEAM_NAME}-neo4j:
      rule: "Host(\`${TEAM_NAME}-neo4j.${DOMAIN_ROOT}\`)"
      service: ${TEAM_NAME}-neo4j
      tls:
        certResolver: myresolver

    ${TEAM_NAME}-minio:
      rule: "Host(\`${TEAM_NAME}-minio.${DOMAIN_ROOT}\`)"
      service: ${TEAM_NAME}-minio
      tls:
        certResolver: myresolver

  services:
    ${TEAM_NAME}-webui:
      loadBalancer:
        servers:
          - url: "http://${HOST_IP}:8080"

    ${TEAM_NAME}-n8n:
      loadBalancer:
        servers:
          - url: "http://${HOST_IP}:5678"

    ${TEAM_NAME}-flowise:
      loadBalancer:
        servers:
          - url: "http://${HOST_IP}:3001"

    ${TEAM_NAME}-supabase:
      loadBalancer:
        servers:
          - url: "http://${HOST_IP}:8000"

    ${TEAM_NAME}-langfuse:
      loadBalancer:
        servers:
          - url: "http://${HOST_IP}:3300"

    ${TEAM_NAME}-search:
      loadBalancer:
        servers:
          - url: "http://${HOST_IP}:8081"

    ${TEAM_NAME}-neo4j:
      loadBalancer:
        servers:
          - url: "http://${HOST_IP}:7474"

    ${TEAM_NAME}-minio:
      loadBalancer:
        servers:
          - url: "http://${HOST_IP}:9011"

# ==============================================================================
# DEPLOYMENT INSTRUCTIONS
# ==============================================================================
#
# 1. Copy this file to your Traefik server's dynamic configuration directory:
#    scp $OUTPUT_FILE root@10.0.4.10:/opt/traefik-stack/dynamic/
#
# 2. Traefik will automatically detect and load this configuration
#
# 3. Verify in Traefik dashboard:
#    https://traefik.${DOMAIN_ROOT}/dashboard
#
# ==============================================================================
# REQUIRED DNS RECORDS (Add to Cloudflare/DNS provider)
# ==============================================================================
#
# Add A records pointing to your Traefik server (10.0.4.10):
#
#   ${TEAM_NAME}-chat.${DOMAIN_ROOT}      -> 10.0.4.10
#   ${TEAM_NAME}-n8n.${DOMAIN_ROOT}       -> 10.0.4.10
#   ${TEAM_NAME}-flowise.${DOMAIN_ROOT}   -> 10.0.4.10
#   ${TEAM_NAME}-supabase.${DOMAIN_ROOT}  -> 10.0.4.10
#   ${TEAM_NAME}-langfuse.${DOMAIN_ROOT}  -> 10.0.4.10
#   ${TEAM_NAME}-search.${DOMAIN_ROOT}    -> 10.0.4.10
#   ${TEAM_NAME}-neo4j.${DOMAIN_ROOT}     -> 10.0.4.10
#   ${TEAM_NAME}-minio.${DOMAIN_ROOT}     -> 10.0.4.10
#
# ==============================================================================
EOF

echo ""
echo "========================================================="
echo "✅ STEP 6 COMPLETE: Traefik config generated"
echo "========================================================="
echo ""
echo "Output file: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "1. Copy to Traefik server:"
echo "   scp $OUTPUT_FILE root@10.0.4.10:/opt/traefik-stack/dynamic/"
echo ""
echo "2. Add DNS records (see comments in the generated file)"
echo ""
echo "3. Access your services at:"
echo "   - https://${TEAM_NAME}-chat.${DOMAIN_ROOT}"
echo "   - https://${TEAM_NAME}-n8n.${DOMAIN_ROOT}"
echo "   - https://${TEAM_NAME}-flowise.${DOMAIN_ROOT}"
echo "   - etc."
echo ""
echo "========================================================="
