# Enterprise AI Infrastructure - Architecture Overview

**High-level architecture design for multi-user AI infrastructure**

> For detailed IP assignments, environment variables, and health checks, see [SERVICE_IP_MAP.md](SERVICE_IP_MAP.md)

---

## Design Principle

**Maximize resource sharing while maintaining user isolation where necessary**

---

## Architecture Pattern

```
┌────────────────────────────────────────────────────────────────┐
│                  SHARED INFRASTRUCTURE LAYER                    │
│                   (ONE Container Per Service)                   │
│                                                                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │ Ollama   │ │ Qdrant   │ │PostgreSQL│ │  Redis   │  ...     │
│  │10.0.5.100│ │10.0.5.101│ │10.0.5.102│ │10.0.5.103│          │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│                                                                 │
│  Each service in dedicated LXC container (CTID matches last    │
│  octet of IP: 100, 101, 102, etc.)                            │
└────────────────────────────────────────────────────────────────┘
                            ▲
                            │ All users connect here
                            │ via shared backend
                            │
┌───────────────────────────┼────────────────────────────────────┐
│                           │                                    │
│                           │                                    │
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ User 1 Container │  │ User 2 Container │  │ User 3 Container │
│  (10.0.5.200)    │  │  (10.0.5.201)    │  │  (10.0.5.202)    │
│  CTID 200        │  │  CTID 201        │  │  CTID 202        │
│                  │  │                  │  │                  │
│ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────────┐ │
│ │ openwebui-u1 │ │  │ │ openwebui-u2 │ │  │ │ openwebui-u3 │ │
│ │ n8n-u1       │ │  │ │ n8n-u2       │ │  │ │ n8n-u3       │ │
│ │ jupyter-u1   │ │  │ │ jupyter-u2   │ │  │ │ jupyter-u3   │ │
│ │ code-u1      │ │  │ │ code-u2      │ │  │ │ code-u3      │ │
│ │ big-agi-u1   │ │  │ │ big-agi-u2   │ │  │ │ big-agi-u3   │ │
│ │ kotaemon-u1  │ │  │ │ kotaemon-u2  │ │  │ │ kotaemon-u3  │ │
│ │ chainforge-u1│ │  │ │ chainforge-u2│ │  │ │ chainforge-u3│ │
│ │ flowise-u1   │ │  │ │ flowise-u2   │ │  │ │ flowise-u3   │ │
│ └──────────────┘ │  │ └──────────────┘ │  │ └──────────────┘ │
│  (8 Docker       │  │  (8 Docker       │  │  (8 Docker       │
│   containers)    │  │   containers)    │  │   containers)    │
└──────────────────┘  └──────────────────┘  └──────────────────┘

            ... continues to User 50 (10.0.5.249) ...
```

---

## Key Architecture Decisions

### 1. Shared Services (10.0.5.100-199)

**One LXC container per service, shared by ALL users**

#### Why This Pattern?

- **Resource Efficiency**: Avoid duplicating large models (Ollama), databases (PostgreSQL), etc.
- **Central Management**: Single point of backup, updates, monitoring
- **Cost-Effective**: Share expensive resources (GPU, storage, RAM)
- **Multi-Tenancy Built-In**: Services like PostgreSQL, Redis, Qdrant support multi-user natively

#### Isolation Strategy

| Service | Isolation Method | Example |
|---------|------------------|---------|
| PostgreSQL | Database-level | `openwebui_user1`, `openwebui_user2` |
| Redis | DB number (0-15) | User1=DB2, User2=DB3 |
| Qdrant | Collection-level | `user1_docs`, `user2_docs` |
| MinIO | Bucket-level + IAM | `user1-openwebui`, `user2-openwebui` |
| Ollama | No isolation needed | All users share models |

#### Service Categories

**Core Infrastructure (15 services):**
- Ollama, Qdrant, PostgreSQL, Redis, MinIO
- SearXNG, Langfuse, Neo4j
- Tika, Docling, Whisper, faster-whisper, openedai-speech
- LibreTranslate, MCPO

**DevOps & Development (10 services):**
- Gitea, Prometheus, Grafana, Loki
- BookStack, Metabase, Playwright
- Portainer, Formbricks

**Communication & Business (7 services):**
- Mailcow, EspoCRM, Matrix, Element
- Superset, DuckDB, Authentik

**Image Generation & A/V (4 services):**
- ComfyUI, AUTOMATIC1111
- faster-whisper, openedai-speech

**Total: ~36 shared services**

---

### 2. Per-User Services (10.0.5.200-249)

**One LXC container per user, containing multiple Docker containers**

#### Why This Pattern?

- **Manageable Scale**: 50 LXC containers instead of 400+ containers
- **User Isolation**: Each user's services in their own container
- **Easy Provisioning**: Clone template, assign IP, deploy services
- **Resource Control**: Set RAM/CPU limits per user

#### Services That CANNOT Be Shared

| Service | Reason | License/Technical |
|---------|--------|-------------------|
| **Open WebUI** | Personal interface, settings, chats | User preference |
| **n8n** | Free version = 1 user ONLY | **Licensing restriction** |
| **Jupyter** | Single-user by default | Technical limitation |
| **code-server** | One workspace per instance | Technical limitation |
| **big-AGI** | Browser localStorage | Technical limitation |
| **ChainForge** | Desktop app, local storage | Technical limitation |
| **Kotaemon** | Per-user document uploads | User preference |
| **Flowise** | Limited multi-user | User preference |

#### User Container Template

Each user container (e.g., `10.0.5.200`) runs:
- **8 Docker containers** inside
- **Connects to shared backend** (Ollama, PostgreSQL, etc.)
- **Isolated data** (separate databases, collections, buckets)
- **Independent scaling** (can restart user1 without affecting user2)

**Resource Requirements Per User:**
- RAM: 8-16GB
- Disk: 100-200GB
- Cores: 4-8 CPUs

**Total for 50 users:**
- LXC Containers: 50
- Docker Containers: 400 (8 per user)
- RAM: 400-800GB
- Disk: 5-10TB

---

## Network Layout

### IP Allocation

| Range | Purpose | Count | CTID Range |
|-------|---------|-------|------------|
| `10.0.4.10` | Traefik (reverse proxy) | 1 | - |
| `10.0.5.26-27` | Nextcloud, Supabase (legacy) | 2 | 26, 27 |
| `10.0.5.100-199` | Shared services | ~36 | 100-199 |
| `10.0.5.200-249` | Per-user containers | 50 | 200-249 |

**CTID = Last octet of IP**
- IP `10.0.5.100` → CTID `100` (Ollama)
- IP `10.0.5.102` → CTID `102` (PostgreSQL)
- IP `10.0.5.200` → CTID `200` (User 1)

### Routing via Traefik

All services accessible via domain names routed through Traefik (`10.0.4.10`):

**Traefik Configuration:**
- **Server:** `10.0.4.10`
- **Dynamic config directory:** `/opt/traefik-stack/dynamic`
- **File naming convention:** `205{last_octet}.yml`
  - Example: Service at `10.0.5.100` → Config file `205100.yml`
  - Example: Service at `10.0.5.122` → Config file `205122.yml`
- **SSL/TLS:** Automatic certificate generation via Let's Encrypt
- **Generate configs:** `bash 53_configure_traefik_routing.sh`

**Config file structure (example for Ollama at 10.0.5.100):**
```yaml
# /opt/traefik-stack/dynamic/205100.yml
http:
  routers:
    ollama-router:
      rule: "Host(`ollama.valuechainhackers.xyz`)"
      service: ollama-service
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt

  services:
    ollama-service:
      loadBalancer:
        servers:
          - url: "http://10.0.5.100:11434"
```

**Shared Services:**
- `ollama.valuechainhackers.xyz` → `10.0.5.100:11434`
- `postgres.valuechainhackers.xyz` → `10.0.5.102:5432`
- `qdrant.valuechainhackers.xyz` → `10.0.5.101:6333`

**Per-User Services:**
- `ai-user1.valuechainhackers.xyz` → `10.0.5.200:8080` (Open WebUI)
- `n8n-user1.valuechainhackers.xyz` → `10.0.5.200:5678` (n8n)
- `ai-user2.valuechainhackers.xyz` → `10.0.5.201:8080` (Open WebUI)
- `n8n-user2.valuechainhackers.xyz` → `10.0.5.201:5678` (n8n)

---

## Data Flow Example

### User Makes AI Request

```
1. User opens browser → ai-user1.valuechainhackers.xyz

2. Traefik (10.0.4.10) routes to → Open WebUI (10.0.5.200:8080)

3. Open WebUI calls:
   ├─ Ollama (10.0.5.100) → LLM inference
   ├─ Qdrant (10.0.5.101) → Vector search in user1_docs collection
   ├─ PostgreSQL (10.0.5.102) → Load chat history from openwebui_user1 DB
   ├─ Redis (10.0.5.103) → Cache recent queries in DB 2
   ├─ MinIO (10.0.5.104) → Load uploaded files from user1-openwebui bucket
   └─ SearXNG (10.0.5.105) → Web search if needed

4. Langfuse (10.0.5.106) ← Logs all LLM calls for observability

5. Response returned to user
```

**Key Point**: User1's data stays isolated (separate DB, collection, bucket) while sharing infrastructure (same Ollama, same PostgreSQL server, etc.)

---

## Security & Isolation

### Network Segmentation

```
Internet
    ↓
Traefik (10.0.4.10) ← Only public entry point
    ↓
Services (10.0.5.0/24) ← Private network
```

**Firewall Rules:**
- Block direct access to `10.0.5.0/24` from internet
- All external traffic MUST go through Traefik
- Internal services communicate freely on `10.0.5.0/24`

### Authentication Hierarchy

1. **Authentik SSO** (`10.0.5.146`) → Organization-wide identity
   - OAuth2/OIDC for compatible services (Gitea, Grafana, Portainer)

2. **Service-Level Auth** → Individual service authentication
   - Open WebUI (per-user accounts)
   - n8n (per-instance)

3. **API Keys** → Service-to-service communication
   - Langfuse (per-project keys)
   - MinIO (per-user credentials)

### Data Isolation

**Per-User Data Separation:**

| Service | Isolation Method | User 1 Example | User 2 Example |
|---------|------------------|----------------|----------------|
| PostgreSQL | Database | `openwebui_user1` | `openwebui_user2` |
| Redis | DB number | DB 2 | DB 3 |
| Qdrant | Collection | `user1_docs` | `user2_docs` |
| MinIO | Bucket + IAM | `user1-openwebui` | `user2-openwebui` |
| Langfuse | Project + API keys | User1 project | User2 project |

---

## Deployment Strategy

### Phase 1: Core Infrastructure (5 containers)

**Deploy these FIRST** - foundation for everything:

| Service | IP | CTID | Purpose |
|---------|-----|------|---------|
| Ollama | 10.0.5.100 | 100 | LLM inference |
| Qdrant | 10.0.5.101 | 101 | Vector DB |
| PostgreSQL | 10.0.5.102 | 102 | Relational DB |
| Redis | 10.0.5.103 | 103 | Cache |
| MinIO | 10.0.5.104 | 104 | Object storage |

**Why this order?** These are dependencies for everything else.

---

### Phase 2: Essential Shared Services (6+ containers)

**Deploy after Phase 1:**

| Service | IP | CTID | Purpose |
|---------|-----|------|---------|
| SearXNG | 10.0.5.105 | 105 | Web search |
| Langfuse | 10.0.5.106 | 106 | LLM observability |
| Gitea | 10.0.5.120 | 120 | Git/backups |
| Prometheus | 10.0.5.121 | 121 | Metrics |
| Grafana | 10.0.5.122 | 122 | Dashboards |
| Authentik | 10.0.5.146 | 146 | SSO |

---

### Shared Services Container Requirements

**Container specifications for ALL shared services (10.0.5.100-199):**

#### Core Infrastructure (100-105) - ✅ DEPLOYED

| IP | CTID | Service | CPU | RAM | Disk | Notes |
|----|------|---------|-----|-----|------|-------|
| 10.0.5.100 | 100 | Ollama | 8 cores | 16GB | 200GB | GPU passthrough recommended |
| 10.0.5.101 | 101 | Qdrant | 4 cores | 8GB | 100GB | Vector storage |
| 10.0.5.102 | 102 | PostgreSQL | 4 cores | 8GB | 200GB | All app databases |
| 10.0.5.103 | 103 | Redis | 2 cores | 4GB | 20GB | Cache + sessions |
| 10.0.5.104 | 104 | MinIO | 2 cores | 4GB | 500GB | Object storage |
| 10.0.5.105 | 105 | SearXNG | 2 cores | 2GB | 10GB | Meta-search |

#### Observability & Monitoring (106-107, 121-123) - ✅ DEPLOYED

| IP | CTID | Service | CPU | RAM | Disk | Notes |
|----|------|---------|-----|-----|------|-------|
| 10.0.5.106 | 106 | Langfuse | 2 cores | 2GB | 10GB | LLM observability |
| 10.0.5.107 | 107 | Neo4j | 4 cores | 4GB | 50GB | Graph database |
| 10.0.5.121 | 121 | Prometheus | 2 cores | 4GB | 50GB | Metrics collection |
| 10.0.5.122 | 122 | Grafana | 2 cores | 2GB | 10GB | Dashboards |
| 10.0.5.123 | 123 | Loki | 2 cores | 4GB | 50GB | Log aggregation |

#### AI/ML Services (108-115) - NEEDED

| IP | CTID | Service | CPU | RAM | Disk | Notes |
|----|------|---------|-----|-----|------|-------|
| 10.0.5.108 | 108 | Jupyter | 2 cores | 2GB | 20GB | ⚠️ PER-USER: Deploy in user containers (single-user by default) |
| 10.0.5.109 | 109 | n8n | 2 cores | 2GB | 10GB | ⚠️ PER-USER: Free version = 1 user only |
| 10.0.5.110 | 110 | Flowise | 2 cores | 3GB | 15GB | ⚠️ PER-TEAM: Limited multi-user support |
| 10.0.5.111 | 111 | Tika | 2 cores | 2GB | 10GB | ✅ SHARED: Stateless document parsing |
| 10.0.5.112 | 112 | Docling | 2 cores | 3GB | 15GB | ✅ SHARED: Advanced document parsing |
| 10.0.5.113 | 113 | Whisper | 4 cores | 4GB | 20GB | ✅ SHARED: Stateless STT (GPU optional) |
| 10.0.5.114 | 114 | LibreTranslate | 2 cores | 2GB | 10GB | ✅ SHARED: Translation API |
| 10.0.5.115 | 115 | MCPO | 1 core | 1GB | 5GB | ✅ SHARED: MCP to OpenAPI proxy |

#### Enterprise Tools (116-120) - NEEDED

| IP | CTID | Service | CPU | RAM | Disk | Notes |
|----|------|---------|-----|-----|------|-------|
| 10.0.5.116 | 116 | BookStack | 2 cores | 2GB | 20GB | ✅ SHARED: Multi-user documentation |
| 10.0.5.117 | 117 | Metabase | 2 cores | 2GB | 10GB | ✅ SHARED: Multi-user BI |
| 10.0.5.118 | 118 | Playwright | 2 cores | 2GB | 15GB | ✅ SHARED: Stateless browser automation |
| 10.0.5.119 | 119 | Code-Server | 2 cores | 2GB | 20GB | ⚠️ PER-USER: Single workspace per instance |
| 10.0.5.120 | 120 | Gitea | 2 cores | 2GB | 50GB | ✅ SHARED: Multi-user Git server |

#### Optional Services (124-139) - DEPLOY AS NEEDED

| IP | CTID | Service | CPU | RAM | Disk | Notes |
|----|------|---------|-----|-----|------|-------|
| 10.0.5.124 | 124 | Portainer | 1 core | 1GB | 5GB | ✅ SHARED: Multi-user Docker management |
| 10.0.5.125 | 125 | Formbricks | 1 core | 1GB | 10GB | ✅ SHARED: Multi-user form builder |
| 10.0.5.126 | 126 | Mailserver | 2 cores | 2GB | 20GB | ✅ SHARED: Multi-domain mail server |
| 10.0.5.127 | 127 | CRM | 2 cores | 2GB | 20GB | ✅ SHARED: Multi-user CRM |
| 10.0.5.128 | 128 | Matrix | 2 cores | 3GB | 20GB | ✅ SHARED: Multi-user chat server |
| 10.0.5.129 | 129 | Superset | 4 cores | 4GB | 20GB | ✅ SHARED: Multi-user data viz |
| 10.0.5.130 | 130 | DuckDB | 2 cores | 2GB | 30GB | ✅ SHARED: API-based OLAP database |
| 10.0.5.131 | 131 | RESERVED | - | - | - | Available for future service |
| 10.0.5.132 | 132 | ComfyUI | 4 cores | 8GB | 50GB | ✅ SHARED: Multi-user via API (GPU REQUIRED) |
| 10.0.5.133 | 133 | Automatic1111 | 4 cores | 8GB | 50GB | ✅ SHARED: Multi-user via API (GPU REQUIRED) |
| 10.0.5.134 | 134 | Faster Whisper | 4 cores | 4GB | 20GB | ✅ SHARED: Stateless STT (GPU optional) |
| 10.0.5.135 | 135 | OpenedAI Speech | 2 cores | 2GB | 10GB | ✅ SHARED: Stateless TTS |
| 10.0.5.136 | 136 | ChainForge | 2 cores | 2GB | 10GB | ⚠️ PER-USER: Desktop app, local storage |
| 10.0.5.137 | 137 | Big-AGI | 2 cores | 2GB | 10GB | ⚠️ PER-USER: Browser localStorage |
| 10.0.5.138 | 138 | Kotaemon | 2 cores | 3GB | 15GB | ⚠️ PER-USER: Per-instance document uploads |
| 10.0.5.139 | 139 | LobeChat | 2 cores | 2GB | 10GB | ✅ SHARED: Multi-user AI chat interface |

**Summary Totals:**

| Category | Containers | Total CPU | Total RAM | Total Disk |
|----------|-----------|-----------|-----------|------------|
| **Core (100-105)** | 6 | 22 cores | 42GB | 1030GB |
| **Monitoring (106-107, 121-123)** | 5 | 12 cores | 16GB | 170GB |
| **AI/ML (108-115)** | 8 | 18 cores | 20GB | 105GB |
| **Enterprise (116-120)** | 5 | 10 cores | 10GB | 115GB |
| **Optional (124-139)** | 16 | 44 cores | 59GB | 405GB |
| **TOTAL SHARED SERVICES** | **40** | **106 cores** | **147GB** | **1825GB** |

**Deployment Priority:**
1. **Phase 1** - Core (100-105) - ✅ DONE
2. **Phase 2** - Monitoring (106-107, 121-123) - ✅ DONE
3. **Phase 3** - AI/ML (108-115) - RECOMMENDED NEXT
4. **Phase 4** - Enterprise (116-120) - DEPLOY AS NEEDED
5. **Phase 5** - Optional (124-139) - DEPLOY AS NEEDED

**Important Notes:**
- ❌ **NO DOCKER** on ANY shared service containers (100-199)
- ✅ All services deployed NATIVELY with systemd + apt packages
- Services marked with PostgreSQL dependency need access to 10.0.5.102
- GPU-required services (132-133) will not function without GPU passthrough
- GPU-optional services (100, 113, 134) work better with GPU but can run on CPU

---

### Phase 3: First User Container (1 container)

**Deploy ONE user container to test:**

| Service | IP | CTID | Contains |
|---------|-----|------|----------|
| User 1 | 10.0.5.200 | 200 | 8 Docker containers (Open WebUI, n8n, etc.) |

**Test workflow:**
1. Open WebUI works with Ollama
2. RAG search works with Qdrant
3. Chats persist in PostgreSQL
4. n8n can connect to all services

---

### Phase 4: Scale to More Users

**Clone User 1 container pattern:**

| User | IP | CTID | Status |
|------|-----|------|--------|
| User 2 | 10.0.5.201 | 201 | Clone template |
| User 3 | 10.0.5.202 | 202 | Clone template |
| ... | ... | ... | ... |
| User 50 | 10.0.5.249 | 249 | Clone template |

---

### Phase 5: Optional Services (Deploy as needed)

**Add these when required:**

- Document processing (Tika, Docling, Whisper)
- Image generation (ComfyUI, AUTOMATIC1111)
- Business tools (BookStack, Metabase, EspoCRM)
- Communication (Matrix, Mailcow)

---

## Scaling Considerations

### When to Scale Horizontally

**Ollama** (GPU bottleneck):
- Deploy second instance at `10.0.5.101`
- Use Traefik load balancing

**PostgreSQL** (performance bottleneck):
- Keep single writer at `10.0.5.102`
- Add read replicas at `10.0.5.108+`

**Qdrant** (storage/performance):
- Deploy second instance
- Shard collections across instances

### When to Keep Single Instance

**ALWAYS single instance:**
- **Authentik** (identity source of truth)
- **Gitea** (code collaboration)
- **Matrix** (unified communication)
- **Monitoring** (central visibility)

---

## Backup Strategy

### Critical (Daily Automated)

```bash
# PostgreSQL (ALL application data)
pg_dumpall -U dbadmin > /backups/postgres_$(date +%Y%m%d).sql

# Qdrant snapshots
curl -X POST http://10.0.5.101:6333/collections/{collection}/snapshots

# Gitea repositories
docker exec shared-gitea gitea dump
```

### Important (Weekly)

```bash
# MinIO buckets
mc mirror local/user1-openwebui /backups/minio/user1/

# Redis snapshots
redis-cli BGSAVE
```

### Configuration (On Change)

- Docker compose files → Git repository
- Environment variables → Encrypted storage (`/root/.env`)
- Deployment scripts → This repository
- DNS records → Export periodically

---

## Monitoring & Observability

### Metrics (Prometheus)

**Collect from:**
- All Docker containers (`/metrics` endpoints)
- System metrics (CPU, RAM, GPU, Disk)
- Service-specific metrics (PostgreSQL, Redis, Ollama)

### Logs (Loki)

**Aggregate from:**
- All Docker containers (via Docker driver)
- Systemd services (Ollama, Qdrant)
- Application logs

### Traces (Langfuse)

**Track:**
- All LLM calls from Open WebUI instances
- Ollama API calls
- RAG operations (Qdrant queries)
- Per-user usage tracking

### Dashboards (Grafana)

**Monitor:**
- System resources per host
- Service health and response times
- Per-user activity and token usage
- Cost tracking (GPU hours, storage)

---

## Cost Optimization

### Resource Sharing Benefits

**Without sharing (50 users):**
- Ollama instances: 50 × 200GB = 10TB (models duplicated!)
- PostgreSQL instances: 50 × 50GB = 2.5TB
- Total: ~12.5TB + massive RAM requirements

**With sharing (this architecture):**
- Ollama: 1 × 200GB = 200GB (shared models)
- PostgreSQL: 1 × 200GB = 200GB (all user databases)
- Total: ~6.3TB (50% reduction)

**RAM Savings:**
- Without sharing: 50 × 32GB = 1.6TB RAM (if each user had Ollama)
- With sharing: 32GB + (50 × 8GB) = 432GB RAM
- **Savings: 73% less RAM**

---

## Summary

### Architecture Pattern

✅ **Shared Services** - One container per service, shared by all (36 services)
✅ **Per-User Services** - One container per user, contains all personal services (50 users)

### Key Benefits

1. **Resource Efficiency** - Share expensive infrastructure (GPU, models, databases)
2. **User Isolation** - Per-user data separation while sharing backend
3. **Easy Scaling** - Clone user container template for new users
4. **Central Management** - Single backup point, monitoring, updates
5. **Cost-Effective** - 50-70% resource savings vs per-user everything

### Deployment Phases

1. **Phase 1** - Core infrastructure (5 containers)
2. **Phase 2** - Essential services (6+ containers)
3. **Phase 3** - First user (1 container, test)
4. **Phase 4** - Scale users (49 more containers)
5. **Phase 5** - Optional services (as needed)

### Total Infrastructure

- **LXC Containers**: ~86 (36 shared + 50 users)
- **RAM**: 512-912GB
- **Disk**: 6.3-11.3TB
- **Services**: ~436 (36 shared + 50 × 8 per-user)

---

## Reference Documents

- **[SERVICE_IP_MAP.md](SERVICE_IP_MAP.md)** - Complete IP assignments, ENV vars, health checks
- **[DEPLOYMENT_STATUS.md](DEPLOYMENT_STATUS.md)** - Deployment scripts and order
- **[SHARED_SERVICES_LIMITATIONS.md](SHARED_SERVICES_LIMITATIONS.md)** - Analysis of sharing capabilities
- **[N8N_CONFIGURATION.md](N8N_CONFIGURATION.md)** - n8n integration guide

---

**Ready to deploy!** See [DEPLOYMENT_STATUS.md](DEPLOYMENT_STATUS.md) for step-by-step deployment guide.
