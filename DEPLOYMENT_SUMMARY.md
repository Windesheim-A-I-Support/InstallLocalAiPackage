# Deployment Summary

## Complete Enterprise AI Infrastructure

This repository now contains **45 deployment scripts** for a complete, scalable enterprise AI infrastructure centered around **Open WebUI**.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Open WebUI (Central Hub)                │
│              Connect unlimited instances via Docker          │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼────────┐  ┌────────▼────────┐  ┌────────▼────────┐
│  AI/ML Core    │  │  Data & Storage │  │  Enterprise     │
│  (11-12,18-27) │  │  (13-14,16-17)  │  │  Tools (28-45)  │
└────────────────┘  └─────────────────┘  └─────────────────┘
```

## Service Count by Category

| Category | Count | Scripts |
|----------|-------|---------|
| **Base System** | 3 | 01-02, 07 |
| **All-in-One Stack** | 1 | 08 (legacy) |
| **Cloud Services** | 2 | 09-10 |
| **AI/ML Core** | 17 | 11-12, 16-27 |
| **Enterprise Tools** | 8 | 28-35 |
| **Communication & Auth** | 6 | 36-41 |
| **Image Gen & A/V** | 4 | 42-45 |
| **Instance Deployment** | 1 | 15 |
| **TOTAL** | **42** | **Deployment scripts** |

## Complete Service Inventory

### Base System (3 scripts)
- **01** - System dependencies (Python, build tools, PostgreSQL client)
- **02** - Docker installation with user configuration
- **07** - SSH enablement and configuration

### All-in-One Stack (1 script - Legacy)
- **08** - Minimal AI stack (Ollama + Qdrant + Open WebUI + Pipelines all-in-one)

### Cloud Services (2 scripts)
- **09** - Nextcloud (file storage, WebDAV, collaboration)
- **10** - Supabase (backend-as-a-service, auth, database, storage)

### AI/ML Core Services (17 scripts)
- **11** - Ollama (LLM inference engine) - Native
- **12** - Qdrant (vector database for RAG) - Native
- **13** - PostgreSQL (shared relational database)
- **14** - Redis (caching and sessions)
- **16** - MinIO (S3-compatible object storage)
- **17** - SearXNG (privacy-respecting meta search)
- **18** - Langfuse (LLM observability and tracing)
- **19** - Neo4j (graph database)
- **20** - Jupyter (data science notebooks)
- **21** - n8n (workflow automation)
- **22** - Flowise (visual AI workflow builder)
- **23** - Tika (text extraction from documents)
- **24** - Docling (advanced document parsing)
- **25** - Whisper (standard speech-to-text)
- **26** - LibreTranslate (translation service)
- **27** - MCPO (Model Context Protocol to OpenAPI proxy)

### Enterprise Tools (8 scripts)
- **28** - Gitea (Git service, version control)
- **29** - Monitoring Stack (Prometheus + Grafana + Loki)
- **30** - BookStack (wiki and documentation)
- **31** - Metabase (business intelligence)
- **32** - Playwright (browser automation)
- **33** - code-server (VS Code in browser)
- **34** - Portainer (container management UI)
- **35** - Formbricks (user feedback and surveys)

### Communication & Business (6 scripts)
- **36** - Mailcow (full mail server: SMTP, IMAP, webmail)
- **37** - EspoCRM (customer relationship management)
- **38** - Matrix + Element (secure team chat)
- **39** - Apache Superset (enterprise BI and analytics)
- **40** - DuckDB (analytical database with HTTP API)
- **41** - Authentik (SSO, OAuth2, SAML provider)

### Image Generation & Enhanced A/V (4 scripts)
- **42** - ComfyUI (modern node-based Stable Diffusion)
- **43** - AUTOMATIC1111 (classic Stable Diffusion WebUI)
- **44** - faster-whisper (optimized STT, much faster than standard)
- **45** - openedai-speech (fast TTS with Piper/Coqui engines)

### Instance Deployment (1 script)
- **15** - Open WebUI instance deployment (scales horizontally)

## Deployment Patterns

### Pattern 1: All-in-One (Simple, Single Server)
```bash
bash 01_system_dependencies.sh
bash 02_install_docker.sh ai-admin
bash 08_minimal_ai_stack.sh ai-admin
```
✅ Quick start, single server
❌ Doesn't scale, all services bundled

### Pattern 2: Scalable Architecture (Recommended)
```bash
# 1. Base system
bash 01_system_dependencies.sh
bash 02_install_docker.sh ai-admin

# 2. Deploy shared AI/ML services (once)
bash 11_deploy_shared_ollama.sh
bash 12_deploy_shared_qdrant.sh
bash 13_deploy_shared_postgres.sh
bash 14_deploy_shared_redis.sh
bash 16_deploy_shared_minio.sh
bash 17_deploy_shared_searxng.sh
# ... continue with other shared services as needed

# 3. Deploy unlimited Open WebUI instances
bash 15_deploy_openwebui_instance.sh webui1 3000
bash 15_deploy_openwebui_instance.sh webui2 3001
bash 15_deploy_openwebui_instance.sh team-sales 3002
bash 15_deploy_openwebui_instance.sh team-dev 3003
```
✅ Scales horizontally
✅ Shared infrastructure
✅ Resource efficient

## Update Mechanism

**ALL scripts support `--update` flag:**
```bash
bash 11_deploy_shared_ollama.sh --update
bash 42_deploy_shared_comfyui.sh --update
```

This pattern ensures:
- ✅ No separate update scripts needed
- ✅ Consistent update process
- ✅ Safe updates with minimal downtime

## Key Features

### 1. Unified Authentication Strategy
- Individual auth per service (current)
- Optional SSO with Authentik (script 41)
- OAuth2/OIDC for compatible services
- See [AUTHENTICATION_STRATEGY.md](AUTHENTICATION_STRATEGY.md)

### 2. Centralized Configuration
- All connection URLs documented in [SERVICES_REFERENCE.md](SERVICES_REFERENCE.md)
- Environment variables for Open WebUI integration
- Database credentials managed via `generate_env_secrets.sh`

### 3. Open WebUI as Central Hub
All services connect to Open WebUI:
- **LLM**: Ollama
- **Pipelines**: Plugin framework
- **RAG**: Qdrant vector DB
- **Search**: SearXNG
- **STT**: faster-whisper (enhanced) or Whisper (standard)
- **TTS**: openedai-speech (enhanced) or Ollama (standard)
- **Images**: AUTOMATIC1111 or ComfyUI
- **Storage**: MinIO (S3), Nextcloud (WebDAV)
- **Database**: PostgreSQL, Redis
- **Monitoring**: Langfuse

### 4. GPU Support
Services with GPU acceleration:
- ComfyUI (script 42)
- AUTOMATIC1111 (script 43)
- faster-whisper (script 44)
- Ollama (script 11)

Automatically detects NVIDIA GPU and configures accordingly.

### 5. Native vs Docker Deployments
**Native (for performance):**
- Ollama (script 11)
- Qdrant (script 12)

**Docker (for portability):**
- Everything else

## Infrastructure Servers

| Server | IP | Domain | Purpose |
|--------|------|--------|---------|
| Traefik | 10.0.4.10 | - | Reverse proxy & SSL |
| AI Stack | 10.0.5.24 | ai-24.valuechainhackers.xyz | Main AI services |
| Nextcloud | 10.0.5.26 | nextcloud.valuechainhackers.xyz | File storage |
| Supabase | 10.0.5.27 | supabase.valuechainhackers.xyz | Backend services |

## Port Allocation

Organized port ranges:
- **3000-3099**: Web UIs (Open WebUI instances, services)
- **5000-5999**: Processing services (Docling, LibreTranslate, n8n, etc.)
- **6000-6999**: Databases (Qdrant, Redis)
- **7000-7999**: AI services (AUTOMATIC1111)
- **8000-8999**: APIs and utilities (faster-whisper, openedai-speech, SearXNG, etc.)
- **9000-9999**: Infrastructure (Whisper, Prometheus, Tika, Portainer, Authentik)
- **11434**: Ollama

See [SERVICES_REFERENCE.md](SERVICES_REFERENCE.md) for complete port mapping.

## Database Architecture

**Shared PostgreSQL** (script 13) hosts databases for:
- Langfuse
- Flowise
- n8n
- Gitea
- BookStack
- Metabase
- Formbricks
- EspoCRM
- Matrix/Synapse
- Apache Superset
- Authentik

All databases auto-created by deployment scripts.
Single PostgreSQL instance = easier backups, resource efficiency.

## Documentation

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Quick start and script index |
| [SERVICES_REFERENCE.md](SERVICES_REFERENCE.md) | Complete service inventory with URLs and connection strings |
| [AUTHENTICATION_STRATEGY.md](AUTHENTICATION_STRATEGY.md) | Auth architecture and SSO integration guide |
| [SCALING_GUIDE.md](SCALING_GUIDE.md) | Architecture patterns and scaling strategies |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Step-by-step deployment instructions |
| [ENV-REFERENCE.md](ENV-REFERENCE.md) | Environment variables reference |
| **DEPLOYMENT_SUMMARY.md** | This document - comprehensive overview |

## Next Steps

### Immediate Deployment
1. Choose deployment pattern (all-in-one vs scalable)
2. Run base scripts (01, 02)
3. Deploy shared services as needed
4. Deploy Open WebUI instances
5. Configure Pipelines in Open WebUI UI
6. Pull Ollama models

### Optional Enhancements
1. Deploy Authentik (script 41) for SSO
2. Configure Traefik routing for clean domains
3. Deploy monitoring stack (script 29)
4. Set up mail server (script 36) for notifications
5. Deploy image generation (scripts 42-43) for AI art
6. Configure enhanced STT/TTS (scripts 44-45) for better voice

### Security Hardening
1. Change all default passwords (see AUTHENTICATION_STRATEGY.md)
2. Configure firewall rules
3. Enable HTTPS via Traefik
4. Set up regular backups
5. Implement Authentik SSO (optional)

## Maintenance

**Regular updates:**
```bash
# Update all shared services
for i in {11..45}; do
  [ -f "${i}_deploy_shared_*.sh" ] && bash ${i}_deploy_shared_*.sh --update
done

# Or update specific services
bash 11_deploy_shared_ollama.sh --update
bash 15_deploy_openwebui_instance.sh webui1 3000 --update
```

**Monitoring:**
- Grafana: http://10.0.5.24:3004
- Prometheus: http://10.0.5.24:9090
- Portainer: https://10.0.5.24:9443
- Langfuse: http://10.0.5.24:3002

**Backups:**
- PostgreSQL databases: `pg_dump` or `pg_dumpall`
- Docker volumes: Standard Docker backup procedures
- Configuration files: Git repository (this repo)

## Success Criteria

✅ 45 deployment scripts created
✅ All scripts support `--update` flag
✅ Scalable architecture with shared services
✅ Open WebUI as central hub
✅ Complete documentation
✅ GPU support for relevant services
✅ OpenAI-compatible APIs where possible
✅ Single PostgreSQL for efficiency
✅ Clean domain names via Traefik
✅ Comprehensive service inventory

## Summary

This infrastructure provides:
- **Complete AI Stack**: From LLMs to image generation
- **Enterprise Tools**: Git, CI/CD, monitoring, documentation
- **Communication**: Email, chat, CRM
- **Business Intelligence**: Analytics, dashboards, surveys
- **Authentication**: Individual or unified SSO
- **Scalability**: Unlimited Open WebUI instances
- **Maintainability**: Simple update mechanism
- **Documentation**: Complete reference materials

All centered around **Open WebUI** as the primary interface for AI interactions.
