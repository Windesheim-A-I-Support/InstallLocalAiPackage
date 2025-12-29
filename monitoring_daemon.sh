#!/bin/bash

# Enterprise AI Infrastructure - Monitoring Daemon
# 
# This script runs as a background daemon to continuously monitor
# the health of all services and send alerts when issues are detected.
#
# Usage: ./monitoring_daemon.sh [start|stop|status|restart]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_PID_FILE="/tmp/ai_infrastructure_monitor.pid"
DAEMON_LOG_FILE="${SCRIPT_DIR}/monitoring_daemon_$(date +%Y%m%d).log"
HEALTH_CHECK_SCRIPT="${SCRIPT_DIR}/service_health_check.sh"
CHECK_INTERVAL=300  # 5 minutes
ALERT_COOLDOWN=1800  # 30 minutes
ALERT_EMAIL=""
ALERT_WEBHOOK_URL=""
ALERT_THRESHOLD=3  # Number of consecutive failures before alerting

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service state tracking
declare -A SERVICE_FAILURE_COUNTS
declare -A LAST_ALERT_TIMES

# Logging function
daemon_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$DAEMON_LOG_FILE"
}

# Send alert notification
send_alert() {
    local alert_type="$1"
    local message="$2"
    local service_name="$3"
    
    # Log the alert
    daemon_log "ALERT: ${alert_type} - ${message}"
    
    # Check cooldown period
    local current_time=$(date +%s)
    local last_alert=${LAST_ALERT_TIMES[$service_name]:-0}
    local time_diff=$((current_time - last_alert))
    
    if [[ $time_diff -lt $ALERT_COOLDOWN ]]; then
        daemon_log "Alert for ${service_name} is in cooldown period (${time_diff}s < ${ALERT_COOLDOWN}s)"
        return
    fi
    
    # Send email if configured
    if [[ -n "$ALERT_EMAIL" ]] && command -v mail &>/dev/null; then
        echo "${message}" | mail -s "AI Infrastructure Alert: ${alert_type}" "$ALERT_EMAIL"
        daemon_log "Email alert sent to: $ALERT_EMAIL"
    fi
    
    # Send webhook if configured
    if [[ -n "$ALERT_WEBHOOK_URL" ]]; then
        curl -s -X POST -H "Content-Type: application/json" \
            -d "{\"alert_type\":\"${alert_type}\",\"message\":\"${message}\",\"service\":\"${service_name}\",\"timestamp\":\"$(date -Iseconds)\"}" \
            "$ALERT_WEBHOOK_URL" &>/dev/null
        daemon_log "Webhook alert sent to: $ALERT_WEBHOOK_URL"
    fi
    
    # Update last alert time
    LAST_ALERT_TIMES[$service_name]=$current_time
}

# Check service health and track failures
check_service_health() {
    local service_name="$1"
    local ip="$2"
    local port="$3"
    local path="$4"
    
    # Run health check
    if [[ -n "$path" ]]; then
        if curl -s --connect-timeout 10 "http://${ip}:${port}${path}" >/dev/null 2>&1; then
            # Service is healthy
            if [[ ${SERVICE_FAILURE_COUNTS[$service_name]:-0} -gt 0 ]]; then
                daemon_log "✅ ${service_name} (${ip}:${port}) - Service recovered"
                send_alert "Service Recovery" "${service_name} has recovered and is now healthy" "$service_name"
            fi
            SERVICE_FAILURE_COUNTS[$service_name]=0
            return 0
        fi
    else
        if timeout 5 bash -c "</dev/tcp/${ip}/${port}" 2>/dev/null; then
            # Service is healthy
            if [[ ${SERVICE_FAILURE_COUNTS[$service_name]:-0} -gt 0 ]]; then
                daemon_log "✅ ${service_name} (${ip}:${port}) - Service recovered"
                send_alert "Service Recovery" "${service_name} has recovered and is now healthy" "$service_name"
            fi
            SERVICE_FAILURE_COUNTS[$service_name]=0
            return 0
        fi
    fi
    
    # Service is down
    local current_failures=${SERVICE_FAILURE_COUNTS[$service_name]:-0}
    current_failures=$((current_failures + 1))
    SERVICE_FAILURE_COUNTS[$service_name]=$current_failures
    
    daemon_log "❌ ${service_name} (${ip}:${port}) - Service down (failure #${current_failures})"
    
    # Send alert if threshold reached
    if [[ $current_failures -eq $ALERT_THRESHOLD ]]; then
        send_alert "Service Down" "${service_name} has been down for ${ALERT_THRESHOLD} consecutive checks" "$service_name"
    fi
    
    return 1
}

# Monitor shared services
monitor_shared_services() {
    # Core Infrastructure
    check_service_health "Ollama" "10.0.5.100" "11434" "/api/tags"
    check_service_health "Qdrant" "10.0.5.101" "6333" "/healthz"
    check_service_health "PostgreSQL" "10.0.5.102" "5432" ""
    check_service_health "Redis" "10.0.5.103" "6379" ""
    check_service_health "MinIO" "10.0.5.104" "9000" "/minio/health/live"
    check_service_health "SearXNG" "10.0.5.105" "8080" "/"
    check_service_health "Langfuse" "10.0.5.106" "3002" "/api/public/health"
    check_service_health "Neo4j" "10.0.5.107" "7474" "/"
    
    # AI/ML Services
    check_service_health "Tika" "10.0.5.111" "9998" "/tika"
    check_service_health "Docling" "10.0.5.112" "5001" "/health"
    check_service_health "Whisper" "10.0.5.113" "9000" "/health"
    check_service_health "LibreTranslate" "10.0.5.114" "5000" "/languages"
    check_service_health "MCPO" "10.0.5.115" "8765" "/health"
    
    # DevOps & Development
    check_service_health "Gitea" "10.0.5.120" "3003" "/"
    check_service_health "Prometheus" "10.0.5.121" "9090" "/-/healthy"
    check_service_health "Grafana" "10.0.5.122" "3004" "/api/health"
    check_service_health "Loki" "10.0.5.123" "3100" "/ready"
    check_service_health "BookStack" "10.0.5.124" "3005" "/"
    check_service_health "Metabase" "10.0.5.125" "3006" "/api/health"
    check_service_health "Playwright" "10.0.5.126" "3007" "/health"
    check_service_health "Portainer" "10.0.5.128" "9443" "/api/status"
    check_service_health "Formbricks" "10.0.5.129" "3008" "/"
    
    # Communication & Business
    check_service_health "Mailcow" "10.0.5.140" "443" ""
    check_service_health "EspoCRM" "10.0.5.141" "3009" "/"
    check_service_health "Matrix" "10.0.5.142" "8008" "/_matrix/client/versions"
    check_service_health "Element" "10.0.5.143" "3010" "/"
    check_service_health "Superset" "10.0.5.144" "3011" "/health"
    check_service_health "DuckDB" "10.0.5.145" "8089" "/health"
    check_service_health "Authentik" "10.0.5.146" "9000" "/-/health/live"
    
    # Image Generation & A/V
    check_service_health "ComfyUI" "10.0.5.160" "8188" "/"
    check_service_health "AUTOMATIC1111" "10.0.5.161" "7860" "/"
    check_service_health "faster-whisper" "10.0.5.162" "8000" "/v1/models"
    check_service_health "openedai-speech" "10.0.5.163" "8001" "/v1/models"
    
    # Legacy services
    check_service_health "Nextcloud" "10.0.5.26" "443" ""
    check_service_health "Supabase" "10.0.5.27" "8000" "/health"
    
    # Traefik reverse proxy
    check_service_health "Traefik" "10.0.4.10" "8080" "/ping"
}

# Monitor user containers (basic connectivity check)
monitor_user_containers() {
    for i in {200..249}; do
        local ip="10.0.5.${i}"
        local container_name="User Container ${i}"
        
        # Check network connectivity
        if ! ping -c 1 -W 5 "$ip" &>/dev/null; then
            local current_failures=${SERVICE_FAILURE_COUNTS[$container_name]:-0}
            current_failures=$((current_failures + 1))
            SERVICE_FAILURE_COUNTS[$container_name]=$current_failures
            
            if [[ $current_failures -eq $ALERT_THRESHOLD ]]; then
                send_alert "Container Down" "${container_name} (${ip}) is not reachable" "$container_name"
            fi
        else
            # Container is reachable
            if [[ ${SERVICE_FAILURE_COUNTS[$container_name]:-0} -gt 0 ]]; then
                daemon_log "✅ ${container_name} (${ip}) - Container recovered"
                send_alert "Container Recovery" "${container_name} has recovered and is now reachable" "$container_name"
            fi
            SERVICE_FAILURE_COUNTS[$container_name]=0
        fi
    done
}

# Main monitoring loop
monitoring_loop() {
    daemon_log "Starting monitoring daemon (PID: $$)"
    
    while true; do
        daemon_log "Starting health check cycle"
        
        # Monitor shared services
        monitor_shared_services
        
        # Monitor user containers
        monitor_user_containers
        
        daemon_log "Health check cycle completed"
        
        # Sleep until next check
        sleep $CHECK_INTERVAL
    done
}

# Start the daemon
start_daemon() {
    if [[ -f "$DAEMON_PID_FILE" ]] && kill -0 "$(cat "$DAEMON_PID_FILE")" 2>/dev/null; then
        echo -e "${YELLOW}Monitoring daemon is already running (PID: $(cat "$DAEMON_PID_FILE"))${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Starting monitoring daemon...${NC}"
    
    # Start daemon in background
    monitoring_loop &
    local daemon_pid=$!
    
    # Save PID
    echo $daemon_pid > "$DAEMON_PID_FILE"
    
    echo -e "${GREEN}Monitoring daemon started (PID: $daemon_pid)${NC}"
    echo -e "${BLUE}Log file: $DAEMON_LOG_FILE${NC}"
}

# Stop the daemon
stop_daemon() {
    if [[ ! -f "$DAEMON_PID_FILE" ]]; then
        echo -e "${YELLOW}Monitoring daemon is not running${NC}"
        exit 1
    fi
    
    local daemon_pid=$(cat "$DAEMON_PID_FILE")
    
    if kill -0 "$daemon_pid" 2>/dev/null; then
        echo -e "${GREEN}Stopping monitoring daemon (PID: $daemon_pid)...${NC}"
        kill "$daemon_pid"
        
        # Wait for process to stop
        while kill -0 "$daemon_pid" 2>/dev/null; do
            sleep 1
        done
        
        rm -f "$DAEMON_PID_FILE"
        echo -e "${GREEN}Monitoring daemon stopped${NC}"
    else
        echo -e "${YELLOW}Monitoring daemon is not running${NC}"
        rm -f "$DAEMON_PID_FILE"
    fi
}

# Check daemon status
status_daemon() {
    if [[ -f "$DAEMON_PID_FILE" ]]; then
        local daemon_pid=$(cat "$DAEMON_PID_FILE")
        if kill -0 "$daemon_pid" 2>/dev/null; then
            echo -e "${GREEN}Monitoring daemon is running (PID: $daemon_pid)${NC}"
            echo -e "${BLUE}Log file: $DAEMON_LOG_FILE${NC}"
            
            # Show recent log entries
            echo -e "${BLUE}Recent log entries:${NC}"
            tail -5 "$DAEMON_LOG_FILE" 2>/dev/null || echo "No log entries found"
        else
            echo -e "${RED}Monitoring daemon PID file exists but process is not running${NC}"
            rm -f "$DAEMON_PID_FILE"
            exit 1
        fi
    else
        echo -e "${RED}Monitoring daemon is not running${NC}"
        exit 1
    fi
}

# Restart the daemon
restart_daemon() {
    echo -e "${YELLOW}Restarting monitoring daemon...${NC}"
    stop_daemon
    sleep 2
    start_daemon
}

# Show usage
show_usage() {
    echo "Usage: $0 {start|stop|status|restart}"
    echo ""
    echo "Commands:"
    echo "  start     Start the monitoring daemon"
    echo "  stop      Stop the monitoring daemon"
    echo "  status    Show daemon status and recent logs"
    echo "  restart   Restart the monitoring daemon"
    echo ""
    echo "Configuration:"
    echo "  Edit this script to configure:"
    echo "  - CHECK_INTERVAL: Health check interval (default: 300s)"
    echo "  - ALERT_COOLDOWN: Alert cooldown period (default: 1800s)"
    echo "  - ALERT_EMAIL: Email address for alerts"
    echo "  - ALERT_WEBHOOK_URL: Webhook URL for alerts"
    echo "  - ALERT_THRESHOLD: Consecutive failures before alerting (default: 3)"
}

# Load configuration from environment file if exists
if [[ -f "${SCRIPT_DIR}/.monitoring_config" ]]; then
    source "${SCRIPT_DIR}/.monitoring_config"
fi

# Main execution
case "${1:-}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    status)
        status_daemon
        ;;
    restart)
        restart_daemon
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
