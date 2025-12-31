# Shared Services Limitations

Analysis of which services can be truly shared across multiple users/teams and which have limitations.

## ✅ Fully Shareable (No Limitations)

These services work perfectly when shared across multiple users, teams, or AI interface instances:

### Infrastructure & Data
- **PostgreSQL** (13) - ✅ Multi-database, multi-user, production-grade
- **Redis** (14) - ✅ Multi-client, namespacing via database numbers
- **MinIO** (16) - ✅ Multi-bucket, multi-user, S3-compatible
- **Qdrant** (12) - ✅ Multi-collection, production vector DB
- **Neo4j** (19) - ✅ Multi-database (Enterprise) or separate graphs
- **DuckDB** (40) - ✅ API-based, concurrent queries

### AI/ML Services
- **Ollama** (11) - ✅ Multi-user, concurrent inference
- **SearXNG** (17) - ✅ Stateless search, unlimited users
- **Whisper** (25) - ✅ Stateless STT API
- **faster-whisper** (44) - ✅ Stateless STT API
- **openedai-speech** (45) - ✅ Stateless TTS API
- **LibreTranslate** (26) - ✅ Stateless translation API
- **Tika** (23) - ✅ Stateless document extraction
- **Docling** (24) - ✅ Stateless document parsing
- **MCPO** (27) - ✅ Stateless API proxy

### Development & DevOps
- **Gitea** (28) - ✅ Multi-user, multi-org, multi-repo
- **Prometheus** (29) - ✅ Multi-target monitoring
- **Grafana** (29) - ✅ Multi-user, multi-dashboard
- **Loki** (29) - ✅ Multi-source log aggregation
- **Portainer** (34) - ✅ Multi-user Docker management
- **Playwright** (32) - ✅ Stateless browser automation API

### Image Generation
- **ComfyUI** (42) - ✅ Multi-user via API (if using API mode)
- **AUTOMATIC1111** (43) - ✅ Multi-user via API

## ⚠️ Limited Sharing (Free Version Restrictions)

These services have limitations in free/community versions that may require multiple instances:

### Workflow & Automation
- **n8n** (21) - ⚠️ **Community Edition: Single user only**
  - Free version: 1 user account
  - Solution: Deploy separate instance per user/team
  - OR: Upgrade to n8n Cloud/Enterprise for multi-user
  - Recommended: Individual instances at 10.0.5.109, 10.0.5.110, etc.

### AI Workflow Builders
- **Flowise** (22) - ⚠️ **Limited multi-user in community version**
  - User management exists but limited
  - Better: Deploy per team
  - Recommended: Separate instances for isolation

### Analytics & BI
- **Metabase** (31) - ⚠️ **Free version has user limits**
  - Open source: Unlimited users but limited features
  - Cloud: User-based pricing
  - Can be shared but consider separate instances for departments

- **Superset** (39) - ✅ Open source version supports multi-user well
  - Role-based access control
  - Can be shared across organization

### Notebooks & Code
- **Jupyter** (20) - ⚠️ **JupyterHub vs single-user**
  - Standard Jupyter: Single user
  - JupyterHub: Multi-user (requires different setup)
  - Recommendation: Deploy per user or use JupyterHub

- **code-server** (33) - ⚠️ **Single user per instance**
  - One workspace per instance
  - Solution: Deploy multiple instances
  - Recommended: One per developer

## 🔒 Single-User Services (By Design)

These services are designed for individual users and should have separate instances:

### AI Interfaces
- **Open WebUI** (15) - 🔒 Best practice: Separate instance per user/team
  - Can support multiple users, but better isolation with separate instances
  - Each instance can have different configurations
  - Recommended: Deploy on Layer 2 with dedicated IPs (10.0.5.200+)

- **big-AGI** (47) - 🔒 Single user per instance
  - Browser-based, user settings in localStorage
  - Deploy per user

- **ChainForge** (46) - 🔒 Single user per instance
  - Desktop-like app, local storage
  - Deploy per user/team

- **Kotaemon** (48) - 🔒 Single user per instance
  - Document uploads are per-instance
  - Deploy per user/team

## ✅ Multi-User But Better Separated

These CAN be shared but are better with separate instances for security/isolation:

### Communication
- **Matrix/Element** (38) - ✅ Multi-user chat server
  - Designed for multiple users
  - Can be shared across organization

- **Mailcow** (36) - ✅ Multi-domain, multi-user mail server
  - Designed for multiple users/domains
  - Can be shared

### Content Management
- **Nextcloud** (09) - ✅ Multi-user file storage
  - Designed for teams
  - Can be shared

- **BookStack** (30) - ✅ Multi-user wiki
  - Role-based access
  - Can be shared

- **Formbricks** (35) - ✅ Multi-user surveys
  - Team collaboration
  - Can be shared

### Backend Services
- **Supabase** (10) - ✅ Multi-project, multi-user
  - Designed for multiple applications
  - Can be shared

### CRM & Business
- **EspoCRM** (37) - ✅ Multi-user CRM
  - Designed for teams
  - Can be shared

### Observability
- **Langfuse** (18) - ✅ Multi-project LLM observability
  - Designed for multiple projects/teams
  - Can be shared

### SSO
- **Authentik** (41) - ✅ Multi-application SSO provider
  - Designed to authenticate multiple services
  - ONE instance for entire organization

## 📋 Deployment Strategy

### Shared Services (ONE instance on dedicated IP)
Deploy these ONCE on their assigned IPs (10.0.5.100-146):

```bash
# Core Infrastructure (share these)
bash 11_deploy_shared_ollama.sh         # 10.0.5.100
bash 12_deploy_shared_qdrant.sh         # 10.0.5.101
bash 13_deploy_shared_postgres.sh       # 10.0.5.102
bash 14_deploy_shared_redis.sh          # 10.0.5.103
bash 16_deploy_shared_minio.sh          # 10.0.5.104
bash 17_deploy_shared_searxng.sh        # 10.0.5.105

# Shared Dev Tools
bash 28_deploy_shared_gitea.sh          # 10.0.5.120
bash 29_deploy_shared_monitoring.sh     # 10.0.5.121-123
bash 34_deploy_shared_portainer.sh      # 10.0.5.128

# Shared Communication
bash 36_deploy_shared_mailserver.sh     # 10.0.5.140
bash 38_deploy_shared_matrix.sh         # 10.0.5.142

# SSO (organization-wide)
bash 41_deploy_shared_authentik.sh      # 10.0.5.146
```

### Per-User/Team Services (MULTIPLE instances)
Deploy these for EACH user or team:

```bash
# AI Interfaces (per user)
bash /root/deploy_openwebui_layer2.sh user1 10.0.5.200
bash /root/deploy_openwebui_layer2.sh user2 10.0.5.201
bash 47_deploy_shared_big_agi.sh        # Per user
bash 48_deploy_shared_kotaemon.sh       # Per user

# Workflows (per user/team due to limitations)
bash 21_deploy_shared_n8n.sh            # One per user
bash 22_deploy_shared_flowise.sh        # One per team

# Development (per developer)
bash 20_deploy_shared_jupyter.sh        # Per developer
bash 33_deploy_shared_code_server.sh    # Per developer
```

### Optional Shared Services
Deploy ONCE if needed by multiple users:

```bash
# Document processing (can be shared)
bash 23_deploy_shared_tika.sh
bash 24_deploy_shared_docling.sh

# Audio (can be shared)
bash 44_deploy_shared_faster_whisper.sh
bash 45_deploy_shared_openedai_speech.sh

# Image generation (can be shared via API)
bash 42_deploy_shared_comfyui.sh
bash 43_deploy_shared_automatic1111.sh

# Business tools (share across organization)
bash 30_deploy_shared_bookstack.sh
bash 31_deploy_shared_metabase.sh
bash 37_deploy_shared_crm.sh
```

## 🎯 Recommended Architecture

```
┌─────────────────────────────────────────────────┐
│         Shared Infrastructure Layer             │
│  (ONE instance, ALL users connect)              │
│                                                  │
│  Ollama, Qdrant, PostgreSQL, Redis, MinIO       │
│  SearXNG, Gitea, Monitoring, Authentik          │
│  10.0.5.100-146                                 │
└─────────────────────────────────────────────────┘
                      ▲
                      │ Connect
                      │
┌─────────────────────┼─────────────────────────┐
│                     │                         │
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  User 1     │  │  User 2     │  │  Team A     │
│             │  │             │  │             │
│ OpenWebUI   │  │ OpenWebUI   │  │ n8n         │
│ big-AGI     │  │ Kotaemon    │  │ Flowise     │
│ Jupyter     │  │ code-server │  │ Metabase    │
│             │  │             │  │             │
│ 10.0.5.200  │  │ 10.0.5.201  │  │ 10.0.5.202  │
└─────────────┘  └─────────────┘  └─────────────┘
```

## Summary

**Truly Shareable (46+ → actually ~30 services):**
- Infrastructure: PostgreSQL, Redis, MinIO, Qdrant, Neo4j, DuckDB (6)
- AI/ML APIs: Ollama, SearXNG, Whisper, faster-whisper, openedai-speech, LibreTranslate, Tika, Docling, MCPO (9)
- DevOps: Gitea, Prometheus, Grafana, Loki, Portainer, Playwright (6)
- Communication: Matrix, Mailcow (2)
- Content: Nextcloud, BookStack, Formbricks (3)
- Business: Supabase, EspoCRM, Superset (3)
- SSO: Authentik (1)

**Per-User/Team (~21 services):**
- AI Interfaces: Open WebUI, big-AGI, ChainForge, Kotaemon (4)
- Workflows: n8n, Flowise (2) ⚠️ Limited in free version
- Development: Jupyter, code-server (2)
- Optional: Metabase, ComfyUI, AUTOMATIC1111, Langfuse (varies by use case)

**Deployment Rule:**
- Services on 10.0.5.100-179: Deploy ONCE, share across organization
- Services on 10.0.5.200+: Deploy PER USER/TEAM as needed
