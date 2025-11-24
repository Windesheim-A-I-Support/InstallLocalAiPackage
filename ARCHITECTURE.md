# Network & Deployment Architecture Documentation

## Overview
This document describes the current infrastructure for the AI services deployment on Proxmox LXC containers with Traefik reverse proxy.

---

## Network Topology

### Physical/Virtual Infrastructure
- **Hypervisor**: Proxmox VE
- **Container Technology**: LXC (Linux Containers)
- **Network Range**: 10.0.0.0/16 (private network)

### Network Segments

#### Management Network (10.0.4.0/24)
- **Traefik Reverse Proxy Server**: 10.0.4.10
  - Hostname: `Traefic` (typo in hostname)
  - Role: Central ingress controller for all services
  - Exposed Ports: 80 (HTTP), 443 (HTTPS)
  - Gateway: 10.0.4.1

#### Application Network (10.0.5.0/24)
- **Container 1**: 10.0.5.7 - `openwebui.valuechainhackers.xyz` (NEW - being deployed)
- **Container 2**: 10.0.5.6 - AI Stack (existing deployment)
- **Container 3**: 10.0.5.8 - Team deployment
- **Container 4**: 10.0.5.9 - Team deployment
- **Container 5**: 10.0.5.10 - Team deployment
- **Container 6**: 10.0.5.11 - Team deployment
- **Container 7**: 10.0.5.12 - Team deployment

---

## Traefik Reverse Proxy Configuration

### Location: 10.0.4.10

#### Network Interfaces
```
eth0: 10.0.4.10/24 (Host network)
br-4e8042481b29: 172.18.0.1/16 (Docker bridge)
docker0: 172.17.0.1/16 (Default Docker bridge - unused)
```

#### Running Services
- **traefik-proxy**: Main reverse proxy (ports 80, 443)
- **basic-web**: Test service
- **traefik-dashboard**: Management UI
- **whoami-app**: Test service
- **extra-web**: Additional service

#### Configuration
- **Dynamic Config Directory**: `/opt/traefik-stack/dynamic/`
- **Docker Compose File**: `/opt/traefik-stack/docker-compose.yml`
- **SSL/TLS**: Let's Encrypt via Cloudflare DNS challenge
- **Email**: christiaan.gerardo@gmail.com
- **Dashboard**: https://traefik.valuechainhackers.xyz/dashboard

#### TLS Configuration
- Cert Resolver: `myresolver`
- Provider: Cloudflare DNS-01 challenge
- Auto-renewal enabled
- ACME storage: `/acme.json`

#### Security Features
- HTTP to HTTPS automatic redirection
- Basic authentication on dashboard
- Security headers (HSTS enabled)
- Docker socket read-only mount

---

## Service Routing (Container 2 - 10.0.5.6)

The existing Traefik configuration (`20506LocalAi.yml`) routes to:

### HTTP Services
| Service | Domain | Backend |
|---------|--------|---------|
| Open WebUI | openwebui.valuechainhackers.xyz | http://10.0.5.6:3000 |
| Flowise | flowise.valuechainhackers.xyz | http://10.0.5.6:3001 |
| n8n | n8n.valuechainhackers.xyz | http://10.0.5.6:5678 |
| Langfuse | langfuse.valuechainhackers.xyz | http://10.0.5.6:3002 |
| Neo4j Browser | neo4j.valuechainhackers.xyz | http://10.0.5.6:7474 |
| SearXNG | searxng.valuechainhackers.xyz | http://10.0.5.6:8081 |
| MinIO | minio.valuechainhackers.xyz | http://10.0.5.6:9011 |
| Supabase | supabase.valuechainhackers.xyz | http://10.0.5.6:8000 |

### TCP Services
| Service | Domain | Backend | Protocol |
|---------|--------|---------|----------|
| Neo4j Bolt | neo4j.valuechainhackers.xyz | 10.0.5.6:7687 | Bolt (TLS terminated at Traefik) |

---

## Container Architecture

### Container 1 (10.0.5.7) - NEW DEPLOYMENT

#### Planned Services
- **Open WebUI**: LLM chat interface (port 3000)
- **Ollama**: LLM inference engine (port 11434)
- **Qdrant**: Vector database for RAG (port 6333)
- **n8n**: Workflow automation (port 5678)
- **Flowise**: Low-code AI orchestration (port 3001)
- **Neo4j**: Graph database (ports 7474, 7687)
- **SearXNG**: Search aggregation (port 8081)
- **Langfuse**: LLM observability (port 3002)
- **Supabase**: Backend services (port 8000)
  - PostgreSQL: Database
  - Kong: API Gateway
  - GoTrue: Authentication
  - Storage: File storage
  - Realtime: WebSocket subscriptions

#### Internal Docker Network
- Docker Bridge: 172.18.0.1/16 (on containers)
- Service-to-service communication via container names
- Example: Open WebUI → `http://ollama:11434`

#### LXC Container Type
- **Type**: Unprivileged LXC container
- **Features Required**:
  - `nesting=1` (for Docker-in-Docker)
  - `keyctl=1` (for container capabilities)

---

## Service Integration Architecture

### Data Flow

```
Internet
    ↓ (HTTPS)
Traefik (10.0.4.10:443)
    ↓ (HTTP - internal)
LXC Container (10.0.5.7)
    ↓
Docker Network (172.18.0.0/16)
    ↓
┌─────────────────────────────────────┐
│  Open WebUI (3000)                  │
│    ├─> Ollama (11434)               │
│    ├─> Qdrant (6333)                │
│    └─> Langfuse (3002)              │
│                                     │
│  Flowise (3001)                     │
│    ├─> Ollama (11434)               │
│    ├─> Qdrant (6333)                │
│    ├─> PostgreSQL (5432)            │
│    └─> Langfuse (3002)              │
│                                     │
│  n8n (5678)                         │
│    ├─> Ollama (11434)               │
│    └─> PostgreSQL (5432)            │
│                                     │
│  Langfuse (3002)                    │
│    ├─> PostgreSQL (5432)            │
│    ├─> Clickhouse (8123)            │
│    └─> MinIO (9000)                 │
└─────────────────────────────────────┘
```

### Environment Variables for Integrations

#### Open WebUI
- `VECTOR_DB=qdrant`
- `QDRANT_URI=http://qdrant:6333`
- `OLLAMA_BASE_URL=http://ollama:11434`

#### n8n
- `DB_TYPE=postgresdb`
- `DB_POSTGRESDB_HOST=db`
- `NODE_FUNCTION_ALLOW_EXTERNAL=*`

#### Flowise
- `FLOWISE_DATABASE_TYPE=postgres`
- `FLOWISE_DATABASE_HOST=db`
- Qdrant URL (in UI): `qdrant:6333`
- Ollama URL (in UI): `http://ollama:11434`

#### Ollama
- `OLLAMA_HOST=0.0.0.0:11434`
- `OLLAMA_ORIGINS=*`

---

## DNS Configuration

### Domain: valuechainhackers.xyz
- **DNS Provider**: Cloudflare
- **Records Type**: A records (assumed)

### Subdomains (Existing)
- traefik.valuechainhackers.xyz → 10.0.4.10
- openwebui.valuechainhackers.xyz → 10.0.4.10 (Traefik routes to 10.0.5.6)
- flowise.valuechainhackers.xyz → 10.0.4.10
- n8n.valuechainhackers.xyz → 10.0.4.10
- langfuse.valuechainhackers.xyz → 10.0.4.10
- neo4j.valuechainhackers.xyz → 10.0.4.10
- searxng.valuechainhackers.xyz → 10.0.4.10
- minio.valuechainhackers.xyz → 10.0.4.10
- supabase.valuechainhackers.xyz → 10.0.4.10

### New Deployment (Container 1)
Same subdomains will be used but routing to 10.0.5.7 via new Traefik config file.

---

## Storage Architecture

### Traefik Server (10.0.4.10)
- Configuration: `/opt/traefik-stack/`
  - `dynamic/`: Dynamic route configurations
  - `docker-compose.yml`: Traefik container definition
  - `acme.json`: SSL certificates (Let's Encrypt)
- Backups: `.backup-YYYY-MM-DD-HHMMSS/` directories

### LXC Containers (10.0.5.x)
- Docker volumes for persistent data
- Volume naming: `localai_<service>_<type>`
  - Example: `localai_postgres_data`, `localai_qdrant_storage`

---

## Deployment Process

### Automated Deployment Scripts
1. **01_system_dependencies.sh**: Install system packages (Python, Git, curl, etc.)
2. **02_install_docker.sh**: Install Docker, create user `ai-admin`
3. **Clone Repository**: `git clone -b stable https://github.com/coleam00/local-ai-packaged.git`
4. **generate_env_secrets.sh**: Generate secure credentials
5. **configure_integrations.sh**: Patch docker-compose override with integration configs
6. **start_services.py**: Orchestrate deployment
   - Clones Supabase repository
   - Starts Supabase services
   - Starts AI application stack

### Docker Compose Profile System
- **cpu**: CPU-only Ollama inference
- **gpu-nvidia**: NVIDIA GPU acceleration
- **gpu-amd**: AMD GPU acceleration
- **none**: External Ollama (Mac)

### Environment Types
- **private**: Internal network only (ports not exposed externally)
- **public**: Cloud deployment (only 80/443 exposed)

---

## Security Architecture

### Network Security
- All external traffic through single ingress (Traefik)
- TLS termination at reverse proxy
- Internal services communicate over HTTP (encrypted by container network isolation)
- Unprivileged LXC containers (user namespace isolation)

### Authentication
- Traefik Dashboard: Basic Auth (htpasswd)
- Open WebUI: Application-level authentication
- n8n: Application-level authentication
- Flowise: Username/password (`FLOWISE_USERNAME`, `FLOWISE_PASSWORD`)
- Neo4j: `NEO4J_AUTH=neo4j/<password>`

### Secrets Management
- Environment variables in `.env` file
- Generated using cryptographically secure random functions
- Secrets include:
  - Database passwords
  - JWT secrets
  - Encryption keys
  - API keys

---

## Current Issues & Observations

### Hostname Typo
- Traefik server hostname is "Traefic" (missing 'k')

### Multiple Config Files
- `/opt/traefik-stack/dynamic/` contains multiple LocalAI config files:
  - `20506LocalAi.yml` (10.0.5.6)
  - `20507LocalAi.yml` (10.0.5.7)
  - `20508LocalAi.yml` (10.0.5.8)
  - etc.

### Container Deployment Status
- Container 1 (10.0.5.7): Being deployed (new)
- Container 2 (10.0.5.6): Already deployed and running
- Containers 3-7: Deployed for team use

### LXC Container Requirements
- Supabase containers require sysctl modifications
- Requires LXC container with `nesting=1` and `keyctl=1` features enabled in Proxmox
- Previous deployments resolved this (working in containers 2-7)

---

## Monitoring & Observability

### Traefik Dashboard
- URL: https://traefik.valuechainhackers.xyz/dashboard
- Features:
  - Real-time router status
  - Service health checks
  - Certificate status
  - Request metrics

### Application Monitoring
- **Langfuse**: LLM tracing and observability
  - Tracks Open WebUI and Flowise LLM calls
  - Provides usage analytics and debugging

### Logs
- Traefik access logs enabled
- Docker container logs: `docker logs <container-name>`

---

## Backup Strategy

### Current Backups
- Traefik dynamic configs backed up in `.backup-*` directories
- Manual backups (timestamped)
- Location: `/opt/traefik-stack/dynamic/.backup-YYYY-MM-DD-HHMMSS/`

### Data Requiring Backup
- Docker volumes (databases, vector stores)
- `.env` files (secrets)
- Traefik configurations
- SSL certificates (`acme.json`)

---

## Documentation References

### Official Documentation
- Traefik: https://doc.traefik.io/traefik/
- Open WebUI: https://docs.openwebui.com/
- n8n: https://docs.n8n.io/
- Flowise: https://docs.flowiseai.com/
- Qdrant: https://qdrant.tech/documentation/
- Langfuse: https://langfuse.com/docs
- Supabase: https://supabase.com/docs

### GitHub Repositories
- AI Stack: https://github.com/coleam00/local-ai-packaged
- Deployment Scripts: `/home/chris/Documents/github/InstallLocalAiPackage/`

---

**Document Version**: 1.0
**Last Updated**: 2025-11-24
**Author**: Infrastructure Audit
**Status**: Initial Documentation
