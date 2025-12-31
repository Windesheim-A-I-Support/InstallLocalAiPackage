#!/bin/bash

# Enterprise AI Infrastructure - Monitoring Integration Script
# 
# Leverages existing Prometheus, Grafana, and Loki monitoring stack
# to provide real-time service status and health checks
#
# Usage: ./monitoring_integration.sh [OPTIONS]
# Options:
#   -s, --status      Show current service status from Prometheus
#   -g, --grafana     Show Grafana dashboard URLs and status
#   -l, --logs        Show recent logs from Loki
#   -a, --alerts      Show active alerts from Prometheus
#   -h, --help        Show help message

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITORING_IP="10.0.5.121"  # Prometheus IP
GRAFANA_IP="10.0.5.122"     # Grafana IP  
LOKI_IP="10.0.5.123"        # Loki IP

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print usage
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -s, --status      Show current service status from Prometheus"
    echo "  -g, --grafana     Show Grafana dashboard URLs and status"
    echo "  -l, --logs        Show recent logs from Loki"
    echo "  -a, --alerts      Show active alerts from Prometheus"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -s                 # Check service status"
    echo "  $0 -g                 # Show Grafana dashboards"
    echo "  $0 -l -s 100          # Show last 100 log lines"
    echo "  $0 -a                 # Show active alerts"
}

# Check if monitoring services are accessible
check_monitoring_services() {
    echo -e "${BLUE}=== Checking Monitoring Infrastructure ===${NC}"
    
    # Check Prometheus
    if curl -s --connect-timeout 5 "http://${MONITORING_IP}:9090/-/healthy" &>/dev/null; then
        echo -e "${GREEN}✅ Prometheus (${MONITORING_IP}:9090) - Healthy${NC}"
        PROMETHEUS_UP=true
    else
        echo -e "${RED}❌ Prometheus (${MONITORING_IP}:9090) - Down${NC}"
        PROMETHEUS_UP=false
    fi
    
    # Check Grafana
    if curl -s --connect-timeout 5 "http://${GRAFANA_IP}:3004/api/health" &>/dev/null; then
        echo -e "${GREEN}✅ Grafana (${GRAFANA_IP}:3004) - Healthy${NC}"
        GRAFANA_UP=true
    else
        echo -e "${RED}❌ Grafana (${GRAFANA_IP}:3004) - Down${NC}"
        GRAFANA_UP=false
    fi
    
    # Check Loki
    if curl -s --connect-timeout 5 "http://${LOKI_IP}:3100/ready" &>/dev/null; then
        echo -e "${GREEN}✅ Loki (${LOKI_IP}:3100) - Healthy${NC}"
        LOKI_UP=true
    else
        echo -e "${RED}❌ Loki (${LOKI_IP}:3100) - Down${NC}"
        LOKI_UP=false
    fi
    
    echo ""
}

# Show service status from Prometheus
show_service_status() {
    if [[ "$PROMETHEUS_UP" != "true" ]]; then
        echo -e "${RED}❌ Prometheus is not accessible${NC}"
        return 1
    fi
    
    echo -e "${BLUE}=== Service Status from Prometheus ===${NC}"
    echo ""
    
    # Get up/down status for all services
    local targets_url="http://${MONITORING_IP}:9090/api/v1/targets"
    
    if command -v jq &>/dev/null; then
        # Use jq for pretty parsing if available
        echo "Service targets status:"
        curl -s "$targets_url" | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health)"' 2>/dev/null || echo "Failed to parse targets"
    else
        # Fallback to curl only
        echo "Prometheus targets (raw JSON):"
        curl -s "$targets_url" | head -20
    fi
    
    echo ""
    echo -e "${BLUE}Prometheus URL: http://${MONITORING_IP}:9090${NC}"
    echo -e "${BLUE}Grafana URL: http://${GRAFANA_IP}:3004 (admin/admin)${NC}"
    echo ""
}

# Show Grafana dashboards
show_grafana_dashboards() {
    if [[ "$GRAFANA_UP" != "true" ]]; then
        echo -e "${RED}❌ Grafana is not accessible${NC}"
        return 1
    fi
    
    echo -e "${BLUE}=== Grafana Dashboards ===${NC}"
    echo ""
    
    # Get dashboard list
    local dashboards_url="http://${GRAFANA_IP}:3004/api/search"
    
    if command -v jq &>/dev/null; then
        echo "Available dashboards:"
        curl -s -u admin:admin "$dashboards_url" | jq -r '.[] | "• \(.title) - \(.url)"' 2>/dev/null || echo "Failed to get dashboards"
    else
        echo "Grafana dashboards (raw JSON):"
        curl -s -u admin:admin "$dashboards_url" | head -20
    fi
    
    echo ""
    echo -e "${BLUE}Grafana URLs:${NC}"
    echo -e "  Main: http://${GRAFANA_IP}:3004"
    echo -e "  Dashboards: http://${GRAFANA_IP}:3004/dashboards"
    echo -e "  Data Sources: http://${GRAFANA_IP}:3004/datasources"
    echo ""
}

# Show logs from Loki
show_loki_logs() {
    if [[ "$LOKI_UP" != "true" ]]; then
        echo -e "${RED}❌ Loki is not accessible${NC}"
        return 1
    fi
    
    local lines="${LOG_LINES:-50}"
    
    echo -e "${BLUE}=== Recent Logs from Loki ===${NC}"
    echo ""
    
    # Query recent logs
    local query='{job=~".+"}'
    local loki_query_url="http://${LOKI_IP}:3100/loki/api/v1/query_range"
    
    # Get logs (last N lines)
    if command -v jq &>/dev/null; then
        echo "Recent log entries:"
        curl -s "${loki_query_url}?query=${query}&limit=${lines}" | \
            jq -r '.data.result[] | .stream.job + ": " + .values[-1][1]' 2>/dev/null | \
            head -20 || echo "Failed to get logs"
    else
        echo "Loki logs (raw JSON):"
        curl -s "${loki_query_url}?query=${query}&limit=${lines}" | head -30
    fi
    
    echo ""
    echo -e "${BLUE}Loki URLs:${NC}"
    echo -e "  Query: http://${LOKI_IP}:3100/loki/api/v1/query"
    echo -e "  Status: http://${LOKI_IP}:3100/ready"
    echo ""
}

# Show active alerts from Prometheus
show_prometheus_alerts() {
    if [[ "$PROMETHEUS_UP" != "true" ]]; then
        echo -e "${RED}❌ Prometheus is not accessible${NC}"
        return 1
    fi
    
    echo -e "${BLUE}=== Active Alerts from Prometheus ===${NC}"
    echo ""
    
    local alerts_url="http://${MONITORING_IP}:9090/api/v1/alerts"
    
    if command -v jq &>/dev/null; then
        echo "Active alerts:"
        curl -s "$alerts_url" | jq -r '.data.alerts[] | select(.state == "firing") | "\(.labels.alertname): \(.annotations.summary)"' 2>/dev/null || echo "No active alerts or failed to parse"
    else
        echo "Prometheus alerts (raw JSON):"
        curl -s "$alerts_url" | head -30
    fi
    
    echo ""
    echo -e "${BLUE}Alert Manager (if available): http://${MONITORING_IP}:9093${NC}"
    echo ""
}

# Show monitoring stack status summary
show_monitoring_summary() {
    echo -e "${BLUE}=== Monitoring Stack Summary ===${NC}"
    echo ""
    
    check_monitoring_services
    
    echo -e "${BLUE}=== Quick Links ===${NC}"
    echo -e "Prometheus:     http://${MONITORING_IP}:9090"
    echo -e "Grafana:        http://${GRAFANA_IP}:3004 (admin/admin)"
    echo -e "Loki:           http://${LOKI_IP}:3100"
    echo ""
    echo -e "${BLUE}=== Service Discovery ===${NC}"
    echo -e "All services should be automatically discovered by Prometheus"
    echo -e "Check /etc/prometheus/prometheus.yml for scrape configurations"
    echo ""
    echo -e "${BLUE}=== Usage Examples ===${NC}"
    echo -e "$0 -s    # Check service status"
    echo -e "$0 -g    # Show Grafana dashboards"
    echo -e "$0 -l    # Show recent logs"
    echo -e "$0 -a    # Show active alerts"
    echo ""
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--status)
                check_monitoring_services
                show_service_status
                shift
                ;;
            -g|--grafana)
                check_monitoring_services
                show_grafana_dashboards
                shift
                ;;
            -l|--logs)
                LOG_LINES="${2:-50}"
                check_monitoring_services
                show_loki_logs
                shift
                ;;
            -a|--alerts)
                check_monitoring_services
                show_prometheus_alerts
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
    
    # If no arguments provided, show summary
    if [[ $# -eq 0 ]]; then
        show_monitoring_summary
    fi
}

# Run main function with all arguments
main "$@"
