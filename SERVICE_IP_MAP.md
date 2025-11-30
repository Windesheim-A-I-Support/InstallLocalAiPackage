# Service IP Address Mapping & Architecture

**Complete list of all services with assigned IP addresses, environment variables, and health checks**

Last Updated: 2025-11-30

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   SHARED INFRASTRUCTURE                      │
│            (ONE container per service)                       │
│                                                              │
│  Each service in dedicated LXC container on 10.0.5.100-199  │
│  All users connect to these shared backend services         │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │
                  All users connect here
                              │
┌─────────────────────────────┼─────────────────────────────┐
│                             │                             │
│                             │                             │
┌───────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  User 1 Container │  │ User 2 Container │  │ User 3 Container │
│  (10.0.5.200)     │  │ (10.0.5.201)     │  │ (10.0.5.202)     │
│                   │  │                  │  │                  │
│  • openwebui-u1   │  │ • openwebui-u2   │  │ • openwebui-u3   │
│  • n8n-u1         │  │ • n8n-u2         │  │ • n8n-u3         │
│  • jupyter-u1     │  │ • jupyter-u2     │  │ • jupyter-u2     │
│  • code-server-u1 │  │ • code-server-u2 │  │ • code-server-u3 │
│  • big-agi-u1     │  │ • big-agi-u2     │  │ • big-agi-u3     │
│  • kotaemon-u1    │  │ • kotaemon-u2    │  │ • kotaemon-u3    │
│  • chainforge-u1  │  │ • chainforge-u2  │  │ • chainforge-u3  │
│  • flowise-u1     │  │ • flowise-u2     │  │ • flowise-u3     │
└───────────────────┘  └──────────────────┘  └──────────────────┘

         ... continues to User 50 (10.0.5.249) ...
```

---

## Currently Deployed

| Service | IP Address | Container | Status | Health Check |
|---------|------------|-----------|--------|--------------|
| Traefik | `10.0.4.10` | traefik | ✅ Running | `curl http://10.0.4.10:8080/ping` |
| Nextcloud | `10.0.5.26` | nextcloud | ✅ Running | `curl -I https://nextcloud.valuechainhackers.xyz/status.php` |
| Supabase | `10.0.5.27` | supabase | ✅ Running | `curl http://10.0.5.27:8000/health` |

---

# SHARED SERVICES (Deploy ONCE - Each in Own Container)

## AI/ML Core Services (10.0.5.100-119)

### Ollama - LLM Inference Engine

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.100` |
| **Container** | CTID 100, hostname: `ollama` |
| **Port(s)** | 11434 |
| **Domain** | `ollama.valuechainhackers.xyz` |
| **Script** | `11_deploy_shared_ollama.sh` |
| **Type** | Native (systemd service for GPU performance) |
| **Sharing** | ✅ **SHARED** - All users use same instance |

**Environment Variables:**
```bash
# No auth by default (internal network)
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_ORIGINS=*
# Optional:
# OLLAMA_DEBUG=1
# OLLAMA_NUM_PARALLEL=4
```

**Health Check:**
```bash
curl http://10.0.5.100:11434/api/tags
# Should return list of models
```

**Resource Requirements:**
- RAM: 16GB minimum, 32GB recommended
- Disk: 200GB (models are large: 7GB-70GB each)
- GPU: Optional but highly recommended (NVIDIA with CUDA)

**Why Shared:** Concurrent inference supported, models are large (avoid duplication), GPU shared efficiently

---

### Qdrant - Vector Database

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.101` |
| **Container** | CTID 101, hostname: `qdrant` |
| **Port(s)** | 6333 (HTTP), 6334 (gRPC) |
| **Domain** | `qdrant.valuechainhackers.xyz` |
| **Script** | `12_deploy_shared_qdrant.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Multi-collection support |

**Environment Variables:**
```bash
# Optional API key for production
QDRANT_API_KEY=<optional-api-key>
```

**Health Check:**
```bash
curl http://10.0.5.101:6333/healthz
# Should return: {"status":"ok"}
```

**Resource Requirements:**
- RAM: 4GB minimum, 8GB recommended
- Disk: 100GB (grows with vectors)

**Isolation Strategy:** Per-user collections (`user1_docs`, `user2_docs`, etc.)

**Why Shared:** Native multi-collection support, efficient resource usage

---

### PostgreSQL - Relational Database

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.102` |
| **Container** | CTID 102, hostname: `postgres` |
| **Port(s)** | 5432 |
| **Domain** | `postgres.valuechainhackers.xyz` |
| **Script** | `13_deploy_shared_postgres.sh <password>` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Multi-database support |

**Environment Variables:**
```bash
POSTGRES_PASSWORD=<generated-once>
POSTGRES_USER=dbadmin

# Connection string template
DATABASE_URL=postgresql://dbadmin:${POSTGRES_PASSWORD}@10.0.5.102:5432/${DB_NAME}
```

**Databases Created:**
- `openwebui_user1`, `openwebui_user2`, ... (per-user Open WebUI data)
- `n8n_user1`, `n8n_user2`, ... (per-user n8n workflows)
- `langfuse` (shared LLM observability)
- `gitea` (shared git server)
- `bookstack` (shared wiki)
- `metabase` (shared analytics)
- `formbricks` (shared surveys)
- `espocrm` (shared CRM)
- `synapse` (shared Matrix server)
- `superset` (shared BI)
- `authentik` (shared SSO)

**Health Check:**
```bash
docker exec shared-postgres pg_isready -U dbadmin
# Should return: accepting connections
```

**Resource Requirements:**
- RAM: 4GB minimum, 8GB recommended
- Disk: 50GB minimum, 200GB recommended (grows with data)

**Isolation Strategy:** Database-level separation per user/service

**Why Shared:** Production-grade multi-database support, single backup point, efficient resource usage

---

### Redis - Cache & Session Store

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.103` |
| **Container** | CTID 103, hostname: `redis` |
| **Port(s)** | 6379 |
| **Domain** | `redis.valuechainhackers.xyz` |
| **Script** | `14_deploy_shared_redis.sh <password>` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Multi-database support (0-15) |

**Environment Variables:**
```bash
REDIS_PASSWORD=<generated-once>

# Connection string template
REDIS_URL=redis://:${REDIS_PASSWORD}@10.0.5.103:6379/${DB_NUMBER}

# Database allocation:
# DB 0: General caching
# DB 1: Authentik sessions
# DB 2: Open WebUI user1
# DB 3: Open WebUI user2
# DB 4: n8n user1 queue
# DB 5: n8n user2 queue
# ... etc
```

**Health Check:**
```bash
docker exec shared-redis redis-cli --pass ${REDIS_PASSWORD} PING
# Should return: PONG
```

**Resource Requirements:**
- RAM: 1GB minimum, 2GB recommended
- Disk: 20GB (for persistence)

**Isolation Strategy:** Database number separation (0-15)

**Why Shared:** Lightweight, built-in multi-database support, efficient

---

### MinIO - S3-Compatible Object Storage

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.104` |
| **Container** | CTID 104, hostname: `minio` |
| **Port(s)** | 9000 (API), 9001 (Console) |
| **Domain** | `minio.valuechainhackers.xyz` |
| **Script** | `16_deploy_shared_minio.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Multi-bucket, multi-user |

**Environment Variables:**
```bash
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=<generated-once>

# S3 endpoint for clients
S3_ENDPOINT_URL=http://10.0.5.104:9000

# Per-user credentials (create via MinIO console)
S3_ACCESS_KEY_USER1=<generated>
S3_SECRET_KEY_USER1=<generated>
```

**Buckets:**
- `user1-openwebui`, `user2-openwebui`, ... (per-user Open WebUI files)
- `user1-n8n`, `user2-n8n`, ... (per-user n8n files)
- `shared-models` (shared AI model storage)
- `backups` (system backups)

**Health Check:**
```bash
curl http://10.0.5.104:9000/minio/health/live
# Should return: OK
```

**Resource Requirements:**
- RAM: 2GB minimum, 4GB recommended
- Disk: 100GB minimum, 500GB+ recommended (grows with files)

**Isolation Strategy:** Bucket-level permissions with IAM policies

**Why Shared:** S3-compatible, multi-bucket support, efficient storage

---

### SearXNG - Privacy-Respecting Search Engine

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.105` |
| **Container** | CTID 105, hostname: `searxng` |
| **Port(s)** | 8080 |
| **Domain** | `searxng.valuechainhackers.xyz` |
| **Script** | `17_deploy_shared_searxng.sh <secret>` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Stateless search |

**Environment Variables:**
```bash
SEARXNG_SECRET=<generated-once>
SEARXNG_QUERY_URL=http://10.0.5.105:8080/search?q=<query>
```

**Health Check:**
```bash
curl -I http://10.0.5.105:8080/
# Should return: 200 OK
```

**Resource Requirements:**
- RAM: 1GB
- Disk: 10GB

**Why Shared:** Stateless, no user data stored, instant search for all users

---

### Langfuse - LLM Observability

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.106` |
| **Container** | CTID 106, hostname: `langfuse` |
| **Port(s)** | 3002 |
| **Domain** | `langfuse.valuechainhackers.xyz` |
| **Script** | `18_deploy_shared_langfuse.sh 10.0.5.102 <postgres_password>` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Multi-project support |

**Environment Variables:**
```bash
LANGFUSE_HOST=http://10.0.5.106:3002
DATABASE_URL=postgresql://dbadmin:${POSTGRES_PASSWORD}@10.0.5.102:5432/langfuse

# Per-user/project keys (generated in UI)
LANGFUSE_PUBLIC_KEY_USER1=<from-ui>
LANGFUSE_SECRET_KEY_USER1=<from-ui>
LANGFUSE_PUBLIC_KEY_USER2=<from-ui>
LANGFUSE_SECRET_KEY_USER2=<from-ui>
```

**Health Check:**
```bash
curl http://10.0.5.106:3002/api/public/health
# Should return: {"status":"ok"}
```

**Resource Requirements:**
- RAM: 2GB
- Disk: 20GB

**Isolation Strategy:** Project-level separation with API keys

**Why Shared:** Multi-project observability platform, all users send traces to single instance

---

### Neo4j - Graph Database

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.107` |
| **Container** | CTID 107, hostname: `neo4j` |
| **Port(s)** | 7474 (HTTP), 7687 (Bolt) |
| **Domain** | `neo4j.valuechainhackers.xyz` |
| **Script** | `19_deploy_shared_neo4j.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Multi-database (Enterprise) or label-based (Community) |

**Environment Variables:**
```bash
NEO4J_PASSWORD=<generated-once>
NEO4J_URI=bolt://10.0.5.107:7687
NEO4J_USER=neo4j
```

**Health Check:**
```bash
curl http://10.0.5.107:7474/
# Should return Neo4j browser HTML
```

**Resource Requirements:**
- RAM: 4GB
- Disk: 50GB

**Isolation Strategy:** Multi-database (Enterprise) or label prefixes (Community)

**Why Shared:** Efficient graph queries, multi-database or labeling support

---

### Tika - Document Text Extraction

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.111` |
| **Container** | CTID 111, hostname: `tika` |
| **Port(s)** | 9998 |
| **Domain** | `tika.valuechainhackers.xyz` |
| **Script** | `23_deploy_shared_tika.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Stateless processing |

**Environment Variables:**
```bash
TIKA_URL=http://10.0.5.111:9998
```

**Health Check:**
```bash
curl http://10.0.5.111:9998/tika
# Should return: OK
```

**Resource Requirements:**
- RAM: 2GB
- Disk: 10GB

**Why Shared:** Stateless document extraction API, no data retention

---

### Docling - Document Parser

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.112` |
| **Container** | CTID 112, hostname: `docling` |
| **Port(s)** | 5001 |
| **Domain** | `docling.valuechainhackers.xyz` |
| **Script** | `24_deploy_shared_docling.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Stateless processing |

**Environment Variables:**
```bash
DOCLING_URL=http://10.0.5.112:5001
```

**Health Check:**
```bash
curl http://10.0.5.112:5001/health
# Should return: {"status":"healthy"}
```

**Resource Requirements:**
- RAM: 2GB
- Disk: 10GB

**Why Shared:** Stateless document parsing API

---

### Whisper - Speech-to-Text (Standard)

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.113` |
| **Container** | CTID 113, hostname: `whisper` |
| **Port(s)** | 9000 |
| **Domain** | `whisper.valuechainhackers.xyz` |
| **Script** | `25_deploy_shared_whisper.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Stateless STT |

**Environment Variables:**
```bash
WHISPER_URL=http://10.0.5.113:9000
```

**Health Check:**
```bash
curl http://10.0.5.113:9000/health
# Should return: OK
```

**Resource Requirements:**
- RAM: 4GB
- Disk: 20GB

**Why Shared:** Stateless audio transcription

**Note:** Consider using faster-whisper (10.0.5.162) instead for better performance

---

### LibreTranslate - Translation API

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.114` |
| **Container** | CTID 114, hostname: `libretranslate` |
| **Port(s)** | 5000 |
| **Domain** | `translate.valuechainhackers.xyz` |
| **Script** | `26_deploy_shared_libretranslate.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Stateless translation |

**Environment Variables:**
```bash
TRANSLATE_URL=http://10.0.5.114:5000
```

**Health Check:**
```bash
curl http://10.0.5.114:5000/languages
# Should return: JSON array of supported languages
```

**Resource Requirements:**
- RAM: 2GB
- Disk: 10GB

**Why Shared:** Stateless language translation API

---

### MCPO - MCP to OpenAPI Proxy

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.115` |
| **Container** | CTID 115, hostname: `mcpo` |
| **Port(s)** | 8765 |
| **Domain** | `mcpo.valuechainhackers.xyz` |
| **Script** | `27_deploy_shared_mcpo.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Proxy service |

**Environment Variables:**
```bash
MCPO_URL=http://10.0.5.115:8765
```

**Health Check:**
```bash
curl http://10.0.5.115:8765/health
# Should return: OK
```

**Resource Requirements:**
- RAM: 512MB
- Disk: 10GB

**Why Shared:** MCP protocol to OpenAPI proxy for tool integration

---

## DevOps & Development Services (10.0.5.120-139)

### Gitea - Git Server

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.120` |
| **Container** | CTID 120, hostname: `gitea` |
| **Port(s)** | 3003 (HTTP), 2222 (SSH) |
| **Domain** | `gitea.valuechainhackers.xyz` |
| **Script** | `28_deploy_shared_gitea.sh 10.0.5.102 <postgres_password>` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Multi-user by design |

**Environment Variables:**
```bash
GIT_URL=http://10.0.5.120:3003
DATABASE_URL=postgresql://dbadmin:${POSTGRES_PASSWORD}@10.0.5.102:5432/gitea
```

**Health Check:**
```bash
curl -I http://10.0.5.120:3003/
# Should return: 200 OK
```

**Resource Requirements:**
- RAM: 1GB
- Disk: 100GB (grows with repositories)

**Why Shared:** Multi-user, multi-org, multi-repo by design, code collaboration platform

---

### Prometheus - Metrics Collection

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.121` |
| **Container** | CTID 121, hostname: `prometheus` |
| **Port(s)** | 9090 |
| **Domain** | `prometheus.valuechainhackers.xyz` |
| **Script** | `29_deploy_shared_monitoring.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Central monitoring |

**Environment Variables:**
```bash
PROMETHEUS_URL=http://10.0.5.121:9090
```

**Health Check:**
```bash
curl http://10.0.5.121:9090/-/healthy
# Should return: Prometheus is Healthy
```

**Resource Requirements:**
- RAM: 4GB
- Disk: 100GB (time-series data)

**Why Shared:** Central metrics collection for entire infrastructure

---

### Grafana - Visualization & Dashboards

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.122` |
| **Container** | CTID 122, hostname: `grafana` |
| **Port(s)** | 3004 |
| **Domain** | `grafana.valuechainhackers.xyz` |
| **Script** | `29_deploy_shared_monitoring.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Multi-user with RBAC |

**Environment Variables:**
```bash
GRAFANA_URL=http://10.0.5.122:3004
GF_SECURITY_ADMIN_PASSWORD=<generated-once>
```

**Health Check:**
```bash
curl http://10.0.5.122:3004/api/health
# Should return: {"database":"ok","version":"..."}
```

**Resource Requirements:**
- RAM: 1GB
- Disk: 20GB

**Why Shared:** Multi-user dashboards, team collaboration, RBAC support

---

### Loki - Log Aggregation

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.123` |
| **Container** | CTID 123, hostname: `loki` |
| **Port(s)** | 3100 |
| **Domain** | `loki.valuechainhackers.xyz` |
| **Script** | `29_deploy_shared_monitoring.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Central logging |

**Environment Variables:**
```bash
LOKI_URL=http://10.0.5.123:3100
```

**Health Check:**
```bash
curl http://10.0.5.123:3100/ready
# Should return: ready
```

**Resource Requirements:**
- RAM: 2GB
- Disk: 100GB (log data)

**Why Shared:** Central log aggregation from all Docker containers and services

---

### BookStack - Wiki & Documentation

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.124` |
| **Container** | CTID 124, hostname: `bookstack` |
| **Port(s)** | 3005 |
| **Domain** | `wiki.valuechainhackers.xyz` |
| **Script** | `30_deploy_shared_bookstack.sh 10.0.5.102 <postgres_password>` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Team wiki with RBAC |

**Environment Variables:**
```bash
WIKI_URL=http://10.0.5.124:3005
DATABASE_URL=postgresql://dbadmin:${POSTGRES_PASSWORD}@10.0.5.102:5432/bookstack
APP_KEY=<generated-once>
```

**Health Check:**
```bash
curl -I http://10.0.5.124:3005/
# Should return: 200 OK
```

**Resource Requirements:**
- RAM: 1GB
- Disk: 20GB

**Why Shared:** Collaborative documentation platform with permissions

---

### Metabase - Analytics & BI

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.125` |
| **Container** | CTID 125, hostname: `metabase` |
| **Port(s)** | 3006 |
| **Domain** | `metabase.valuechainhackers.xyz` |
| **Script** | `31_deploy_shared_metabase.sh 10.0.5.102 <postgres_password>` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** (with caution for sensitive data) |

**Environment Variables:**
```bash
METABASE_URL=http://10.0.5.125:3006
DATABASE_URL=postgresql://dbadmin:${POSTGRES_PASSWORD}@10.0.5.102:5432/metabase
MB_DB_TYPE=postgres
```

**Health Check:**
```bash
curl http://10.0.5.125:3006/api/health
# Should return: {"status":"ok"}
```

**Resource Requirements:**
- RAM: 2GB
- Disk: 20GB

**Why Shared:** Can share for company-wide analytics, consider separate for sensitive departments

---

### Playwright - Browser Automation

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.126` |
| **Container** | CTID 126, hostname: `playwright` |
| **Port(s)** | 3007 |
| **Domain** | `playwright.valuechainhackers.xyz` |
| **Script** | `32_deploy_shared_playwright.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Stateless API |

**Environment Variables:**
```bash
PLAYWRIGHT_URL=http://10.0.5.126:3007
```

**Health Check:**
```bash
curl http://10.0.5.126:3007/health
# Should return: OK
```

**Resource Requirements:**
- RAM: 2GB
- Disk: 10GB

**Why Shared:** Stateless browser automation for web scraping/testing

---

### Portainer - Docker Management

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.128` |
| **Container** | CTID 128, hostname: `portainer` |
| **Port(s)** | 9443 (HTTPS), 9000 (HTTP) |
| **Domain** | `portainer.valuechainhackers.xyz` |
| **Script** | `34_deploy_shared_portainer.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Multi-user with RBAC |

**Environment Variables:**
```bash
PORTAINER_URL=https://10.0.5.128:9443
```

**Health Check:**
```bash
curl -k https://10.0.5.128:9443/api/status
# Should return: {"Version":"..."}
```

**Resource Requirements:**
- RAM: 512MB
- Disk: 20GB

**Why Shared:** Multi-user Docker/container management with permissions

---

### Formbricks - Survey Platform

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.129` |
| **Container** | CTID 129, hostname: `formbricks` |
| **Port(s)** | 3008 |
| **Domain** | `formbricks.valuechainhackers.xyz` |
| **Script** | `35_deploy_shared_formbricks.sh 10.0.5.102 <postgres_password>` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Team surveys |

**Environment Variables:**
```bash
FORMBRICKS_URL=http://10.0.5.129:3008
DATABASE_URL=postgresql://dbadmin:${POSTGRES_PASSWORD}@10.0.5.102:5432/formbricks
NEXTAUTH_SECRET=<generated-once>
```

**Health Check:**
```bash
curl -I http://10.0.5.129:3008/
# Should return: 200 OK
```

**Resource Requirements:**
- RAM: 1GB
- Disk: 20GB

**Why Shared:** Team survey and feedback platform

---

## Communication & Business Services (10.0.5.140-159)

### Mailcow - Mail Server

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.140` |
| **Container** | CTID 140, hostname: `mailcow` |
| **Port(s)** | 443 (HTTPS), 25 (SMTP), 587 (Submission), 993 (IMAPS) |
| **Domain** | `mail.valuechainhackers.xyz` |
| **Script** | `36_deploy_shared_mailserver.sh` |
| **Type** | Docker Compose stack |
| **Sharing** | ✅ **SHARED** - Multi-domain, multi-user |

**Environment Variables:**
```bash
MAIL_DOMAIN=mail.valuechainhackers.xyz
MAILCOW_ADMIN_PASSWORD=<generated-once>
```

**Health Check:**
```bash
curl -k https://10.0.5.140/
# Should return: Mailcow login page
```

**Resource Requirements:**
- RAM: 4GB
- Disk: 50GB

**Why Shared:** Complete mail server with multi-user support, mailboxes per user

---

### EspoCRM - Customer Relationship Management

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.141` |
| **Container** | CTID 141, hostname: `espocrm` |
| **Port(s)** | 3009 |
| **Domain** | `crm.valuechainhackers.xyz` |
| **Script** | `37_deploy_shared_crm.sh 10.0.5.102 <postgres_password>` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Team CRM |

**Environment Variables:**
```bash
CRM_URL=http://10.0.5.141:3009
DATABASE_URL=postgresql://dbadmin:${POSTGRES_PASSWORD}@10.0.5.102:5432/espocrm
```

**Health Check:**
```bash
curl -I http://10.0.5.141:3009/
# Should return: 200 OK
```

**Resource Requirements:**
- RAM: 2GB
- Disk: 20GB

**Why Shared:** Team CRM with multi-user support, shared customer database

---

### Matrix (Synapse) - Chat Server

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.142` |
| **Container** | CTID 142, hostname: `matrix` |
| **Port(s)** | 8008 |
| **Domain** | `matrix.valuechainhackers.xyz` |
| **Script** | `38_deploy_shared_matrix.sh 10.0.5.102 <postgres_password> <domain>` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Multi-user chat |

**Environment Variables:**
```bash
MATRIX_URL=http://10.0.5.142:8008
DATABASE_URL=postgresql://dbadmin:${POSTGRES_PASSWORD}@10.0.5.102:5432/synapse
```

**Health Check:**
```bash
curl http://10.0.5.142:8008/_matrix/client/versions
# Should return: JSON with Matrix versions
```

**Resource Requirements:**
- RAM: 2GB
- Disk: 50GB

**Why Shared:** Federated chat server designed for multiple users, rooms, and teams

---

### Element - Matrix Web Client

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.143` |
| **Container** | CTID 143, hostname: `element` |
| **Port(s)** | 3010 |
| **Domain** | `element.valuechainhackers.xyz` |
| **Script** | `38_deploy_shared_matrix.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Web UI for Matrix |

**Environment Variables:**
```bash
ELEMENT_URL=http://10.0.5.143:3010
```

**Health Check:**
```bash
curl -I http://10.0.5.143:3010/
# Should return: 200 OK
```

**Resource Requirements:**
- RAM: 512MB
- Disk: 10GB

**Why Shared:** Web interface for Matrix chat

---

### Superset - Business Intelligence

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.144` |
| **Container** | CTID 144, hostname: `superset` |
| **Port(s)** | 3011 |
| **Domain** | `superset.valuechainhackers.xyz` |
| **Script** | `39_deploy_shared_superset.sh 10.0.5.102 <postgres_password>` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Multi-user with row-level security |

**Environment Variables:**
```bash
SUPERSET_URL=http://10.0.5.144:3011
DATABASE_URL=postgresql://dbadmin:${POSTGRES_PASSWORD}@10.0.5.102:5432/superset
SECRET_KEY=<generated-once>
```

**Health Check:**
```bash
curl http://10.0.5.144:3011/health
# Should return: {"status":"ok"}
```

**Resource Requirements:**
- RAM: 4GB
- Disk: 20GB

**Why Shared:** Multi-user BI with RBAC and row-level security

---

### DuckDB API - Analytical Database

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.145` |
| **Container** | CTID 145, hostname: `duckdb` |
| **Port(s)** | 8089 |
| **Domain** | `duckdb.valuechainhackers.xyz` |
| **Script** | `40_deploy_shared_duckdb.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Stateless analytical queries |

**Environment Variables:**
```bash
DUCKDB_URL=http://10.0.5.145:8089
```

**Health Check:**
```bash
curl http://10.0.5.145:8089/health
# Should return: OK
```

**Resource Requirements:**
- RAM: 2GB
- Disk: 20GB

**Why Shared:** Stateless, fast analytical queries on data

---

### Authentik - SSO & Identity Provider

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.146` |
| **Container** | CTID 146, hostname: `authentik` |
| **Port(s)** | 9000 (HTTP), 9443 (HTTPS) |
| **Domain** | `authentik.valuechainhackers.xyz` |
| **Script** | `41_deploy_shared_authentik.sh 10.0.5.102 <postgres_password> 10.0.5.103 <redis_password>` |
| **Type** | Docker Compose stack |
| **Sharing** | ✅ **SHARED** - Single identity source for organization |

**Environment Variables:**
```bash
AUTHENTIK_URL=http://10.0.5.146:9000
DATABASE_URL=postgresql://dbadmin:${POSTGRES_PASSWORD}@10.0.5.102:5432/authentik
REDIS_URL=redis://:${REDIS_PASSWORD}@10.0.5.103:6379/1

AUTHENTIK_SECRET_KEY=<generated-once>
AUTHENTIK_BOOTSTRAP_TOKEN=<generated-once>
AUTHENTIK_BOOTSTRAP_PASSWORD=<generated-once>
```

**Health Check:**
```bash
curl http://10.0.5.146:9000/-/health/live/
# Should return: {"status":"ok"}
```

**Resource Requirements:**
- RAM: 4GB
- Disk: 20GB

**Why Shared:** CRITICAL - Single source of truth for identity, OAuth2/OIDC provider

**Note:** ALWAYS deploy single instance - this is your identity source

---

## Image Generation & A/V Services (10.0.5.160-179)

### ComfyUI - Image Generation Workflows

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.160` |
| **Container** | CTID 160, hostname: `comfyui` |
| **Port(s)** | 8188 |
| **Domain** | `comfyui.valuechainhackers.xyz` |
| **Script** | `42_deploy_shared_comfyui.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** (API mode) or ❌ **PER-TEAM** (different model needs) |

**Environment Variables:**
```bash
COMFYUI_URL=http://10.0.5.160:8188
```

**Health Check:**
```bash
curl http://10.0.5.160:8188/
# Should return: ComfyUI interface HTML
```

**Resource Requirements:**
- RAM: 8GB
- Disk: 50GB (models)
- GPU: 8GB+ VRAM recommended

**Decision Point:** Share if team uses same models, separate if different needs

---

### AUTOMATIC1111 - Stable Diffusion WebUI

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.161` |
| **Container** | CTID 161, hostname: `automatic1111` |
| **Port(s)** | 7860 |
| **Domain** | `sd-webui.valuechainhackers.xyz` |
| **Script** | `43_deploy_shared_automatic1111.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** (API mode) or ❌ **PER-TEAM** |

**Environment Variables:**
```bash
SD_WEBUI_URL=http://10.0.5.161:7860
```

**Health Check:**
```bash
curl http://10.0.5.161:7860/
# Should return: WebUI HTML
```

**Resource Requirements:**
- RAM: 8GB
- Disk: 50GB (models)
- GPU: 8GB+ VRAM

**Decision Point:** Similar to ComfyUI

---

### faster-whisper - Speech-to-Text (Optimized)

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.162` |
| **Container** | CTID 162, hostname: `faster-whisper` |
| **Port(s)** | 8000 |
| **Domain** | `faster-whisper.valuechainhackers.xyz` |
| **Script** | `44_deploy_shared_faster_whisper.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Stateless STT |

**Environment Variables:**
```bash
STT_API_BASE_URL=http://10.0.5.162:8000/v1
# OpenAI-compatible API
```

**Health Check:**
```bash
curl http://10.0.5.162:8000/v1/models
# Should return: Available models
```

**Resource Requirements:**
- RAM: 4GB
- Disk: 20GB

**Why Shared:** Optimized Whisper, OpenAI API compatible, stateless

**Recommended:** Use this over standard Whisper

---

### openedai-speech - Text-to-Speech

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.163` |
| **Container** | CTID 163, hostname: `openedai-speech` |
| **Port(s)** | 8001 |
| **Domain** | `openedai-speech.valuechainhackers.xyz` |
| **Script** | `45_deploy_shared_openedai_speech.sh` |
| **Type** | Docker container |
| **Sharing** | ✅ **SHARED** - Stateless TTS |

**Environment Variables:**
```bash
TTS_API_BASE_URL=http://10.0.5.163:8001/v1
# OpenAI-compatible API
```

**Health Check:**
```bash
curl http://10.0.5.163:8001/v1/models
# Should return: Available voices
```

**Resource Requirements:**
- RAM: 2GB
- Disk: 10GB

**Why Shared:** Fast TTS with Piper/Coqui, OpenAI compatible, stateless

---

# PER-USER SERVICES (One Container Per User)

## User Containers (10.0.5.200-249 = 50 Users)

Each user gets **ONE LXC container** containing **ALL their personal Docker containers**.

### Container Template

| Property | Value |
|----------|-------|
| **IP Range** | `10.0.5.200` - `10.0.5.249` (50 users) |
| **Container** | CTID 200-249, hostname: `user1`, `user2`, etc. |
| **Type** | LXC container with Docker inside |
| **Sharing** | ❌ **PER-USER** - Dedicated container per user |

**Resource Requirements PER CONTAINER:**
- RAM: 8GB minimum, 16GB recommended
- Disk: 100GB minimum, 200GB recommended
- Cores: 4-8 CPUs

---

### Services Inside Each User Container

Each user container runs these Docker containers:

| Service | Internal Port | Why Per-User |
|---------|---------------|--------------|
| **Open WebUI** | 8080 | Personal AI interface, settings, chats |
| **n8n** | 5678 | Free version = 1 user ONLY (licensing) |
| **Jupyter** | 8888 | Single-user by default |
| **code-server** | 8443 | One workspace per instance |
| **big-AGI** | 3012 | Browser localStorage, single user |
| **ChainForge** | 8000 | Desktop app, local storage |
| **Kotaemon** | 7860 | Per-user document uploads |
| **Flowise** | 3000 | Limited multi-user (better per-user) |

---

### User 1 (10.0.5.200)

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.200` |
| **Container** | CTID 200, hostname: `user1` |
| **Status** | 📦 Ready to provision |

**Docker Containers Inside:**
```bash
# All running inside 10.0.5.200
openwebui-user1       # Port 8080 -> ai-user1.valuechainhackers.xyz
n8n-user1             # Port 5678 -> n8n-user1.valuechainhackers.xyz
jupyter-user1         # Port 8888 -> jupyter-user1.valuechainhackers.xyz
code-server-user1     # Port 8443 -> code-user1.valuechainhackers.xyz
big-agi-user1         # Port 3012 -> bigagi-user1.valuechainhackers.xyz
chainforge-user1      # Port 8000 -> chainforge-user1.valuechainhackers.xyz
kotaemon-user1        # Port 7860 -> kotaemon-user1.valuechainhackers.xyz
flowise-user1         # Port 3000 -> flowise-user1.valuechainhackers.xyz
```

**Environment Variables (for containers inside):**
```bash
# Connections to SHARED infrastructure
OLLAMA_BASE_URL=http://10.0.5.100:11434
QDRANT_URI=http://10.0.5.101:6333
DATABASE_URL=postgresql://dbadmin:PASS@10.0.5.102:5432/openwebui_user1
REDIS_URL=redis://:PASS@10.0.5.103:6379/2
S3_ENDPOINT_URL=http://10.0.5.104:9000
SEARXNG_QUERY_URL=http://10.0.5.105:8080/search?q=<query>

# Per-user secrets (MUST be unique)
WEBUI_SECRET_KEY_USER1=<unique-generated>
N8N_ENCRYPTION_KEY_USER1=<unique-generated>
N8N_JWT_SECRET_USER1=<unique-generated>

# Per-user isolation
QDRANT_COLLECTION=user1_docs
S3_BUCKET_NAME=user1-openwebui
JUPYTER_TOKEN=<user1-token>
```

**Health Checks:**
```bash
# From host
curl http://10.0.5.200:8080/    # Open WebUI
curl http://10.0.5.200:5678/    # n8n
curl http://10.0.5.200:8888/    # Jupyter
curl http://10.0.5.200:8443/    # code-server
```

---

### User 2 (10.0.5.201)

| Property | Value |
|----------|-------|
| **IP** | `10.0.5.201` |
| **Container** | CTID 201, hostname: `user2` |
| **Status** | 📦 Ready to provision |

**Docker Containers Inside:**
```bash
openwebui-user2, n8n-user2, jupyter-user2, code-server-user2, etc.
```

**Environment Variables:** Same pattern as User 1, with `user2` substitutions

---

### User 3-50 (10.0.5.202-249)

| IP Range | Containers | Status |
|----------|------------|--------|
| `10.0.5.202` - `10.0.5.249` | CTID 202-249, hostnames: `user3`-`user50` | 📦 Ready to provision |

Each follows the same pattern as User 1 and User 2.

---

## User Container Deployment Script

To deploy a new user container:

```bash
# 1. Create LXC container
SERVICE_NAME="user1"
SERVICE_IP="10.0.5.200"
CTID="200"

pct create $CTID local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname $SERVICE_NAME \
  --memory 16384 \
  --swap 8192 \
  --cores 8 \
  --net0 name=eth0,bridge=vmbr0,ip=$SERVICE_IP/24,gw=10.0.4.1 \
  --storage local-lvm \
  --rootfs local-lvm:100 \
  --password "Localbaby100!" \
  --unprivileged 1 \
  --features nesting=1

pct start $CTID

# 2. Install Docker
pct exec $CTID -- bash -c "apt update && apt install -y curl"
pct exec $CTID -- bash -c "curl -fsSL https://get.docker.com | sh"

# 3. Deploy all per-user services
# (Run deployment scripts inside the container)
```

---

# Summary Tables

## Shared Services Summary (30+ services)

| IP Range | Service Count | Purpose | Total RAM | Total Disk |
|----------|---------------|---------|-----------|------------|
| 10.0.5.100-119 | 15 | AI/ML Core | ~60GB | ~700GB |
| 10.0.5.120-139 | 10 | DevOps & Development | ~15GB | ~300GB |
| 10.0.5.140-159 | 7 | Communication & Business | ~15GB | ~200GB |
| 10.0.5.160-179 | 4 | Image Gen & A/V | ~22GB | ~130GB |
| **Total Shared** | **~36** | **All categories** | **~112GB** | **~1.3TB** |

## Per-User Services Summary (50 users)

| IP Range | User Count | Services Per User | RAM Per User | Disk Per User |
|----------|------------|-------------------|--------------|---------------|
| 10.0.5.200-249 | 50 | 8 Docker containers | 8-16GB | 100-200GB |
| **Total Per-User** | **50** | **8 services each** | **400-800GB** | **5-10TB** |

## Grand Total

| Category | Containers | RAM | Disk |
|----------|------------|-----|------|
| Shared Services | ~36 | ~112GB | ~1.3TB |
| Per-User (50 users) | 50 | 400-800GB | 5-10TB |
| **TOTAL** | **~86** | **~512-912GB** | **~6.3-11.3TB** |

---

# Health Check Reference

## Quick Health Check Script

```bash
#!/bin/bash
# Check health of all shared services

echo "=== Shared Services Health Check ==="

# Core Infrastructure
curl -sf http://10.0.5.100:11434/api/tags > /dev/null && echo "✅ Ollama" || echo "❌ Ollama"
curl -sf http://10.0.5.101:6333/healthz > /dev/null && echo "✅ Qdrant" || echo "❌ Qdrant"
docker exec shared-postgres pg_isready -U dbadmin > /dev/null 2>&1 && echo "✅ PostgreSQL" || echo "❌ PostgreSQL"
docker exec shared-redis redis-cli --pass $REDIS_PASSWORD PING > /dev/null 2>&1 && echo "✅ Redis" || echo "❌ Redis"
curl -sf http://10.0.5.104:9000/minio/health/live > /dev/null && echo "✅ MinIO" || echo "❌ MinIO"

# Add more as needed...
```

---

# Environment Variables Reference

## Central Secrets (Generate Once)

```bash
# Generate all secrets at once
bash generate_env_secrets.sh

# Core infrastructure
POSTGRES_PASSWORD=<openssl rand -base64 32>
REDIS_PASSWORD=<openssl rand -base64 32>
SEARXNG_SECRET=<openssl rand -base64 32>
MINIO_ROOT_PASSWORD=<openssl rand -base64 32>
NEO4J_PASSWORD=<openssl rand -base64 32>

# Authentik (CRITICAL)
AUTHENTIK_SECRET_KEY=<openssl rand -base64 64>
AUTHENTIK_BOOTSTRAP_TOKEN=<openssl rand -base64 32>
AUTHENTIK_BOOTSTRAP_PASSWORD=<strong-password>

# Per-user secrets (generate for each user)
for i in {1..50}; do
  echo "WEBUI_SECRET_KEY_USER$i=$(openssl rand -base64 32)"
  echo "N8N_ENCRYPTION_KEY_USER$i=$(openssl rand -base64 32)"
  echo "N8N_JWT_SECRET_USER$i=$(openssl rand -base64 32)"
  echo "JUPYTER_TOKEN_USER$i=$(openssl rand -base64 32)"
done
```

**Storage:** `/root/.env` on each container (secure permissions, never commit to Git!)

---

# Next Steps

1. ✅ Review this updated SERVICE_IP_MAP.md
2. 📦 Provision containers for Phase 1 (5 shared infrastructure containers)
3. 🔑 Provide SSH access to containers
4. 🚀 Deploy shared services one by one
5. 📊 Set up monitoring (Grafana/Prometheus)
6. 👥 Provision first user container (10.0.5.200)
7. 🧪 Test user services
8. 📈 Scale to more users as needed

Let me know when Phase 1 containers (100-104) are ready!
