# IP Allocation Plan

## Network Architecture

**Network:** 10.0.5.0/24
**Gateway:** 10.0.4.10 (Traefik)
**DNS Domain:** valuechainhackers.xyz

## IP Ranges

- **10.0.5.1-10.0.5.50**: Infrastructure & Primary Servers
- **10.0.5.100-10.0.5.199**: Shared Services (AI/ML, Enterprise, Communication)
- **10.0.5.200-10.0.5.254**: Dynamic/Instance Deployments

## Assigned IPs

### Primary Infrastructure (10.0.5.1-50)

| IP | Service | Domain | Purpose |
|----|---------|--------|---------|
| 10.0.4.10 | Traefik | - | Reverse proxy & SSL termination |
| 10.0.5.24 | AI Stack | ai-24.valuechainhackers.xyz | Main AI services (legacy deployment) |
| 10.0.5.26 | Nextcloud | nextcloud.valuechainhackers.xyz | Cloud storage & collaboration |
| 10.0.5.27 | Supabase | supabase.valuechainhackers.xyz | Backend-as-a-Service |

### Shared Services (10.0.5.100-199)

#### AI/ML Core (100-119)

| IP | Service | Domain | Port | Purpose |
|----|---------|--------|------|---------|
| 10.0.5.100 | Ollama | ollama.valuechainhackers.xyz | 11434 | LLM inference (native) |
| 10.0.5.101 | Qdrant | qdrant.valuechainhackers.xyz | 6333 | Vector database (native) |
| 10.0.5.102 | PostgreSQL | postgres.valuechainhackers.xyz | 5432 | Shared relational DB |
| 10.0.5.103 | Redis | redis.valuechainhackers.xyz | 6379 | Cache & sessions |
| 10.0.5.104 | MinIO | minio.valuechainhackers.xyz | 9001 | S3-compatible storage |
| 10.0.5.105 | SearXNG | searxng.valuechainhackers.xyz | 8080 | Meta search engine |
| 10.0.5.106 | Langfuse | langfuse.valuechainhackers.xyz | 3002 | LLM observability |
| 10.0.5.107 | Neo4j | neo4j.valuechainhackers.xyz | 7474 | Graph database |
| 10.0.5.108 | Jupyter | jupyter.valuechainhackers.xyz | 8888 | Data science notebooks |
| 10.0.5.109 | n8n | n8n.valuechainhackers.xyz | 5678 | Workflow automation |
| 10.0.5.110 | Flowise | flowise.valuechainhackers.xyz | 3001 | Visual AI workflows |
| 10.0.5.111 | Tika | tika.valuechainhackers.xyz | 9998 | Text extraction |
| 10.0.5.112 | Docling | docling.valuechainhackers.xyz | 5001 | Document parsing |
| 10.0.5.113 | Whisper | whisper.valuechainhackers.xyz | 9000 | Speech-to-text |
| 10.0.5.114 | LibreTranslate | translate.valuechainhackers.xyz | 5000 | Translation |
| 10.0.5.115 | MCPO | mcpo.valuechainhackers.xyz | 8765 | MCP-to-OpenAPI proxy |

#### Enterprise Tools (120-139)

| IP | Service | Domain | Port | Purpose |
|----|---------|--------|------|---------|
| 10.0.5.120 | Gitea | git.valuechainhackers.xyz | 3003 | Git service |
| 10.0.5.121 | Prometheus | prometheus.valuechainhackers.xyz | 9090 | Metrics collection |
| 10.0.5.122 | Grafana | grafana.valuechainhackers.xyz | 3004 | Metrics visualization |
| 10.0.5.123 | Loki | loki.valuechainhackers.xyz | 3100 | Log aggregation |
| 10.0.5.124 | BookStack | wiki.valuechainhackers.xyz | 3005 | Documentation wiki |
| 10.0.5.125 | Metabase | metabase.valuechainhackers.xyz | 3006 | Business intelligence |
| 10.0.5.126 | Playwright | playwright.valuechainhackers.xyz | 3007 | Browser automation |
| 10.0.5.127 | code-server | code.valuechainhackers.xyz | 8443 | VS Code in browser |
| 10.0.5.128 | Portainer | portainer.valuechainhackers.xyz | 9443 | Container management |
| 10.0.5.129 | Formbricks | formbricks.valuechainhackers.xyz | 3008 | Surveys & feedback |

#### Communication & Business (140-159)

| IP | Service | Domain | Port | Purpose |
|----|---------|--------|------|---------|
| 10.0.5.140 | Mailcow | mail.valuechainhackers.xyz | 25/587/993 | Mail server |
| 10.0.5.141 | EspoCRM | crm.valuechainhackers.xyz | 3009 | Customer relationship mgmt |
| 10.0.5.142 | Matrix | matrix.valuechainhackers.xyz | 8008 | Team chat (Synapse) |
| 10.0.5.143 | Element | element.valuechainhackers.xyz | 3010 | Matrix web client |
| 10.0.5.144 | Superset | superset.valuechainhackers.xyz | 3011 | Enterprise BI |
| 10.0.5.145 | DuckDB | duckdb.valuechainhackers.xyz | 8089 | Analytical DB API |
| 10.0.5.146 | Authentik | auth.valuechainhackers.xyz | 9000 | SSO/OAuth2 provider |

#### Image Generation & A/V (160-179)

| IP | Service | Domain | Port | Purpose |
|----|---------|--------|------|---------|
| 10.0.5.160 | ComfyUI | comfyui.valuechainhackers.xyz | 8188 | Node-based Stable Diffusion |
| 10.0.5.161 | AUTOMATIC1111 | sd.valuechainhackers.xyz | 7860 | Classic SD WebUI |
| 10.0.5.162 | faster-whisper | stt.valuechainhackers.xyz | 8000 | Optimized speech-to-text |
| 10.0.5.163 | openedai-speech | tts.valuechainhackers.xyz | 8001 | Fast text-to-speech |

#### LLM Tools & Interfaces (180-199)

| IP | Service | Domain | Port | Purpose |
|----|---------|--------|------|---------|
| 10.0.5.180 | ChainForge | chainforge.valuechainhackers.xyz | 8002 | Prompt engineering |
| 10.0.5.181 | big-AGI | bigagi.valuechainhackers.xyz | 3012 | Advanced multi-model UI |
| 10.0.5.182 | Kotaemon | kotaemon.valuechainhackers.xyz | 7860 | RAG document QA |

### Dynamic Instances (10.0.5.200-254)

| IP Range | Service | Purpose |
|----------|---------|---------|
| 10.0.5.200-209 | Open WebUI | Instance deployments (webui1, webui2, etc.) |
| 10.0.5.210-254 | Reserved | Future dynamic instances |

## DNS Configuration

All services should have corresponding DNS A records in the `valuechainhackers.xyz` domain.

### Example DNS Records

```
# Infrastructure
traefik.valuechainhackers.xyz     A  10.0.4.10
ai-24.valuechainhackers.xyz       A  10.0.5.24
nextcloud.valuechainhackers.xyz   A  10.0.5.26
supabase.valuechainhackers.xyz    A  10.0.5.27

# AI/ML Core
ollama.valuechainhackers.xyz      A  10.0.5.100
qdrant.valuechainhackers.xyz      A  10.0.5.101
postgres.valuechainhackers.xyz    A  10.0.5.102
# ... etc

# LLM Interfaces
chainforge.valuechainhackers.xyz  A  10.0.5.180
bigagi.valuechainhackers.xyz      A  10.0.5.181
kotaemon.valuechainhackers.xyz    A  10.0.5.182
```

## Traefik Configuration

Each service should have a corresponding Traefik dynamic configuration file in `/opt/traefik-stack/dynamic/`:

**Example:** `/opt/traefik-stack/dynamic/flowise.yml`
```yaml
http:
  routers:
    flowise:
      rule: "Host(`flowise.valuechainhackers.xyz`)"
      entryPoints:
        - websecure
      service: flowise
      tls:
        certResolver: letsencrypt

  services:
    flowise:
      loadBalancer:
        servers:
          - url: "http://10.0.5.110:3001"
```

## Migration Strategy

For services currently deployed on 10.0.5.24 without dedicated IPs:

1. **Option A: In-place** - Keep on 10.0.5.24 with port mapping
2. **Option B: Migrate** - Deploy to dedicated IP from 10.0.5.100+ range
3. **Option C: Hybrid** - Critical services get dedicated IPs, others stay on 10.0.5.24

**Recommended:** Option B for production, Option A for testing/development

## Port Allocation Summary

Services on dedicated IPs expose standard ports:
- Web UIs: Standard HTTP/HTTPS (80/443 via Traefik)
- APIs: Standard ports (e.g., PostgreSQL 5432, Redis 6379)
- Internal services: Original ports

Services on shared hosts (like 10.0.5.24) use unique high ports:
- 3000-3099: Web UIs
- 5000-5999: Processing services
- 6000-6999: Databases
- 7000-7999: AI services
- 8000-8999: APIs
- 9000-9999: Infrastructure

## Implementation

To deploy a service to its dedicated IP:

1. Provision server/VM with assigned IP
2. Configure DNS A record
3. Deploy service using deployment script
4. Create Traefik routing configuration
5. Test access via domain name

## Notes

- All IPs are static assignments
- Dynamic range (200-254) uses DHCP reservation or manual assignment
- Traefik handles SSL termination for all HTTPS services
- Internal service-to-service communication can use IPs or domains
- Services on 10.0.5.24 are legacy deployments, can be migrated gradually
