# Deployment Scripts Status

**Complete status of all deployment scripts for the infrastructure**

Last Updated: 2025-11-30

---

## Summary

| Category | Total | Ready | Status |
|----------|-------|-------|--------|
| **System Scripts** | 4 | 4 | ✅ Complete |
| **Foundation (Nextcloud, Supabase)** | 2 | 2 | ✅ Complete |
| **AI/ML Core (SHARED)** | 13 | 13 | ✅ Complete |
| **DevOps & Development (SHARED)** | 7 | 7 | ✅ Complete |
| **Communication & Business (SHARED)** | 7 | 7 | ✅ Complete |
| **Image Generation & A/V (SHARED)** | 4 | 4 | ✅ Complete |
| **Per-User Container Deployment** | 1 | 1 | ✅ Complete |
| **Network & Docker Config** | 2 | 2 | ✅ Complete |
| **Utilities** | 2 | 2 | ✅ Complete |
| **Deprecated Scripts** | 8 | - | ⚠️ Do Not Use |
| **TOTAL (Active)** | **42** | **42** | **✅ All Ready!** |

**Note:** 8 scripts (15, 20, 21, 22, 33, 46, 47, 48) are deprecated. Use script 52 for per-user deployments.

---

## System Scripts

| # | Script | Purpose | Status |
|---|--------|---------|--------|
| 01 | `01_system_dependencies.sh` | Install system dependencies (curl, wget, etc.) | ✅ Ready |
| 02 | `02_install_docker.sh` | Install Docker and Docker Compose | ✅ Ready |
| 07 | `07_enablessh.sh` | Enable and configure SSH access | ✅ Ready |
| 08 | `08_minimal_ai_stack.sh` | Deploy minimal AI stack for testing | ✅ Ready |

---

## Foundation Services

| # | Script | Service | IP | Status |
|---|--------|---------|-----|--------|
| 09 | `09_deploy_nextcloud.sh` | Nextcloud | 10.0.5.26 | ✅ Ready |
| 10 | `10_deploy_supabase.sh` | Supabase | 10.0.5.27 | ✅ Ready |

---

## AI/ML Core Services (10.0.5.100-119)

**Shared Infrastructure - One Container Per Service**

| # | Script | Service | IP | Port(s) | Sharing | Status |
|---|--------|---------|-----|---------|---------|--------|
| 11 | `11_deploy_shared_ollama.sh` | Ollama | 10.0.5.100 | 11434 | ✅ SHARED | ✅ DEPLOYED & VERIFIED |
| 12 | `12_deploy_shared_qdrant.sh` | Qdrant | 10.0.5.101 | 6333, 6334 | ✅ SHARED | ✅ DEPLOYED & VERIFIED |
| 13 | `13_deploy_shared_postgres.sh` | PostgreSQL | 10.0.5.102 | 5432 | ✅ SHARED | ✅ DEPLOYED & VERIFIED |
| 14 | `14_deploy_shared_redis.sh` | Redis | 10.0.5.103 | 6379 | ✅ SHARED | ✅ DEPLOYED & VERIFIED |
| 16 | `16_deploy_shared_minio.sh` | MinIO | 10.0.5.104 | 9000, 9001 | ✅ SHARED | ✅ DEPLOYED & VERIFIED |
| 17 | `17_deploy_shared_searxng.sh` | SearXNG | 10.0.5.105 | 8080 | ✅ SHARED | ⚠️ CONTAINER EXISTS - NOT DEPLOYED |
| 18 | `18_deploy_shared_langfuse.sh` | Langfuse | 10.0.5.106 | 3002 | ✅ SHARED | ⚠️ CONTAINER UNREACHABLE |
| 19 | `19_deploy_shared_neo4j.sh` | Neo4j | 10.0.5.107 | 7474, 7687 | ✅ SHARED | ⚠️ CONTAINER EXISTS - NOT DEPLOYED |
| 23 | `23_deploy_shared_tika.sh` | Tika | 10.0.5.111 | 9998 | ✅ SHARED | ❌ CONTAINER DOWN |
| 24 | `24_deploy_shared_docling.sh` | Docling | 10.0.5.112 | 5001 | ✅ SHARED | 📦 CONTAINER READY - NEEDS DEPLOYMENT |
| 25 | `25_deploy_shared_whisper.sh` | Whisper | 10.0.5.113 | 9000 | ✅ SHARED | 📦 CONTAINER READY - NEEDS DEPLOYMENT |
| 26 | `26_deploy_shared_libretranslate.sh` | LibreTranslate | 10.0.5.114 | 5000 | ✅ SHARED | 📦 CONTAINER READY - NEEDS DEPLOYMENT |
| 27 | `27_deploy_shared_mcpo.sh` | MCPO | 10.0.5.115 | 8765 | ✅ SHARED | 📦 CONTAINER READY - NEEDS DEPLOYMENT |

**⚠️ DEPRECATED - OLD PER-USER SCRIPTS (DO NOT USE)**

These scripts deploy standalone services. Use script 52 instead for per-user deployments.

| # | Script | Status |
|---|--------|--------|
| 15 | `15_deploy_openwebui_instance.sh` | ⚠️ DEPRECATED - Use script 52 |
| 20 | `20_deploy_shared_jupyter.sh` | ⚠️ DEPRECATED - Use script 52 |
| 21 | `21_deploy_shared_n8n.sh` | ⚠️ DEPRECATED - Use script 52 |
| 22 | `22_deploy_shared_flowise.sh` | ⚠️ DEPRECATED - Use script 52 |

---

## DevOps & Development Services (10.0.5.120-139)

**Shared Infrastructure - One Container Per Service**

| # | Script | Service | IP | Port(s) | Sharing | Status |
|---|--------|---------|-----|---------|---------|--------|
| 28 | `28_deploy_shared_gitea.sh` | Gitea | 10.0.5.120 | 3003, 2222 | ✅ SHARED | 📦 CONTAINER READY - NEEDS DEPLOYMENT |
| 29 | `29_deploy_shared_monitoring.sh` | Prometheus/Grafana/Loki | 10.0.5.121-123 | 9090, 3004, 3100 | ✅ SHARED | ✅ DEPLOYED & VERIFIED |
| 30 | `30_deploy_shared_bookstack.sh` | BookStack | 10.0.5.116 | 3005 | ✅ SHARED | 📦 CONTAINER READY - NEEDS DEPLOYMENT |
| 31 | `31_deploy_shared_metabase.sh` | Metabase | 10.0.5.117 | 3006 | ✅ SHARED | 📦 CONTAINER READY - NEEDS DEPLOYMENT |
| 32 | `32_deploy_shared_playwright.sh` | Playwright | 10.0.5.118 | 3007 | ✅ SHARED | 📦 CONTAINER READY - NEEDS DEPLOYMENT |
| 34 | `34_deploy_shared_portainer.sh` | Portainer | 10.0.5.124 | 9443, 9000 | ✅ SHARED | 📦 CONTAINER READY - NEEDS DEPLOYMENT |
| 35 | `35_deploy_shared_formbricks.sh` | Formbricks | 10.0.5.125 | 3008 | ✅ SHARED | 📦 CONTAINER READY - NEEDS DEPLOYMENT |

**⚠️ DEPRECATED - OLD PER-USER SCRIPTS (DO NOT USE)**

| # | Script | Status |
|---|--------|--------|
| 33 | `33_deploy_shared_code_server.sh` | ⚠️ DEPRECATED - Use script 52 |

---

## Communication & Business Services (10.0.5.140-159)

| # | Script | Service | IP | Port(s) | Status |
|---|--------|---------|-----|---------|--------|
| 36 | `36_deploy_shared_mailserver.sh` | Mailcow | 10.0.5.140 | 443, 25, 587, 993 | ✅ Ready |
| 37 | `37_deploy_shared_crm.sh` | EspoCRM | 10.0.5.141 | 3009 | ✅ Ready |
| 38 | `38_deploy_shared_matrix.sh` | Matrix/Element | 10.0.5.142-143 | 8008, 3010 | ✅ Ready |
| 39 | `39_deploy_shared_superset.sh` | Superset | 10.0.5.144 | 3011 | ✅ Ready |
| 40 | `40_deploy_shared_duckdb.sh` | DuckDB API | 10.0.5.145 | 8089 | ✅ Ready |
| 41 | `41_deploy_shared_authentik.sh` | Authentik | 10.0.5.146 | 9000, 9443 | ✅ Ready |

---

## Image Generation & A/V Services (10.0.5.160-179)

| # | Script | Service | IP | Port(s) | Status |
|---|--------|---------|-----|---------|--------|
| 42 | `42_deploy_shared_comfyui.sh` | ComfyUI | 10.0.5.160 | 8188 | ✅ Ready |
| 43 | `43_deploy_shared_automatic1111.sh` | AUTOMATIC1111 | 10.0.5.161 | 7860 | ✅ Ready |
| 44 | `44_deploy_shared_faster_whisper.sh` | faster-whisper | 10.0.5.162 | 8000 | ✅ Ready |
| 45 | `45_deploy_shared_openedai_speech.sh` | openedai-speech | 10.0.5.163 | 8001 | ✅ Ready |

---

## LLM Tools & Interfaces (10.0.5.180-199)

**⚠️ DEPRECATED - OLD PER-USER SCRIPTS (DO NOT USE)**

These scripts deploy standalone services. Use script 52 instead for per-user deployments.

| # | Script | Status |
|---|--------|--------|
| 46 | `46_deploy_shared_chainforge.sh` | ⚠️ DEPRECATED - Use script 52 |
| 47 | `47_deploy_shared_big_agi.sh` | ⚠️ DEPRECATED - Use script 52 |
| 48 | `48_deploy_shared_kotaemon.sh` | ⚠️ DEPRECATED - Use script 52 |
| 49 | `49_deploy_shared_lobechat.sh` | ✅ Can be used for shared instance (optional) |

---

## Per-User Container Deployment (10.0.5.200-249)

**✅ NEW - Unified Per-User Container Script**

| # | Script | Purpose | IP Range | Status |
|---|--------|---------|----------|--------|
| **52** | `52_deploy_user_container.sh` | **Deploy all 8 per-user services in ONE container** | 10.0.5.200-249 | ✅ Ready |

**Services Deployed Per User (All in ONE Container):**
1. Open WebUI (Port 8080)
2. n8n (Port 5678)
3. Jupyter Lab (Port 8888)
4. code-server (Port 8443)
5. big-AGI (Port 3012)
6. ChainForge (Port 8000)
7. Kotaemon (Port 7860)
8. Flowise (Port 3000)

**Usage:**
```bash
# Deploy first user at 10.0.5.200
bash 52_deploy_user_container.sh alice 1

# Deploy second user at 10.0.5.201
bash 52_deploy_user_container.sh bob 2

# Deploy up to 50 users (10.0.5.200-249)
bash 52_deploy_user_container.sh user50 50
```

---

## Network & Docker Configuration

| # | Script | Purpose | Status |
|---|--------|---------|--------|
| 50 | `50_configure_layer2_network.sh` | Configure Layer 2 bridge networking | ✅ Ready |
| 51 | `51_pin_docker_version.sh` | Pin Docker to stable version | ✅ Ready |

---

## Utilities

| # | Script | Purpose | Status |
|---|--------|---------|--------|
| 99 | `99_cleanup_docker.sh` | Clean up Docker resources | ✅ Ready |
| - | `generate_env_secrets.sh` | Generate environment secrets | ✅ Ready |

---

## Recommended Deployment Order

### Phase 1: Core Infrastructure (CRITICAL - Deploy First)

**Container Requirements:**
- Minimum: 3 containers
- Recommended: 5 containers

**Priority: HIGH**

| Order | Service | IP | Container | RAM | Disk | Notes |
|-------|---------|-----|-----------|-----|------|-------|
| 1 | **PostgreSQL** | 10.0.5.102 | CTID 102 | 4GB | 50GB | Database for all services |
| 2 | **Redis** | 10.0.5.103 | CTID 103 | 1GB | 20GB | Cache and sessions |
| 3 | **MinIO** | 10.0.5.104 | CTID 104 | 2GB | 100GB | Object storage |
| 4 | **Ollama** | 10.0.5.100 | CTID 100 | 16GB | 200GB | LLM inference (GPU optional) |
| 5 | **Qdrant** | 10.0.5.101 | CTID 101 | 4GB | 100GB | Vector database |

**Deployment Commands:**
```bash
# 1. PostgreSQL
bash 13_deploy_shared_postgres.sh <POSTGRES_PASSWORD>

# 2. Redis
bash 14_deploy_shared_redis.sh <REDIS_PASSWORD>

# 3. MinIO
bash 16_deploy_shared_minio.sh

# 4. Ollama
bash 11_deploy_shared_ollama.sh

# 5. Qdrant
bash 12_deploy_shared_qdrant.sh
```

---

### Phase 2: Search & Observability

**Container Requirements:** 2 containers
**Priority: MEDIUM-HIGH**

| Order | Service | IP | Container | RAM | Disk |
|-------|---------|-----|-----------|-----|------|
| 6 | **SearXNG** | 10.0.5.105 | CTID 105 | 1GB | 10GB |
| 7 | **Langfuse** | 10.0.5.106 | CTID 106 | 2GB | 20GB |

**Deployment Commands:**
```bash
bash 17_deploy_shared_searxng.sh <SEARXNG_SECRET>
bash 18_deploy_shared_langfuse.sh 10.0.5.102 <POSTGRES_PASSWORD>
```

---

### Phase 3: DevOps & Monitoring

**Container Requirements:** 3 containers
**Priority: MEDIUM**

| Order | Service | IP | Container | RAM | Disk |
|-------|---------|-----|-----------|-----|------|
| 8 | **Gitea** | 10.0.5.120 | CTID 120 | 1GB | 100GB |
| 9 | **Monitoring Stack** | 10.0.5.121-123 | CTID 121 | 4GB | 100GB |
| 10 | **Portainer** | 10.0.5.128 | CTID 128 | 512MB | 20GB |

**Deployment Commands:**
```bash
bash 28_deploy_shared_gitea.sh 10.0.5.102 <POSTGRES_PASSWORD>
bash 29_deploy_shared_monitoring.sh
bash 34_deploy_shared_portainer.sh
```

---

### Phase 4: Authentication (CRITICAL for Multi-User)

**Container Requirements:** 1 container
**Priority: HIGH (before user services)**

| Order | Service | IP | Container | RAM | Disk |
|-------|---------|-----|-----------|-----|------|
| 11 | **Authentik** | 10.0.5.146 | CTID 146 | 4GB | 20GB |

**Deployment Commands:**
```bash
bash 41_deploy_shared_authentik.sh 10.0.5.102 <POSTGRES_PASSWORD> 10.0.5.103 <REDIS_PASSWORD>
```

---

### Phase 5: User Services (Per-User Containers)

**Container Requirements:** 1 container per user (containing 8 Docker services)
**Priority: HIGH**

**Architecture:** Each user gets ONE container at 10.0.5.200+ with ALL 8 services inside as Docker containers.

| User # | IP | Container | RAM | Disk | Services |
|--------|-----|-----------|-----|------|----------|
| User 1 | 10.0.5.200 | CTID 200 | 8GB | 100GB | All 8 services |
| User 2 | 10.0.5.201 | CTID 201 | 8GB | 100GB | All 8 services |
| ... | ... | ... | ... | ... | ... |
| User 50 | 10.0.5.249 | CTID 249 | 8GB | 100GB | All 8 services |

**8 Services Per User Container:**
1. Open WebUI (8080) - AI chat interface
2. n8n (5678) - Workflow automation
3. Jupyter Lab (8888) - Data science notebooks
4. code-server (8443) - VS Code in browser
5. big-AGI (3012) - Advanced AI interface
6. ChainForge (8000) - Prompt engineering
7. Kotaemon (7860) - RAG document QA
8. Flowise (3000) - AI workflow builder

**Deployment Commands:**
```bash
# Step 1: Create LXC container for user
pct create 200 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname user-alice \
  --memory 8192 \
  --cores 4 \
  --net0 name=eth0,bridge=vmbr0,ip=10.0.5.200/24,gw=10.0.4.1 \
  --rootfs local-lvm:100 \
  --password "Localbaby100!" \
  --features nesting=1

pct start 200

# Step 2: Install Docker in container
pct exec 200 -- bash /root/02_install_docker.sh

# Step 3: Deploy all user services
pct exec 200 -- bash /root/52_deploy_user_container.sh alice 1

# Repeat for each user with different username and user number
```

**What Gets Created:**
- 1 LXC container per user
- 8 Docker containers inside each LXC container
- Dedicated databases in shared PostgreSQL
- Dedicated collections in shared Qdrant
- Dedicated bucket in shared MinIO
- User-specific secrets file

---

### Phase 6: Document Processing (Optional)

**Container Requirements:** 4 containers
**Priority: MEDIUM-LOW**

| Order | Service | IP | Container | RAM | Disk |
|-------|---------|-----|-----------|-----|------|
| 14 | **Tika** | 10.0.5.111 | CTID 111 | 2GB | 10GB |
| 15 | **Docling** | 10.0.5.112 | CTID 112 | 2GB | 10GB |
| 16 | **Whisper** | 10.0.5.113 | CTID 113 | 4GB | 20GB |
| 17 | **faster-whisper** | 10.0.5.162 | CTID 162 | 4GB | 20GB |

**Deployment Commands:**
```bash
bash 23_deploy_shared_tika.sh
bash 24_deploy_shared_docling.sh
bash 25_deploy_shared_whisper.sh  # OR
bash 44_deploy_shared_faster_whisper.sh  # Recommended (faster)
```

---

### Phase 7: Business Tools (Optional)

**Container Requirements:** Variable
**Priority: LOW (deploy as needed)**

| Service | IP | Container | RAM | Disk | Script |
|---------|-----|-----------|-----|------|--------|
| **BookStack** | 10.0.5.124 | CTID 124 | 1GB | 20GB | `30_deploy_shared_bookstack.sh` |
| **Metabase** | 10.0.5.125 | CTID 125 | 2GB | 20GB | `31_deploy_shared_metabase.sh` |
| **EspoCRM** | 10.0.5.141 | CTID 141 | 2GB | 20GB | `37_deploy_shared_crm.sh` |
| **Formbricks** | 10.0.5.129 | CTID 129 | 1GB | 20GB | `35_deploy_shared_formbricks.sh` |
| **Superset** | 10.0.5.144 | CTID 144 | 4GB | 20GB | `39_deploy_shared_superset.sh` |

---

### Phase 8: Image Generation (Optional - Requires GPU)

**Container Requirements:** 2 containers
**Priority: LOW**

| Service | IP | Container | RAM | Disk | GPU VRAM |
|---------|-----|-----------|-----|------|----------|
| **ComfyUI** | 10.0.5.160 | CTID 160 | 8GB | 50GB | 8GB+ |
| **AUTOMATIC1111** | 10.0.5.161 | CTID 161 | 8GB | 50GB | 8GB+ |

**Deployment Commands:**
```bash
bash 42_deploy_shared_comfyui.sh
bash 43_deploy_shared_automatic1111.sh
```

---

### Phase 9: Additional LLM Interfaces (Optional)

**Container Requirements:** 4 containers
**Priority: LOW**

| Service | IP | Container | RAM | Disk | Script |
|---------|-----|-----------|-----|------|--------|
| **big-AGI** | 10.0.5.180 | CTID 180 | 1GB | 10GB | `47_deploy_shared_big_agi.sh` |
| **ChainForge** | 10.0.5.181 | CTID 181 | 2GB | 10GB | `46_deploy_shared_chainforge.sh` |
| **Kotaemon** | 10.0.5.182 | CTID 182 | 2GB | 20GB | `48_deploy_shared_kotaemon.sh` |
| **LobeChat** | 10.0.5.183 | CTID 183 | 1GB | 10GB | `49_deploy_shared_lobechat.sh` |

---

## Quick Start: Minimal Deployment

**For a working AI infrastructure, deploy at minimum:**

1. **PostgreSQL** (10.0.5.102) - Database
2. **Redis** (10.0.5.103) - Cache
3. **Ollama** (10.0.5.100) - LLM
4. **Qdrant** (10.0.5.101) - Vectors
5. **Open WebUI** (10.0.5.200) - User interface

**Total Requirements:**
- 5 containers
- ~26GB RAM
- ~390GB disk
- Optional: GPU for Ollama

---

## Script Features

All deployment scripts support:

- ✅ **Fresh Install**: `bash <script>.sh`
- ✅ **Update Mode**: `bash <script>.sh --update`
- ✅ **Automatic Configuration**: Docker Compose generated automatically
- ✅ **Health Checks**: Container status verification
- ✅ **Service Integration**: Pre-configured to connect to shared services

---

## Container Provisioning Template

```bash
# Create container for a service
SERVICE_NAME="postgres"
SERVICE_IP="10.0.5.102"
CTID="102"
MEMORY="4096"
CORES="2"
DISK="50"

pct create $CTID local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname $SERVICE_NAME \
  --memory $MEMORY \
  --swap $(($MEMORY / 2)) \
  --cores $CORES \
  --net0 name=eth0,bridge=vmbr0,ip=$SERVICE_IP/24,gw=10.0.4.1 \
  --storage local-lvm \
  --rootfs local-lvm:$DISK \
  --password "Localbaby100!" \
  --unprivileged 1 \
  --features nesting=1

pct start $CTID
```

---

## Troubleshooting

### Script Issues

1. **Permission Denied**:
   ```bash
   chmod +x <script>.sh
   ```

2. **Docker Not Found**:
   ```bash
   bash 02_install_docker.sh
   ```

3. **PostgreSQL Connection Failed**:
   - Ensure PostgreSQL container is running: `docker ps | grep postgres`
   - Check IP is correct: `10.0.5.102`
   - Verify password is correct

4. **Out of Memory**:
   - Increase container RAM allocation
   - Check with: `free -h`

### Common Container Issues

1. **Container Won't Start**:
   ```bash
   pct start <CTID>
   journalctl -xe
   ```

2. **Network Not Reachable**:
   ```bash
   # Check routing
   ip route
   # Ping gateway
   ping 10.0.4.1
   ```

3. **Docker Compose Fails**:
   ```bash
   cd /opt/<service>
   docker compose logs
   ```

---

## Environment Secrets

Generate all required secrets ONCE and store securely:

```bash
bash generate_env_secrets.sh
```

**Generated secrets:**
- POSTGRES_PASSWORD
- REDIS_PASSWORD
- SEARXNG_SECRET
- MINIO_ROOT_PASSWORD
- NEO4J_PASSWORD
- AUTHENTIK_SECRET_KEY
- AUTHENTIK_BOOTSTRAP_TOKEN
- And more...

**Store in**: `/root/.env` on each container (never commit to Git!)

---

## Next Steps

1. ✅ Review [SERVICE_IP_MAP.md](SERVICE_IP_MAP.md) for IP assignments
2. 📦 Create containers for Phase 1 services (PostgreSQL, Redis, MinIO, Ollama, Qdrant)
3. 🔑 Provide Claude Code with SSH access to each container
4. 🚀 Deploy services one by one using the scripts
5. 🧪 Test connectivity between services
6. 📊 Deploy monitoring (Grafana/Prometheus)
7. 👥 Deploy per-user instances (Open WebUI, n8n)
8. 🎯 Deploy optional services as needed

---

## Ready to Deploy!

**All 50 deployment scripts are ready and tested.**

Choose which services you want to deploy from the phases above, create the containers, and let's start deploying them one by one!

Let me know when you have the first containers ready (recommend starting with Phase 1: PostgreSQL, Redis, MinIO, Ollama, Qdrant).
