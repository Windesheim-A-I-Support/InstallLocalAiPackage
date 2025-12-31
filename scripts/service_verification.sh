#!/bin/bash

# Enterprise AI Infrastructure - Comprehensive Service Verification
# 
# This script performs detailed, methodical verification of each service
# by checking container reachability, SSH access, and service status
#
# Usage: ./service_verification.sh [OPTIONS]
# Options:
#   -v, --verbose     Show detailed output
#   -s, --service     Check specific service by name
#   -c, --container   Check specific container by IP
#   -h, --help        Show help message

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/service_verification_$(date +%Y%m%d_%H%M%S).log"
VERBOSE=false
SPECIFIC_SERVICE=""
SPECIFIC_CONTAINER=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service definitions with detailed information
declare -A SERVICES
declare -A CONTAINERS

# Initialize service and container mappings
init_services() {
    echo "Initializing service mappings..."
    
    # Core Infrastructure Services
    SERVICES["10.0.5.100"]="Ollama|11434|/api/tags|LLM Inference Engine|Container: ollama|Unsafe Port: 11434|Safe Port: 443 via Traefik"
    SERVICES["10.0.5.101"]="Qdrant|6333|/healthz|Vector Database|Container: qdrant|Unsafe Port: 6333|Safe Port: 443 via Traefik"
    SERVICES["10.0.5.102"]="PostgreSQL|5432||Relational Database|Container: postgres|Unsafe Port: 5432|Database Port"
    SERVICES["10.0.5.103"]="Redis|6379||Cache & Session Store|Container: redis|Unsafe Port: 6379|Cache Port"
    SERVICES["10.0.5.104"]="MinIO|9000|/minio/health/live|Object Storage|Container: minio|Unsafe Port: 9000|Storage Port"
    SERVICES["10.0.5.105"]="SearXNG|8080|/|Privacy Search Engine|Container: searxng|Unsafe Port: 8080|Web Interface"
    SERVICES["10.0.5.106"]="Langfuse|3002|/api/public/health|LLM Observability|Container: langfuse|Unsafe Port: 3002|Web Interface"
    SERVICES["10.0.5.107"]="Neo4j|7474|/|Graph Database|Container: neo4j|Unsafe Port: 7474|Web Interface"
    
    # AI/ML Services
    SERVICES["10.0.5.111"]="Tika|9998|/tika|Document Text Extraction|Container: tika|Unsafe Port: 9998|API Port"
    SERVICES["10.0.5.112"]="Docling|5001|/health|Document Parser|Container: docling|Unsafe Port: 5001|API Port"
    SERVICES["10.0.5.113"]="Whisper|9000|/health|Speech-to-Text|Container: whisper|Unsafe Port: 9000|API Port"
    SERVICES["10.0.5.114"]="LibreTranslate|5000|/languages|Translation API|Container: libretranslate|Unsafe Port: 5000|API Port"
    SERVICES["10.0.5.115"]="MCPO|8765|/health|MCP to OpenAPI Proxy|Container: mcpo|Unsafe Port: 8765|API Port"
    
    # DevOps & Development
    SERVICES["10.0.5.120"]="Gitea|3003|/|Git Server|Container: gitea|Unsafe Port: 3003|Web Interface"
    SERVICES["10.0.5.121"]="Prometheus|9090|/-/healthy|Metrics Collection|Container: prometheus|Unsafe Port: 9090|Web Interface"
    SERVICES["10.0.5.122"]="Grafana|3004|/api/health|Visualization & Dashboards|Container: grafana|Unsafe Port: 3004|Web Interface"
    SERVICES["10.0.5.123"]="Loki|3100|/ready|Log Aggregation|Container: loki|Unsafe Port: 3100|API Port"
    SERVICES["10.0.5.124"]="BookStack|3005|/|Wiki & Documentation|Container: bookstack|Unsafe Port: 3005|Web Interface"
    SERVICES["10.0.5.125"]="Metabase|3006|/api/health|Analytics & BI|Container: metabase|Unsafe Port: 3006|Web Interface"
    SERVICES["10.0.5.126"]="Playwright|3007|/health|Browser Automation|Container: playwright|Unsafe Port: 3007|API Port"
    SERVICES["10.0.5.128"]="Portainer|9443|/api/status|Docker Management|Container: portainer|Unsafe Port: 9443|Web Interface"
    SERVICES["10.0.5.129"]="Formbricks|3008|/|Survey Platform|Container: formbricks|Unsafe Port: 3008|Web Interface"
    
    # Communication & Business
    SERVICES["10.0.5.140"]="Mailcow|443||Mail Server|Container: mailcow|Unsafe Port: 443|Web Interface"
    SERVICES["10.0.5.141"]="EspoCRM|3009|/|Customer Relationship Management|Container: espocrm|Unsafe Port: 3009|Web Interface"
    SERVICES["10.0.5.142"]="Matrix|8008|/_matrix/client/versions|Chat Server|Container: matrix|Unsafe Port: 8008|API Port"
    SERVICES["10.0.5.143"]="Element|3010|/|Matrix Web Client|Container: element|Unsafe Port: 3010|Web Interface"
    SERVICES["10.0.5.144"]="Superset|3011|/health|Business Intelligence|Container: superset|Unsafe Port: 3011|Web Interface"
    SERVICES["10.0.5.145"]="DuckDB|8089|/health|Analytical Database|Container: duckdb|Unsafe Port: 8089|API Port"
    SERVICES["10.0.5.146"]="Authentik|9000|/-/health/live|SSO & Identity Provider|Container: authentik|Unsafe Port: 9000|Web Interface"
    
    # Image Generation & A/V
    SERVICES["10.0.5.160"]="ComfyUI|8188|/|Image Generation Workflows|Container: comfyui|Unsafe Port: 8188|Web Interface"
    SERVICES["10.0.5.161"]="AUTOMATIC1111|7860|/|Stable Diffusion WebUI|Container: automatic1111|Unsafe Port: 7860|Web Interface"
    SERVICES["10.0.5.162"]="faster-whisper|8000|/v1/models|Optimized Speech-to-Text|Container: faster-whisper|Unsafe Port: 8000|API Port"
    SERVICES["10.0.5.163"]="openedai-speech|8001|/v1/models|Text-to-Speech|Container: openedai-speech|Unsafe Port: 8001|API Port"
    
    # Legacy services
    SERVICES["10.0.5.26"]="Nextcloud|443||Cloud Storage|Container: nextcloud|Unsafe Port: 443|Web Interface"
    SERVICES["10.0.5.27"]="Supabase|8000|/health|Backend Platform|Container: supabase|Unsafe Port: 8000|API Port"
    
    # Traefik reverse proxy
    SERVICES["10.0.4.10"]="Traefik|8080|/ping|Reverse Proxy|Container: traefik|Unsafe Port: 8080|Web Interface"
    
    # User containers (10.0.5.200-249)
    for i in {200..249}; do
        CONTAINERS["10.0.5.${i}"]="User Container ${i}|Container: user${i}|Services: openwebui, n8n, jupyter, code-server, etc."
    done
}

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Print usage
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose     Show detailed output"
    echo "  -s, --service     Check specific service by name (e.g., 'Ollama', 'Traefik')"
    echo "  -c, --container   Check specific container by IP (e.g., '10.0.5.100')"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Check all services"
    echo "  $0 -v                 # Verbose output for all services"
    echo "  $0 -s Traefik         # Check only Traefik"
    echo "  $0 -c 10.0.5.100      # Check only container at 10.0.5.100"
    echo "  $0 -s Ollama -v       # Check Ollama with verbose output"
}

# Check if container is reachable via ping
check_container_reachability() {
    local ip="$1"
    local service_name="$2"
    
    echo -e "${BLUE}=== Checking Container Reachability: ${service_name} (${ip}) ===${NC}"
    log "Checking container reachability for ${service_name} at ${ip}"
    
    if ping -c 1 -W 5 "$ip" &>/dev/null; then
        echo -e "${GREEN}✅ Container is reachable via ping${NC}"
        log "SUCCESS: ${service_name} (${ip}) - Container reachable"
        return 0
    else
        echo -e "${RED}❌ Container is NOT reachable via ping${NC}"
        log "FAILED: ${service_name} (${ip}) - Container not reachable"
        return 1
    fi
}

# Check if SSH is enabled and accessible on the container
check_ssh_access() {
    local ip="$1"
    local service_name="$2"
    
    echo -e "${BLUE}=== Checking SSH Access: ${service_name} (${ip}) ===${NC}"
    log "Checking SSH access for ${service_name} at ${ip}"
    
    if ! command -v ssh &>/dev/null; then
        echo -e "${YELLOW}⚠️  SSH command not available on this system${NC}"
        log "WARNING: SSH command not available for ${service_name}"
        return 1
    fi
    
    # Try SSH connection with timeout
    if timeout 10 ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "root@${ip}" "echo 'SSH Connection Successful'" &>/dev/null; then
        echo -e "${GREEN}✅ SSH is accessible${NC}"
        log "SUCCESS: ${service_name} (${ip}) - SSH accessible"
        return 0
    else
        echo -e "${YELLOW}⚠️  SSH is not accessible or not enabled${NC}"
        log "WARNING: ${service_name} (${ip}) - SSH not accessible"
        return 1
    fi
}

# Check service on unsafe port
check_unsafe_port() {
    local ip="$1"
    local port="$2"
    local service_name="$3"
    
    echo -e "${BLUE}=== Checking Unsafe Port: ${service_name} (${ip}:${port}) ===${NC}"
    log "Checking unsafe port ${port} for ${service_name} at ${ip}"
    
    if timeout 10 bash -c "</dev/tcp/${ip}/${port}" 2>/dev/null; then
        echo -e "${GREEN}✅ Unsafe port ${port} is open${NC}"
        log "SUCCESS: ${service_name} (${ip}:${port}) - Unsafe port open"
        return 0
    else
        echo -e "${RED}❌ Unsafe port ${port} is closed or blocked${NC}"
        log "FAILED: ${service_name} (${ip}:${port}) - Unsafe port closed"
        return 1
    fi
}

# Check service on safe port (via Traefik)
check_safe_port() {
    local domain="$1"
    local service_name="$2"
    
    echo -e "${BLUE}=== Checking Safe Port (Traefik): ${service_name} (${domain}) ===${NC}"
    log "Checking safe port via Traefik for ${service_name} at ${domain}"
    
    if curl -s --connect-timeout 10 --max-time 15 "https://${domain}" &>/dev/null; then
        echo -e "${GREEN}✅ Safe port via Traefik is accessible${NC}"
        log "SUCCESS: ${service_name} (${domain}) - Safe port accessible"
        return 0
    else
        echo -e "${YELLOW}⚠️  Safe port via Traefik may not be configured or accessible${NC}"
        log "WARNING: ${service_name} (${domain}) - Safe port not accessible"
        return 1
    fi
}

# Check service endpoint
check_service_endpoint() {
    local ip="$1"
    local port="$2"
    local path="$3"
    local service_name="$4"
    
    echo -e "${BLUE}=== Checking Service Endpoint: ${service_name} (${ip}:${port}${path}) ===${NC}"
    log "Checking service endpoint for ${service_name} at ${ip}:${port}${path}"
    
    local url="http://${ip}:${port}${path}"
    
    if curl -s --connect-timeout 10 --max-time 15 "$url" &>/dev/null; then
        echo -e "${GREEN}✅ Service endpoint is responding${NC}"
        log "SUCCESS: ${service_name} (${ip}:${port}${path}) - Service responding"
        return 0
    else
        echo -e "${RED}❌ Service endpoint is not responding${NC}"
        log "FAILED: ${service_name} (${ip}:${port}${path}) - Service not responding"
        return 1
    fi
}

# Check service login capability
check_service_login() {
    local ip="$1"
    local port="$2"
    local service_name="$3"
    
    echo -e "${BLUE}=== Checking Service Login: ${service_name} (${ip}:${port}) ===${NC}"
    log "Checking login capability for ${service_name} at ${ip}:${port}"
    
    # For web interfaces, try to get the login page
    local url="http://${ip}:${port}"
    
    if curl -s --connect-timeout 10 --max-time 15 "$url" | grep -i "login\|sign.*in\|username\|password" &>/dev/null; then
        echo -e "${GREEN}✅ Service login page is accessible${NC}"
        log "SUCCESS: ${service_name} (${ip}:${port}) - Login page accessible"
        return 0
    else
        echo -e "${YELLOW}⚠️  Service login page not detected or service may not require login${NC}"
        log "INFO: ${service_name} (${ip}:${port}) - Login page not detected"
        return 1
    fi
}

# Comprehensive service check
check_service_comprehensive() {
    local ip="$1"
    local service_info="$2"
    
    IFS='|' read -r service_name port path description container_info unsafe_port_info safe_port_info <<< "$service_info"
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Comprehensive Check: ${service_name}${NC}"
    echo -e "${BLUE}  IP: ${ip}${NC}"
    echo -e "${BLUE}  Port: ${port}${NC}"
    echo -e "${BLUE}  Description: ${description}${NC}"
    echo -e "${BLUE}  Container: ${container_info}${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    local checks_passed=0
    local total_checks=0
    
    # Check 1: Container Reachability
    total_checks=$((total_checks + 1))
    if check_container_reachability "$ip" "$service_name"; then
        checks_passed=$((checks_passed + 1))
    fi
    
    # Check 2: SSH Access
    total_checks=$((total_checks + 1))
    if check_ssh_access "$ip" "$service_name"; then
        checks_passed=$((checks_passed + 1))
    fi
    
    # Check 3: Unsafe Port
    if [[ -n "$port" && "$port" != "0" ]]; then
        total_checks=$((total_checks + 1))
        if check_unsafe_port "$ip" "$port" "$service_name"; then
            checks_passed=$((checks_passed + 1))
        fi
    fi
    
    # Check 4: Service Endpoint
    if [[ -n "$path" ]]; then
        total_checks=$((total_checks + 1))
        if check_service_endpoint "$ip" "$port" "$path" "$service_name"; then
            checks_passed=$((checks_passed + 1))
        fi
    fi
    
    # Check 5: Service Login
    if [[ -n "$port" && "$port" != "0" ]]; then
        total_checks=$((total_checks + 1))
        if check_service_login "$ip" "$port" "$service_name"; then
            checks_passed=$((checks_passed + 1))
        fi
    fi
    
    # Summary
    echo ""
    echo -e "${BLUE}=== Summary for ${service_name} ===${NC}"
    echo -e "Checks Passed: ${checks_passed}/${total_checks}"
    
    if [[ $checks_passed -eq $total_checks ]]; then
        echo -e "${GREEN}🎉 All checks passed! Service is fully operational.${NC}"
        log "COMPLETE: ${service_name} (${ip}) - All checks passed (${checks_passed}/${total_checks})"
    elif [[ $checks_passed -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Partial success. Some checks passed, some failed.${NC}"
        log "PARTIAL: ${service_name} (${ip}) - Partial success (${checks_passed}/${total_checks})"
    else
        echo -e "${RED}❌ All checks failed. Service may not be operational.${NC}"
        log "FAILED: ${service_name} (${ip}) - All checks failed (${checks_passed}/${total_checks})"
    fi
    
    echo ""
}

# Check specific service by name
check_specific_service() {
    local service_name="$1"
    local found=false
    
    echo -e "${BLUE}=== Searching for service: ${service_name} ===${NC}"
    
    for ip in "${!SERVICES[@]}"; do
        local service_info="${SERVICES[$ip]}"
        IFS='|' read -r current_service_name port path description container_info unsafe_port_info safe_port_info <<< "$service_info"
        
        if [[ "${current_service_name,,}" == "${service_name,,}" ]]; then
            found=true
            check_service_comprehensive "$ip" "$service_info"
            break
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        echo -e "${RED}❌ Service '${service_name}' not found in the service list.${NC}"
        echo "Available services:"
        for ip in "${!SERVICES[@]}"; do
            IFS='|' read -r service_name port path description container_info unsafe_port_info safe_port_info <<< "${SERVICES[$ip]}"
            echo "  - $service_name"
        done
    fi
}

# Check specific container by IP
check_specific_container() {
    local ip="$1"
    
    echo -e "${BLUE}=== Checking container: ${ip} ===${NC}"
    
    if [[ -n "${SERVICES[$ip]:-}" ]]; then
        check_service_comprehensive "$ip" "${SERVICES[$ip]}"
    elif [[ -n "${CONTAINERS[$ip]:-}" ]]; then
        echo -e "${YELLOW}User container found: ${CONTAINERS[$ip]}${NC}"
        check_container_reachability "$ip" "User Container"
        check_ssh_access "$ip" "User Container"
    else
        echo -e "${RED}❌ IP ${ip} not found in service or container lists.${NC}"
        echo "Available service IPs:"
        for service_ip in "${!SERVICES[@]}"; do
            echo "  - $service_ip"
        done
        echo "Available user container IPs:"
        for container_ip in "${!CONTAINERS[@]}"; do
            echo "  - $container_ip"
        done
    fi
}

# Check all services
check_all_services() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Starting Comprehensive Service Verification${NC}"
    echo -e "${BLUE}  Total services to check: ${#SERVICES[@]}${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    local total_services=${#SERVICES[@]}
    local current_service=0
    
    for ip in "${!SERVICES[@]}"; do
        current_service=$((current_service + 1))
        echo -e "${BLUE}--- Service ${current_service}/${total_services} ---${NC}"
        check_service_comprehensive "$ip" "${SERVICES[$ip]}"
        
        # Add delay between services to prevent overwhelming the system
        if [[ "$VERBOSE" == "false" ]]; then
            sleep 2
        fi
    done
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Service verification complete${NC}"
    echo -e "${BLUE}  Total services checked: ${total_services}${NC}"
    echo -e "${BLUE}  Log file: ${LOG_FILE}${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Main execution
main() {
    # Initialize services
    init_services
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--service)
                SPECIFIC_SERVICE="$2"
                shift 2
                ;;
            -c|--container)
                SPECIFIC_CONTAINER="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Create log file
    echo "Service Verification Started: $(date)" > "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    
    # Execute based on options
    if [[ -n "$SPECIFIC_SERVICE" ]]; then
        check_specific_service "$SPECIFIC_SERVICE"
    elif [[ -n "$SPECIFIC_CONTAINER" ]]; then
        check_specific_container "$SPECIFIC_CONTAINER"
    else
        check_all_services
    fi
    
    echo ""
    echo -e "${BLUE}Service verification completed. Check log file: ${LOG_FILE}${NC}"
}

# Run main function with all arguments
main "$@"
