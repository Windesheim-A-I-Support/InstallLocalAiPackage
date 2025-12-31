# Infrastructure Reference Guide

**Complete architecture, rules, and deployment information**

---

## 🔑 Quick Access Info

**Network:** 10.0.5.0/24
**Gateway:** 10.0.5.1
**SSH Access:** `ssh root@10.0.5.XXX` (where XXX = container ID)
**Credentials Location:** `/root/.credentials/SERVICE.txt` on each container
**Deployment Scripts:** `scripts/XX_deploy_shared_SERVICE_native.sh`

---

## 📋 Table of Contents

1. [Connection Info](#connection-info)
2. [Architecture Rules](#architecture-rules)
3. [Deployment Guidelines](#deployment-guidelines)
4. [Available Scripts](#available-scripts)
5. [Health Checks](#health-checks)
6. [Troubleshooting](#troubleshooting)

---

## 🔌 Connection Info

### Network Layout
- **Network:** 10.0.5.0/24
- **Gateway:** 10.0.5.1
- **DNS:** 1.1.1.1
- **Containers:** 100-199 (shared services), 200-249 (user services)

### SSH Access
```bash
# Access any container
ssh root@10.0.5.XXX

# Examples
ssh root@10.0.5.100  # Ollama
ssh root@10.0.5.127  # Elasticsearch (when created)
ssh root@10.0.5.200  # Pipelines
```

### Common Commands
```bash
# Check service status
ssh root@10.0.5.XXX "systemctl status SERVICE"

# View logs
ssh root@10.0.5.XXX "journalctl -u SERVICE -f"

# Get credentials
ssh root@10.0.5.XXX "cat /root/.credentials/SERVICE.txt"

# Quick health check
curl http://10.0.5.XXX:PORT
```

### Deployment from Host
```bash
# Run deployment scripts from the repo directory
cd /home/chris/Documents/github/InstallLocalAiPackage
bash scripts/XX_deploy_shared_SERVICE_native.sh
```

---

## ⚠️ Architecture Rules

### THE GOLDEN RULE: NO DOCKER ON SHARED SERVICES

**CRITICAL:** Shared services (containers 100-199) MUST be deployed natively!

```
❌ DO NOT USE DOCKER for shared services (100-199)
✅ ONLY user containers (200-249) can use Docker
```

### Why Native Deployments?

1. **Resource Efficiency** - Direct system access, no container overhead
2. **Security** - systemd hardening, no Docker daemon exposure
3. **Performance** - Native kernel access, no virtualization layer
4. **Maintainability** - System packages, standard Debian tools
5. **Reliability** - systemd management, automatic restarts

### Container Allocation

- **100-199:** Shared services (Native only)
- **200-249:** User containers (Docker allowed)
- **Special:** 136 (Chainforge - outside normal range)

---

## 🏗️ System Architecture

### Network Layout

```
Traefik Reverse Proxy (10.0.4.10)
    ↓
    ├─→ Shared Services (10.0.5.100-199)
    │   ├─→ Core Infrastructure (100-104)
    │   ├─→ AI/LLM Services (105-120)
    │   └─→ Monitoring (121-123)
    │
    └─→ User Containers (10.0.5.200-249)
        └─→ OpenWebUI, Pipelines, etc.
```

### Service Tiers

**Tier 1 - Core Infrastructure (Always Running)**
- PostgreSQL (102), Redis (103), MinIO (104)
- Qdrant (101), Neo4j (107)
- Ollama (100)

**Tier 2 - AI/LLM Services**
- Langfuse (106), Flowise (110), n8n (109)
- SearXNG (105), Docling (112), Whisper (113)
- LibreTranslate (114), Playwright (118)

**Tier 3 - Productivity & Tools**
- BookStack (116), Metabase (117)
- Gitea (120), JupyterLab (124)

**Tier 4 - Monitoring**
- Prometheus (121), Grafana (122), Loki (123)

---

## 🚀 Deployment Guidelines

### Standard Deployment Process

1. **Check Container Availability**
   ```bash
   cat docs/STATUS.md  # Check which IPs are free
   ```

2. **Find Deployment Script**
   ```bash
   ls scripts/*deploy*SERVICE*
   ```

3. **Run Deployment**
   ```bash
   bash scripts/XX_deploy_shared_SERVICE_native.sh
   ```

4. **Verify Service**
   ```bash
   curl http://10.0.5.XXX:PORT
   ssh root@10.0.5.XXX "systemctl status SERVICE"
   ```

5. **Update Documentation**
   - Edit `docs/STATUS.md` - Mark service as working
   - Edit `docs/CREDENTIALS.md` - Add login info (or copy from `/root/.credentials/`)

### Deployment Script Standards

All deployment scripts must:
- Install via system packages (apt, pip, npm)
- Create dedicated system user
- Use systemd for service management
- Store credentials in `/root/.credentials/SERVICE.txt`
- Implement health checks
- Support `--update` flag for upgrades

### Example Native Deployment

```bash
# Install dependencies
apt-get install -y python3 python3-pip python3-venv

# Create service user
useradd -r -s /bin/bash -d /opt/SERVICE -m SERVICE

# Install in virtual environment
su -s /bin/bash -c "python3 -m venv /opt/SERVICE/venv" SERVICE
su -s /bin/bash -c "/opt/SERVICE/venv/bin/pip install SERVICE" SERVICE

# Create systemd service
cat > /etc/systemd/system/SERVICE.service << EOF
[Unit]
Description=SERVICE
After=network.target

[Service]
Type=simple
User=SERVICE
WorkingDirectory=/opt/SERVICE
ExecStart=/opt/SERVICE/venv/bin/SERVICE --host 0.0.0.0 --port PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start service
systemctl daemon-reload
systemctl enable SERVICE
systemctl start SERVICE
```

---

## 📜 Available Deployment Scripts

### Core Services
```bash
scripts/01_system_dependencies.sh          # Install base system packages
scripts/07_enablessh.sh                    # Enable SSH access
```

### AI/LLM Services
```bash
scripts/17_deploy_shared_searxng_native.sh    # SearXNG → 105:8080
scripts/18_deploy_shared_langfuse_native.sh   # Langfuse → 106:3000
scripts/22_deploy_shared_flowise_native.sh    # Flowise → 110:3000
scripts/23_deploy_shared_n8n_native.sh        # n8n → 109:5678
scripts/24_deploy_shared_docling_native.sh    # Docling → 112:5001
scripts/25_deploy_shared_libretranslate_native.sh  # LibreTranslate → 114:5000
scripts/26_deploy_shared_whisper_native.sh    # Whisper → 113:9000
scripts/27_deploy_shared_playwright_native.sh # Playwright → 118:3000
```

### Data & Productivity
```bash
scripts/32_deploy_shared_gitea.sh             # Gitea → 120:3000
scripts/33_deploy_shared_bookstack_native.sh  # BookStack → 116:3200
scripts/34_deploy_shared_tika.sh              # Tika → 111:9998
scripts/35_deploy_shared_metabase_native.sh   # Metabase → 117:3001
scripts/38_deploy_shared_jupyter_native.sh    # JupyterLab → 124:8888
```

### New Services (Create Containers First)
```bash
scripts/40_deploy_shared_elasticsearch_native.sh   # → 127:9200
scripts/39_deploy_shared_litellm_native.sh         # → 128:4000
scripts/41_deploy_shared_unstructured_native.sh    # → 129:8000
scripts/43_deploy_shared_superset_native.sh        # → 130:8088
scripts/42_deploy_shared_haystack_native.sh        # → 131:8000
scripts/44_deploy_shared_langgraph_native.sh       # → 132:8000
scripts/45_deploy_shared_graphrag_native.sh        # → 133:8000
scripts/46_deploy_shared_plaso_native.sh           # → 135:5000
scripts/47_deploy_shared_volatility3_native.sh     # → 138:8080
```

### Update Existing Services
```bash
# Most scripts support --update flag
bash scripts/XX_deploy_shared_SERVICE_native.sh --update
```

---

## 🔍 Health Checks

### Quick Status Check

```bash
# Check all working services
for ip in 100 101 104 105 107 109 112 113 114 116 117 118 121 122 123; do
  echo -n "10.0.5.$ip: "
  timeout 2 curl -s http://10.0.5.$ip 2>&1 | head -1
done
```

### Individual Service Checks

```bash
# HTTP endpoint
curl http://10.0.5.XXX:PORT

# systemd status
ssh root@10.0.5.XXX "systemctl status SERVICE"

# Service logs
ssh root@10.0.5.XXX "journalctl -u SERVICE -f"

# Process check
ssh root@10.0.5.XXX "ps aux | grep SERVICE"
```

### Monitoring Scripts

```bash
scripts/service_health_check.sh      # Comprehensive health check
scripts/service_verification.sh      # Verify all services
scripts/monitoring_daemon.sh         # Continuous monitoring
```

---

## 🔧 Troubleshooting

### Service Won't Start

1. **Check logs**
   ```bash
   ssh root@10.0.5.XXX "journalctl -u SERVICE -n 50"
   ```

2. **Check systemd status**
   ```bash
   ssh root@10.0.5.XXX "systemctl status SERVICE"
   ```

3. **Check port availability**
   ```bash
   ssh root@10.0.5.XXX "netstat -tlnp | grep PORT"
   ```

4. **Restart service**
   ```bash
   ssh root@10.0.5.XXX "systemctl restart SERVICE"
   ```

### Port Conflicts

If a service won't bind to its port:
```bash
# Find what's using the port
ssh root@10.0.5.XXX "lsof -i :PORT"

# Kill the process if needed
ssh root@10.0.5.XXX "systemctl stop CONFLICTING_SERVICE"
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
ssh root@10.0.5.102 "sudo -u postgres psql -c '\l'"

# Test Redis connection
ssh root@10.0.5.103 "redis-cli ping"

# Test Neo4j connection
curl http://10.0.5.107:7474
```

### Service Credentials

All service credentials are stored in:
```bash
# On each container
/root/.credentials/SERVICE.txt

# Also documented in
docs/CREDENTIALS.md
```

### Common Issues

**pnpm/npm install hanging**
- Normal for large packages (Langfuse, Flowise)
- Check with: `ps aux | grep npm`
- Wait 30-60 minutes

**Python module not found**
- Use `--no-build-isolation` flag
- Install dependencies first

**Apache/Nginx port issues**
- Check both VirtualHost AND ports.conf
- Restart service after changes

**PostgreSQL database doesn't exist**
- Create manually: `su - postgres -c "createdb DATABASE"`

---

## 📚 Additional Resources

### Official Documentation
- BookStack: https://www.bookstackapp.com/docs/
- Langfuse: https://langfuse.com/docs
- Flowise: https://docs.flowiseai.com/
- n8n: https://docs.n8n.io/
- Metabase: https://www.metabase.com/docs/

### Traefik Routing
- Server: 10.0.4.10
- Config: `/opt/traefik-stack/dynamic/`
- File naming: `205{last_octet}.yml`
- Example: 10.0.5.100 → `205100.yml`

### Authentication
Each service has individual auth (no SSO yet):
- Credentials in `/root/.credentials/SERVICE.txt`
- Or see `docs/CREDENTIALS.md`

---

**Last Updated:** 2025-12-31
**See Also:** [STATUS.md](STATUS.md) for current service status
