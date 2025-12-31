#!/bin/bash

# Enterprise AI Infrastructure - Service Health Check Script
# 
# This script performs comprehensive health checks on all shared services
# and per-user containers in the multi-user AI infrastructure.
#
# Usage: ./service_health_check.sh [OPTIONS]
# Options:
#   -v, --verbose     Show detailed output
#   -q, --quiet       Show only failed services
#   -u, --users       Check per-user containers (slower)
#   -h, --help        Show help message

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/health_check_$(date +%Y%m%d_%H%M%S).log"
VERBOSE=false
QUIET=false
CHECK_USERS=false
GENERATE_UPTIME=false
EXIT_CODE=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service definitions
declare -A SHARED_SERVICES
declare -A USER_CONTAINERS
declare -A SERVICE_DEPENDENCIES
declare -A SERVICE_PERFORMANCE_THRESHOLDS

# Initialize service arrays
init_services() {
    # Core Infrastructure (10.0.5.100-119)
    SHARED_SERVICES["10.0.5.100"]="Ollama|11434|/api/tags|LLM Inference Engine"
    SHARED_SERVICES["10.0.5.101"]="Qdrant|6333|/healthz|Vector Database"
    SHARED_SERVICES["10.0.5.102"]="PostgreSQL|5432||Relational Database"
    SHARED_SERVICES["10.0.5.103"]="Redis|6379||Cache & Session Store"
    SHARED_SERVICES["10.0.5.104"]="MinIO|9000|/minio/health/live|Object Storage"
    SHARED_SERVICES["10.0.5.105"]="SearXNG|8080|/|Privacy Search Engine"
    SHARED_SERVICES["10.0.5.106"]="Langfuse|3002|/api/public/health|LLM Observability"
    SHARED_SERVICES["10.0.5.107"]="Neo4j|7474|/|Graph Database"
    
    # AI/ML Services (10.0.5.111-115)
    SHARED_SERVICES["10.0.5.111"]="Tika|9998|/tika|Document Text Extraction"
    SHARED_SERVICES["10.0.5.112"]="Docling|5001|/health|Document Parser"
    SHARED_SERVICES["10.0.5.113"]="Whisper|9000|/health|Speech-to-Text"
    SHARED_SERVICES["10.0.5.114"]="LibreTranslate|5000|/languages|Translation API"
    SHARED_SERVICES["10.0.5.115"]="MCPO|8765|/health|MCP to OpenAPI Proxy"
    
    # DevOps & Development (10.0.5.120-139)
    SHARED_SERVICES["10.0.5.120"]="Gitea|3003|/|Git Server"
    SHARED_SERVICES["10.0.5.121"]="Prometheus|9090|/-/healthy|Metrics Collection"
    SHARED_SERVICES["10.0.5.122"]="Grafana|3004|/api/health|Visualization & Dashboards"
    SHARED_SERVICES["10.0.5.123"]="Loki|3100|/ready|Log Aggregation"
    SHARED_SERVICES["10.0.5.124"]="BookStack|3005|/|Wiki & Documentation"
    SHARED_SERVICES["10.0.5.125"]="Metabase|3006|/api/health|Analytics & BI"
    SHARED_SERVICES["10.0.5.126"]="Playwright|3007|/health|Browser Automation"
    SHARED_SERVICES["10.0.5.128"]="Portainer|9443|/api/status|Docker Management"
    SHARED_SERVICES["10.0.5.129"]="Formbricks|3008|/|Survey Platform"
    
    # Communication & Business (10.0.5.140-159)
    SHARED_SERVICES["10.0.5.140"]="Mailcow|443||Mail Server"
    SHARED_SERVICES["10.0.5.141"]="EspoCRM|3009|/|Customer Relationship Management"
    SHARED_SERVICES["10.0.5.142"]="Matrix|8008|/_matrix/client/versions|Chat Server"
    SHARED_SERVICES["10.0.5.143"]="Element|3010|/|Matrix Web Client"
    SHARED_SERVICES["10.0.5.144"]="Superset|3011|/health|Business Intelligence"
    SHARED_SERVICES["10.0.5.145"]="DuckDB|8089|/health|Analytical Database"
    SHARED_SERVICES["10.0.5.146"]="Authentik|9000|/-/health/live|SSO & Identity Provider"
    
    # Image Generation & A/V (10.0.5.160-179)
    SHARED_SERVICES["10.0.5.160"]="ComfyUI|8188|/|Image Generation Workflows"
    SHARED_SERVICES["10.0.5.161"]="AUTOMATIC1111|7860|/|Stable Diffusion WebUI"
    SHARED_SERVICES["10.0.5.162"]="faster-whisper|8000|/v1/models|Optimized Speech-to-Text"
    SHARED_SERVICES["10.0.5.163"]="openedai-speech|8001|/v1/models|Text-to-Speech"
    
    # Legacy services
    SHARED_SERVICES["10.0.5.26"]="Nextcloud|443||Cloud Storage"
    SHARED_SERVICES["10.0.5.27"]="Supabase|8000|/health|Backend Platform"
    
    # User containers (10.0.5.200-249)
    for i in {200..249}; do
        USER_CONTAINERS["10.0.5.${i}"]="User Container ${i}"
    done
    
    # Service dependencies mapping
    SERVICE_DEPENDENCIES["Ollama"]="PostgreSQL,Redis,MinIO"
    SERVICE_DEPENDENCIES["Qdrant"]="PostgreSQL"
    SERVICE_DEPENDENCIES["Langfuse"]="PostgreSQL"
    SERVICE_DEPENDENCIES["Gitea"]="PostgreSQL"
    SERVICE_DEPENDENCIES["BookStack"]="PostgreSQL"
    SERVICE_DEPENDENCIES["Metabase"]="PostgreSQL"
    SERVICE_DEPENDENCIES["Formbricks"]="PostgreSQL"
    SERVICE_DEPENDENCIES["EspoCRM"]="PostgreSQL"
    SERVICE_DEPENDENCIES["Superset"]="PostgreSQL"
    SERVICE_DEPENDENCIES["Authentik"]="PostgreSQL,Redis"
    
    # Performance thresholds (response time in milliseconds)
    SERVICE_PERFORMANCE_THRESHOLDS["Ollama"]=5000
    SERVICE_PERFORMANCE_THRESHOLDS["Qdrant"]=2000
    SERVICE_PERFORMANCE_THRESHOLDS["PostgreSQL"]=1000
    SERVICE_PERFORMANCE_THRESHOLDS["Redis"]=500
    SERVICE_PERFORMANCE_THRESHOLDS["MinIO"]=3000
    SERVICE_PERFORMANCE_THRESHOLDS["Langfuse"]=2000
    SERVICE_PERFORMANCE_THRESHOLDS["Gitea"]=3000
    SERVICE_PERFORMANCE_THRESHOLDS["Grafana"]=2000
    SERVICE_PERFORMANCE_THRESHOLDS["Prometheus"]=1000
}

# Logging functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Enterprise AI Infrastructure${NC}"
    echo -e "${BLUE}  Service Health Check Report${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Generated: $(date)${NC}"
    echo -e "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose     Show detailed output"
    echo "  -q, --quiet       Show only failed services"
    echo "  -u, --users       Check per-user containers (slower)"
    echo "  -t, --uptime      Generate uptime report from historical data"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Quick check of shared services only"
    echo "  $0 -v                 # Verbose output"
    echo "  $0 -u                 # Check all services including users"
    echo "  $0 -v -u              # Full verbose check"
    echo "  $0 -t                 # Generate uptime report"
}

# Network connectivity check
check_network() {
    local host="$1"
    local timeout="${2:-5}"
    
    if ping -c 1 -W "$timeout" "$host" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Complete service check with proper sequence: Ping → SSH → Service
check_service_complete() {
    local ip="$1"
    local port="$2"
    local path="$3"
    local name="$4"
    local timeout=10
    
    # Step 1: Network connectivity check (Ping)
    if ! check_network "$ip"; then
        if [[ "$QUIET" == "false" ]]; then
            echo -e "${RED}❌ ${name} (${ip}) - Network unreachable${NC}"
        fi
        log "FAILED: ${name} (${ip}) - Network unreachable"
        return 1
    fi
    
    # Step 2: SSH connectivity check (if SSH is available)
    if command -v ssh &>/dev/null; then
        if ssh -o ConnectTimeout=5 -o BatchMode=yes "root@${ip}" "echo 'SSH OK'" &>/dev/null; then
            if [[ "$VERBOSE" == "true" ]]; then
                echo -e "   ${BLUE}SSH: Connected to ${ip}${NC}"
            fi
        else
            if [[ "$VERBOSE" == "true" ]]; then
                echo -e "   ${YELLOW}SSH: Not available or failed for ${ip}${NC}"
            fi
        fi
    fi
    
    # Step 3: Service availability check
    if [[ -n "$path" ]]; then
        # HTTP service check
        local url="http://${ip}:${port}${path}"
        local start_time=$(date +%s%N)
        
        if curl -s --connect-timeout "$timeout" --max-time "$timeout" "$url" >/dev/null 2>&1; then
            local end_time=$(date +%s%N)
            local response_time=$(( (end_time - start_time) / 1000000 ))
            
            # Check performance threshold
            if [[ -n "${SERVICE_PERFORMANCE_THRESHOLDS[$name]:-}" ]]; then
                local threshold=${SERVICE_PERFORMANCE_THRESHOLDS[$name]}
                if [[ $response_time -gt $threshold ]]; then
                    log "WARNING: ${name} (${ip}:${port}) - Slow response: ${response_time}ms (threshold: ${threshold}ms)"
                    if [[ "$VERBOSE" == "true" ]]; then
                        echo -e "   ${YELLOW}⚠️  Performance warning: ${response_time}ms${NC}"
                    fi
                fi
            fi
            
            if [[ "$QUIET" == "false" ]]; then
                echo -e "${GREEN}✅ ${name} (${ip}:${port}) - Healthy${NC}"
            fi
            log "OK: ${name} (${ip}:${port}) - Healthy"
            return 0
        else
            if [[ "$QUIET" == "false" ]]; then
                echo -e "${RED}❌ ${name} (${ip}:${port}) - Service down${NC}"
            fi
            log "FAILED: ${name} (${ip}:${port}) - Service down"
            return 1
        fi
    else
        # TCP port check
        if check_tcp_port "$ip" "$port"; then
            if [[ "$QUIET" == "false" ]]; then
                echo -e "${GREEN}✅ ${name} (${ip}:${port}) - Port open${NC}"
            fi
            log "OK: ${name} (${ip}:${port}) - Port open"
            return 0
        else
            if [[ "$QUIET" == "false" ]]; then
                echo -e "${RED}❌ ${name} (${ip}:${port}) - Port closed${NC}"
            fi
            log "FAILED: ${name} (${ip}:${port}) - Port closed"
            return 1
        fi
    fi
}

# Advanced service status check with dependency validation
check_service_with_dependencies() {
    local ip="$1"
    local port="$2"
    local path="$3"
    local name="$4"
    
    # Check network connectivity first
    if ! check_network "$ip"; then
        return 1
    fi
    
    # Check dependencies if they exist
    if [[ -n "${SERVICE_DEPENDENCIES[$name]:-}" ]]; then
        local dependencies="${SERVICE_DEPENDENCIES[$name]}"
        IFS=',' read -ra DEP_ARRAY <<< "$dependencies"
        
        for dep in "${DEP_ARRAY[@]}"; do
            dep=$(echo "$dep" | xargs) # trim whitespace
            if ! check_service_dependency "$dep"; then
                log "WARNING: ${name} (${ip}:${port}) - Dependency ${dep} is down"
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -e "   ${YELLOW}⚠️  Dependency issue: ${dep} not available${NC}"
                fi
            fi
        done
    fi
    
    # Check the service itself
    if [[ -n "$path" ]]; then
        check_http_service "$ip" "$port" "$path" "$name"
    else
        check_tcp_port "$ip" "$port"
    fi
}

# Check if a service dependency is available
check_service_dependency() {
    local service_name="$1"
    
    # Map service names to IPs
    case "$service_name" in
        "PostgreSQL") check_tcp_port "10.0.5.102" "5432" ;;
        "Redis") check_tcp_port "10.0.5.103" "6379" ;;
        "MinIO") check_http_service "10.0.5.104" "9000" "/minio/health/live" "MinIO" ;;
        *) return 1 ;;
    esac
}

# Check Docker container status and resource usage
check_docker_container_status() {
    local container_name="$1"
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "^${container_name}\s"; then
        local status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "^${container_name}\s" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
        
        # Get container resource usage
        if docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep -q "^${container_name}\s"; then
            local stats=$(docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep "^${container_name}\s")
            if [[ "$VERBOSE" == "true" ]]; then
                echo -e "   ${BLUE}Resource Usage: ${stats}${NC}"
            fi
        fi
        
        if [[ "$status" == *"Up"* ]]; then
            return 0
        fi
    fi
    return 1
}

# Check user container services in detail
check_user_container_services() {
    local ip="$1"
    local container_id=$(echo $ip | cut -d'.' -f4)
    local services_healthy=0
    local total_services=0
    
    # Define expected services for user containers
    local user_services=("openwebui" "n8n" "jupyter" "code-server" "big-agi" "chainforge" "kotaemon" "flowise")
    local user_ports=(8080 5678 8888 8443 3012 8000 7860 3000)
    
    for i in "${!user_services[@]}"; do
        local service="${user_services[$i]}"
        local port="${user_ports[$i]}"
        total_services=$((total_services + 1))
        
        if pct exec "$container_id" -- curl -s --connect-timeout 5 "http://localhost:${port}" >/dev/null 2>&1; then
            services_healthy=$((services_healthy + 1))
            if [[ "$VERBOSE" == "true" ]]; then
                echo -e "     ${GREEN}✅ ${service} (port ${port})${NC}"
            fi
        else
            if [[ "$QUIET" == "false" ]]; then
                echo -e "     ${RED}❌ ${service} (port ${port})${NC}"
            fi
        fi
    done
    
    echo "$services_healthy:$total_services"
}

# TCP port check
check_tcp_port() {
    local ip="$1"
    local port="$2"
    local timeout=5
    
    if timeout "$timeout" bash -c "</dev/tcp/${ip}/${port}" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Docker service check
check_docker_service() {
    local container_name="$1"
    local expected_status="$2"
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "^${container_name}\s"; then
        local status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "^${container_name}\s" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
        if [[ "$status" == *"$expected_status"* ]]; then
            return 0
        fi
    fi
    return 1
}

# Asynchronous service checker worker function
check_service_worker() {
    local ip="$1"
    local port="$2"
    local path="$3"
    local name="$4"
    local result_file="$5"
    
    # Perform the complete service check
    if check_service_complete "$ip" "$port" "$path" "$name" > /dev/null 2>&1; then
        echo "SUCCESS:$name:$ip:$port" >> "$result_file"
    else
        echo "FAILED:$name:$ip:$port" >> "$result_file"
    fi
}

# Check shared services with proper sequence: Ping → SSH → Service (Asynchronous)
check_shared_services() {
    local total_services=0
    local healthy_services=0
    local failed_services=()
    local result_file="/tmp/health_check_results_$$.tmp"
    local pids=()
    
    echo -e "${YELLOW}Checking Shared Services...${NC}"
    log "Starting shared services health check"
    
    # Start all service checks in parallel
    for ip in "${!SHARED_SERVICES[@]}"; do
        IFS='|' read -r name port path description <<< "${SHARED_SERVICES[$ip]}"
        total_services=$((total_services + 1))
        
        # Start service check in background
        check_service_worker "$ip" "$port" "$path" "$name" "$result_file" &
        pids+=($!)
        
        # Limit concurrent processes to prevent system overload
        if [[ ${#pids[@]} -ge 10 ]]; then
            wait "${pids[0]}"
            pids=("${pids[@]:1}")
        fi
        
        # Verbose output for service details
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "   ${BLUE}Checking: ${name} (${ip}:${port})${NC}"
            echo -e "   ${BLUE}Description: ${description}${NC}"
            echo ""
        fi
    done
    
    # Wait for all background processes to complete
    wait "${pids[@]}"
    
    # Process results
    if [[ -f "$result_file" ]]; then
        while IFS=':' read -r status name ip port; do
            case "$status" in
                "SUCCESS")
                    healthy_services=$((healthy_services + 1))
                    if [[ "$QUIET" == "false" ]]; then
                        echo -e "${GREEN}✅ ${name} (${ip}:${port}) - Healthy${NC}"
                    fi
                    log "OK: ${name} (${ip}:${port}) - Healthy"
                    ;;
                "FAILED")
                    failed_services+=("${name} (${ip}:${port})")
                    if [[ "$QUIET" == "false" ]]; then
                        echo -e "${RED}❌ ${name} (${ip}:${port}) - Service down${NC}"
                    fi
                    log "FAILED: ${name} (${ip}:${port}) - Service down"
                    EXIT_CODE=1
                    ;;
            esac
        done < "$result_file"
        
        # Clean up temporary file
        rm -f "$result_file"
    fi
    
    echo ""
    echo -e "${YELLOW}Shared Services Summary:${NC}"
    echo -e "  Total: ${total_services}"
    echo -e "  Healthy: ${healthy_services}"
    echo -e "  Failed: ${#failed_services[@]}"
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        echo -e "  Failed Services:"
        for service in "${failed_services[@]}"; do
            echo -e "    - ${service}"
        done
    fi
    
    log "Shared services check complete: ${healthy_services}/${total_services} healthy"
    echo ""
}

# Check user containers
check_user_containers() {
    if [[ "$CHECK_USERS" == "false" ]]; then
        echo -e "${YELLOW}Skipping user containers (use -u flag to check)${NC}"
        echo ""
        return
    fi
    
    local total_users=0
    local healthy_users=0
    local failed_users=()
    
    echo -e "${YELLOW}Checking User Containers...${NC}"
    log "Starting user containers health check"
    
    for ip in "${!USER_CONTAINERS[@]}"; do
        total_users=$((total_users + 1))
        local container_name="${USER_CONTAINERS[$ip]}"
        
        # Check network connectivity
        if ! check_network "$ip"; then
            if [[ "$QUIET" == "false" ]]; then
                echo -e "${RED}❌ ${container_name} (${ip}) - Network unreachable${NC}"
            fi
            log "FAILED: ${container_name} (${ip}) - Network unreachable"
            failed_users+=("${container_name} (${ip})")
            EXIT_CODE=1
            continue
        fi
        
        # Check if Docker is running inside container
        if pct exec "$(echo $ip | cut -d'.' -f4)" -- docker info &>/dev/null; then
            if [[ "$QUIET" == "false" ]]; then
                echo -e "${GREEN}✅ ${container_name} (${ip}) - Docker running${NC}"
            fi
            log "OK: ${container_name} (${ip}) - Docker running"
            healthy_users=$((healthy_users + 1))
        else
            if [[ "$QUIET" == "false" ]]; then
                echo -e "${RED}❌ ${container_name} (${ip}) - Docker not running${NC}"
            fi
            log "FAILED: ${container_name} (${ip}) - Docker not running"
            failed_users+=("${container_name} (${ip})")
            EXIT_CODE=1
        fi
        
        # Check individual services inside container (if verbose)
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "   ${BLUE}Checking services inside ${container_name}:${NC}"
            
            # Check Open WebUI
            if pct exec "$(echo $ip | cut -d'.' -f4)" -- curl -s http://localhost:8080 >/dev/null 2>&1; then
                echo -e "     ${GREEN}✅ Open WebUI (port 8080)${NC}"
            else
                echo -e "     ${RED}❌ Open WebUI (port 8080)${NC}"
            fi
            
            # Check n8n
            if pct exec "$(echo $ip | cut -d'.' -f4)" -- curl -s http://localhost:5678 >/dev/null 2>&1; then
                echo -e "     ${GREEN}✅ n8n (port 5678)${NC}"
            else
                echo -e "     ${RED}❌ n8n (port 5678)${NC}"
            fi
            
            # Check Jupyter
            if pct exec "$(echo $ip | cut -d'.' -f4)" -- curl -s http://localhost:8888 >/dev/null 2>&1; then
                echo -e "     ${GREEN}✅ Jupyter (port 8888)${NC}"
            else
                echo -e "     ${RED}❌ Jupyter (port 8888)${NC}"
            fi
        fi
    done
    
    echo ""
    echo -e "${YELLOW}User Containers Summary:${NC}"
    echo -e "  Total: ${total_users}"
    echo -e "  Healthy: ${healthy_users}"
    echo -e "  Failed: ${#failed_users[@]}"
    
    if [[ ${#failed_users[@]} -gt 0 ]]; then
        echo -e "  Failed Containers:"
        for container in "${failed_users[@]}"; do
            echo -e "    - ${container}"
        done
    fi
    
    log "User containers check complete: ${healthy_users}/${total_users} healthy"
    echo ""
}

# Check Traefik reverse proxy with proper sequence: Ping → SSH → Service
check_traefik() {
    echo -e "${YELLOW}Checking Traefik Reverse Proxy...${NC}"
    log "Checking Traefik at 10.0.4.10"
    
    # Use the complete service check that follows Ping → SSH → Service sequence
    if check_service_complete "10.0.4.10" "8080" "/ping" "Traefik"; then
        echo -e "${GREEN}✅ Traefik (10.0.4.10:8080) - Healthy${NC}"
        log "OK: Traefik (10.0.4.10:8080) - Healthy"
    else
        echo -e "${RED}❌ Traefik (10.0.4.10:8080) - Service down${NC}"
        log "FAILED: Traefik (10.0.4.10:8080) - Service down"
        EXIT_CODE=1
    fi
    echo ""
}

# Generate detailed summary report with trend analysis
generate_summary() {
    local duration=$(($(date +%s) - START_TIME))
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Health Check Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [[ $EXIT_CODE -eq 0 ]]; then
        echo -e "${GREEN}🎉 All services are healthy!${NC}"
        log "Overall status: HEALTHY"
    else
        echo -e "${RED}⚠️  Some services are experiencing issues${NC}"
        log "Overall status: ISSUES DETECTED"
    fi
    
    echo ""
    echo -e "${BLUE}Quick Stats:${NC}"
    echo -e "  Log file: ${LOG_FILE}"
    echo -e "  Duration: ${duration} seconds"
    echo -e "  Exit code: $EXIT_CODE"
    
    # Generate trend analysis if previous logs exist
    generate_trend_analysis
    
    # Generate alert summary
    generate_alert_summary
    
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo -e "  • Review failed services above"
    echo -e "  • Check detailed logs in ${LOG_FILE}"
    echo -e "  • Restart failed services if needed"
    echo -e "  • Run with -v flag for more details"
    echo ""
}

# Generate trend analysis from previous logs
generate_trend_analysis() {
    echo -e "${BLUE}Trend Analysis:${NC}"
    
    # Find previous log files
    local log_dir="$(dirname "$LOG_FILE")"
    local recent_logs=($(find "$log_dir" -name "health_check_*.log" -mtime -7 | sort -r | head -5))
    
    if [[ ${#recent_logs[@]} -gt 1 ]]; then
        echo -e "  Analyzing last ${#recent_logs[@]} checks..."
        
        # Count healthy vs failed services over time
        local avg_healthy=0
        local avg_failed=0
        local total_checks=0
        
        for log_file in "${recent_logs[@]}"; do
            if [[ "$log_file" != "$LOG_FILE" ]]; then
                local healthy_count=$(grep -c "OK:" "$log_file" 2>/dev/null || echo "0")
                local failed_count=$(grep -c "FAILED:" "$log_file" 2>/dev/null || echo "0")
                
                if [[ $healthy_count -gt 0 ]] || [[ $failed_count -gt 0 ]]; then
                    avg_healthy=$((avg_healthy + healthy_count))
                    avg_failed=$((avg_failed + failed_count))
                    total_checks=$((total_checks + 1))
                fi
            fi
        done
        
        if [[ $total_checks -gt 0 ]]; then
            avg_healthy=$((avg_healthy / total_checks))
            avg_failed=$((avg_failed / total_checks))
            
            echo -e "  Average healthy services: ${avg_healthy}"
            echo -e "  Average failed services: ${avg_failed}"
            
            # Compare with current results
            local current_healthy=$(grep -c "OK:" "$LOG_FILE" 2>/dev/null || echo "0")
            local current_failed=$(grep -c "FAILED:" "$LOG_FILE" 2>/dev/null || echo "0")
            
            if [[ $current_healthy -gt $avg_healthy ]]; then
                echo -e "  ${GREEN}📈 Service health improved!${NC}"
            elif [[ $current_healthy -lt $avg_healthy ]]; then
                echo -e "  ${RED}📉 Service health declined!${NC}"
            else
                echo -e "  ${BLUE}➡️  Service health stable${NC}"
            fi
        fi
    else
        echo -e "  Insufficient historical data for trend analysis"
    fi
}

# Generate alert summary for critical services
generate_alert_summary() {
    echo -e "${BLUE}Alert Summary:${NC}"
    
    # Check for critical service failures
    local critical_services=("PostgreSQL" "Redis" "MinIO" "Ollama" "Qdrant" "Traefik")
    local critical_failures=()
    
    for service in "${critical_services[@]}"; do
        if grep -q "FAILED.*${service}" "$LOG_FILE" 2>/dev/null; then
            critical_failures+=("$service")
        fi
    done
    
    if [[ ${#critical_failures[@]} -gt 0 ]]; then
        echo -e "  ${RED}🚨 Critical service failures detected:${NC}"
        for failure in "${critical_failures[@]}"; do
            echo -e "    • ${failure}"
        done
        echo -e "  ${RED}Immediate attention required!${NC}"
    else
        echo -e "  ${GREEN}✅ No critical service failures${NC}"
    fi
    
    # Check for dependency warnings
    local dependency_warnings=$(grep -c "WARNING.*Dependency" "$LOG_FILE" 2>/dev/null || echo "0")
    if [[ $dependency_warnings -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠️  ${dependency_warnings} dependency warnings detected${NC}"
    fi
}

# Send alert notification (email, webhook, etc.)
send_alert() {
    local alert_type="$1"
    local message="$2"
    local recipients="$3"
    
    # Log the alert
    log "ALERT: ${alert_type} - ${message}"
    
    # Send email if mail command is available
    if command -v mail &>/dev/null && [[ -n "$recipients" ]]; then
        echo "${message}" | mail -s "AI Infrastructure Alert: ${alert_type}" "$recipients"
        log "Email alert sent to: $recipients"
    fi
    
    # Send to webhook if configured
    local webhook_url="${ALERT_WEBHOOK_URL:-}"
    if [[ -n "$webhook_url" ]]; then
        curl -s -X POST -H "Content-Type: application/json" \
            -d "{\"alert_type\":\"${alert_type}\",\"message\":\"${message}\"}" \
            "$webhook_url" &>/dev/null
        log "Webhook alert sent to: $webhook_url"
    fi
}

# Check for service degradation patterns
check_service_degradation() {
    local service_name="$1"
    local current_status="$2"
    
    # Check last 3 logs for this service
    local log_dir="$(dirname "$LOG_FILE")"
    local recent_logs=($(find "$log_dir" -name "health_check_*.log" -mtime -1 | sort -r | head -3))
    
    local failure_count=0
    for log_file in "${recent_logs[@]}"; do
        if grep -q "FAILED.*${service_name}" "$log_file" 2>/dev/null; then
            failure_count=$((failure_count + 1))
        fi
    done
    
    if [[ $failure_count -ge 2 ]]; then
        send_alert "Service Degradation" "${service_name} has failed ${failure_count} times in the last hour"
    fi
}

# Generate service uptime report
generate_uptime_report() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Service Uptime Report${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    local log_dir="$(dirname "$LOG_FILE")"
    local uptime_logs=($(find "$log_dir" -name "health_check_*.log" -mtime -30 | sort))
    
    if [[ ${#uptime_logs[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No uptime data available${NC}"
        return
    fi
    
    # Calculate uptime for each service
    for ip in "${!SHARED_SERVICES[@]}"; do
        IFS='|' read -r name port path description <<< "${SHARED_SERVICES[$ip]}"
        
        local total_checks=0
        local successful_checks=0
        
        for log_file in "${uptime_logs[@]}"; do
            if grep -q "OK.*${name}" "$log_file" 2>/dev/null; then
                successful_checks=$((successful_checks + 1))
                total_checks=$((total_checks + 1))
            elif grep -q "FAILED.*${name}" "$log_file" 2>/dev/null; then
                total_checks=$((total_checks + 1))
            fi
        done
        
        if [[ $total_checks -gt 0 ]]; then
            local uptime_percent=$(( (successful_checks * 100) / total_checks ))
            local status_color="${GREEN}"
            local status_icon="✅"
            
            if [[ $uptime_percent -lt 95 ]]; then
                status_color="${RED}"
                status_icon="❌"
            elif [[ $uptime_percent -lt 99 ]]; then
                status_color="${YELLOW}"
                status_icon="⚠️ "
            fi
            
            echo -e "${status_color}${status_icon} ${name}: ${uptime_percent}% uptime (${successful_checks}/${total_checks})${NC}"
        fi
    done
}

# Main execution
main() {
    local START_TIME=$(date +%s)
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -u|--users)
                CHECK_USERS=true
                shift
                ;;
            -t|--uptime)
                GENERATE_UPTIME=true
                shift
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
    
    # Handle uptime report mode
    if [[ "$GENERATE_UPTIME" == "true" ]]; then
        print_header
        generate_uptime_report
        exit 0
    fi
    
    # Initialize services
    init_services
    
    # Print header
    print_header
    
    # Run checks
    check_traefik
    check_shared_services
    check_user_containers
    
    # Generate summary
    generate_summary
    
    # Exit with appropriate code
    exit $EXIT_CODE
}

# Run main function with all arguments
main "$@"
