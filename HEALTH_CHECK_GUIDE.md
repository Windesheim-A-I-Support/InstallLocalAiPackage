# Service Health Check Script - User Guide

## Overview

The `service_health_check.sh` script is a comprehensive monitoring tool designed to check the health of all services in the Enterprise AI Infrastructure. It performs network connectivity tests, HTTP endpoint checks, and service availability verification across the entire infrastructure.

## Quick Start

### Basic Usage

```bash
# Quick check of shared services only
./service_health_check.sh

# Verbose output with detailed information
./service_health_check.sh -v

# Check all services including user containers
./service_health_check.sh -u

# Full verbose check of everything
./service_health_check.sh -v -u

# Show only failed services
./service_health_check.sh -q

# Show help
./service_health_check.sh -h
```

### Prerequisites

- **Bash 4.0+** (for associative arrays)
- **curl** (for HTTP checks)
- **ping** (for network connectivity)
- **timeout** command (for connection timeouts)
- **Docker** (for container checks)
- **Proxmox VE** with `pct` command (for user container checks)

## Architecture Overview

The script checks services across three main categories:

### 1. Shared Services (36+ services)
- **Core Infrastructure**: Ollama, Qdrant, PostgreSQL, Redis, MinIO
- **AI/ML Services**: Tika, Docling, Whisper, LibreTranslate, MCPO
- **DevOps & Development**: Gitea, Prometheus, Grafana, Loki, BookStack
- **Communication & Business**: Mailcow, Matrix, Authentik, Superset
- **Image Generation & A/V**: ComfyUI, AUTOMATIC1111, faster-whisper

### 2. User Containers (50 containers)
- **Range**: 10.0.5.200-249
- **Services per user**: Open WebUI, n8n, Jupyter, code-server, etc.
- **Resource per container**: 8-16GB RAM, 100-200GB disk

### 3. Infrastructure Components
- **Traefik**: Reverse proxy at 10.0.4.10
- **Legacy services**: Nextcloud, Supabase

## Command Line Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-v` | `--verbose` | Show detailed output with descriptions |
| `-q` | `--quiet` | Show only failed services |
| `-u` | `--users` | Check per-user containers (slower) |
| `-h` | `--help` | Show help message |

## Output Format

### Standard Output
```
========================================
  Enterprise AI Infrastructure
  Service Health Check Report
========================================
Generated: 2025-12-27 22:58:20
Log file: health_check_20251227_225820.log

Checking Traefik Reverse Proxy...
✅ Traefik (10.0.4.10:8080) - Healthy

Checking Shared Services...
✅ Ollama (10.0.5.100:11434) - Healthy
✅ Qdrant (10.0.5.101:6333) - Healthy
❌ PostgreSQL (10.0.5.102:5432) - Port closed
...

Shared Services Summary:
  Total: 36
  Healthy: 35
  Failed: 1
  Failed Services:
    - PostgreSQL (10.0.5.102:5432)

Checking User Containers...
✅ User Container 200 (10.0.5.200) - Docker running
❌ User Container 201 (10.0.5.201) - Network unreachable
...

User Containers Summary:
  Total: 50
  Healthy: 49
  Failed: 1
  Failed Containers:
    - User Container 201 (10.0.5.201)

========================================
  Health Check Summary
========================================
⚠️  Some services are experiencing issues

Quick Stats:
  Log file: health_check_20251227_225820.log
  Duration: 45 seconds
  Exit code: 1

Next Steps:
  • Review failed services above
  • Check detailed logs in health_check_20251227_225820.log
  • Restart failed services if needed
  • Run with -v flag for more details
```

### Color Coding
- 🟢 **Green**: Service is healthy
- 🔴 **Red**: Service is down or unreachable
- 🟡 **Yellow**: Section headers and warnings
- 🔵 **Blue**: Informational text and descriptions

## Health Check Types

### 1. Network Connectivity
- **Method**: ICMP ping
- **Timeout**: 5 seconds
- **Purpose**: Verify basic network reachability

### 2. HTTP Service Checks
- **Method**: HTTP GET request
- **Timeout**: 10 seconds
- **Purpose**: Verify service is responding correctly
- **Examples**:
  - Ollama: `http://10.0.5.100:11434/api/tags`
  - Qdrant: `http://10.0.5.101:6333/healthz`
  - Langfuse: `http://10.0.5.106:3002/api/public/health`

### 3. TCP Port Checks
- **Method**: TCP connection attempt
- **Timeout**: 5 seconds
- **Purpose**: Verify service is listening on expected port
- **Examples**:
  - PostgreSQL: Port 5432
  - Redis: Port 6379
  - Mailcow: Port 443

### 4. Docker Container Checks
- **Method**: `docker info` command
- **Purpose**: Verify Docker is running inside user containers
- **Location**: Inside each user container (10.0.5.200-249)

### 5. User Container Service Checks (Verbose Mode)
- **Method**: HTTP requests to localhost ports
- **Services checked**:
  - Open WebUI: Port 8080
  - n8n: Port 5678
  - Jupyter: Port 8888

## Service Categories

### Core Infrastructure (Priority 1)
| Service | IP | Port | Check Type | Purpose |
|---------|-----|------|------------|---------|
| Ollama | 10.0.5.100 | 11434 | HTTP | LLM inference |
| Qdrant | 10.0.5.101 | 6333 | HTTP | Vector database |
| PostgreSQL | 10.0.5.102 | 5432 | TCP | Relational database |
| Redis | 10.0.5.103 | 6379 | TCP | Cache & sessions |
| MinIO | 10.0.5.104 | 9000 | HTTP | Object storage |

### AI/ML Services (Priority 2)
| Service | IP | Port | Check Type | Purpose |
|---------|-----|------|------------|---------|
| Tika | 10.0.5.111 | 9998 | HTTP | Document extraction |
| Docling | 10.0.5.112 | 5001 | HTTP | Document parsing |
| Whisper | 10.0.5.113 | 9000 | HTTP | Speech-to-text |
| LibreTranslate | 10.0.5.114 | 5000 | HTTP | Translation API |
| MCPO | 10.0.5.115 | 8765 | HTTP | MCP proxy |

### DevOps & Development (Priority 3)
| Service | IP | Port | Check Type | Purpose |
|---------|-----|------|------------|---------|
| Gitea | 10.0.5.120 | 3003 | HTTP | Git server |
| Prometheus | 10.0.5.121 | 9090 | HTTP | Metrics collection |
| Grafana | 10.0.5.122 | 3004 | HTTP | Dashboards |
| Loki | 10.0.5.123 | 3100 | HTTP | Log aggregation |
| BookStack | 10.0.5.124 | 3005 | HTTP | Documentation |

### Communication & Business (Priority 4)
| Service | IP | Port | Check Type | Purpose |
|---------|-----|------|------------|---------|
| Mailcow | 10.0.5.140 | 443 | TCP | Mail server |
| Matrix | 10.0.5.142 | 8008 | HTTP | Chat server |
| Authentik | 10.0.5.146 | 9000 | HTTP | SSO provider |
| Superset | 10.0.5.144 | 3011 | HTTP | Business intelligence |

### Image Generation & A/V (Priority 5)
| Service | IP | Port | Check Type | Purpose |
|---------|-----|------|------------|---------|
| ComfyUI | 10.0.5.160 | 8188 | HTTP | Image generation |
| AUTOMATIC1111 | 10.0.5.161 | 7860 | HTTP | Stable Diffusion |
| faster-whisper | 10.0.5.162 | 8000 | HTTP | Optimized STT |
| openedai-speech | 10.0.5.163 | 8001 | HTTP | Text-to-speech |

## Troubleshooting

### Common Issues

#### 1. Network Unreachable
```
❌ Ollama (10.0.5.100) - Network unreachable
```
**Solutions**:
- Check network connectivity to the container
- Verify container is running: `pct status 100`
- Check firewall rules
- Verify IP address is correct

#### 2. Service Down
```
❌ Ollama (10.0.5.100:11434) - Service down
```
**Solutions**:
- Check if service is running: `docker ps` (inside container)
- Check service logs: `docker logs <container_name>`
- Verify service configuration
- Restart the service

#### 3. Port Closed
```
❌ PostgreSQL (10.0.5.102:5432) - Port closed
```
**Solutions**:
- Check if PostgreSQL is running
- Verify PostgreSQL is listening on the correct port
- Check firewall rules
- Verify PostgreSQL configuration

#### 4. Docker Not Running
```
❌ User Container 200 (10.0.5.200) - Docker not running
```
**Solutions**:
- Start Docker: `pct exec 200 -- systemctl start docker`
- Check Docker status: `pct exec 200 -- systemctl status docker`
- Verify Docker installation

### Debug Mode

For detailed debugging, run with verbose mode:
```bash
./service_health_check.sh -v
```

This will show:
- Service descriptions
- Expected endpoints
- Detailed check results

### Log Analysis

The script generates detailed logs:
```bash
# View the latest log
tail -f health_check_$(date +%Y%m%d_%H%M%S).log

# Search for specific issues
grep "FAILED" health_check_*.log

# Check overall status
grep "Overall status" health_check_*.log
```

## Automation

### Cron Job Setup

To run health checks automatically:

```bash
# Edit crontab
crontab -e

# Add entries for different check frequencies
# Every 5 minutes: Quick shared services check
*/5 * * * * /path/to/service_health_check.sh -q >> /var/log/health_check.log 2>&1

# Every hour: Full check with users
0 * * * * /path/to/service_health_check.sh -u >> /var/log/health_check.log 2>&1

# Daily at 6 AM: Full verbose check
0 6 * * * /path/to/service_health_check.sh -v -u >> /var/log/health_check.log 2>&1
```

### Integration with Monitoring

The script returns appropriate exit codes:
- **0**: All services healthy
- **1**: Some services failed

This can be used with monitoring systems:
```bash
# Nagios/Icinga check
define command{
    command_name    check_ai_infrastructure
    command_line    /path/to/service_health_check.sh -q
}

# Prometheus alerting (via node_exporter textfile collector)
./service_health_check.sh -q > /var/lib/node_exporter/textfile_collector/ai_infrastructure.prom
```

## Performance Considerations

### Check Duration
- **Shared services only**: ~30-60 seconds
- **With user containers**: ~2-5 minutes
- **Verbose mode**: Additional 10-30 seconds

### Resource Usage
- **CPU**: Minimal (network I/O bound)
- **Memory**: <50MB
- **Network**: ~100-500 HTTP requests per run

### Optimization Tips
- Use `-q` flag for faster checks
- Skip user containers with default mode
- Run during off-peak hours for full checks
- Consider parallel checks for large deployments

## Security Considerations

### Network Access
- Script requires access to all service IPs
- Ensure proper network segmentation
- Use VPN or internal networks only

### Credentials
- No credentials required for basic health checks
- HTTP checks use public endpoints
- Docker checks require Proxmox access

### Logging
- Logs contain service status information
- Store logs securely
- Consider log rotation policies

## Customization

### Adding New Services

To add a new shared service, modify the `init_services()` function:

```bash
# Add to SHARED_SERVICES array
SHARED_SERVICES["10.0.5.180"]="NewService|8080|/health|New Service Description"
```

### Modifying Check Parameters

Adjust timeouts and other parameters:
```bash
# Network timeout (default: 5 seconds)
check_network "$ip" 10

# HTTP timeout (default: 10 seconds)  
check_http_service "$ip" "$port" "$path" "$name" 15

# TCP timeout (default: 5 seconds)
check_tcp_port "$ip" "$port" 10
```

### Custom Health Check Endpoints

For services requiring authentication or custom checks:
```bash
# Custom HTTP check with headers
curl -s -H "Authorization: Bearer $TOKEN" "http://$ip:$port/api/health"
```

## Support

### Getting Help
- Check this documentation first
- Review generated logs for details
- Use verbose mode for debugging
- Verify network connectivity

### Reporting Issues
When reporting issues, include:
- Script version and options used
- Generated log file
- Network connectivity status
- Service-specific error messages

### Contributing
To contribute improvements:
1. Fork the repository
2. Test changes thoroughly
3. Update documentation
4. Submit pull request

---

**Last Updated**: December 27, 2025
**Version**: 1.0
**Compatibility**: Bash 4.0+, Linux systems with Docker and Proxmox VE
