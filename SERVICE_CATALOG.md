# Service Catalog

Comprehensive reference for all 51 deployment scripts with details, purposes, and update information.

## Legend

- 🐳 = Docker container
- 🔧 = Native installation
- 🔄 = Supports `--update` flag
- 🌐 = Has web UI
- 🔗 = API only

---

## Base System (3 scripts)

### 01 - System Dependencies 🔧
**Script**: `01_system_dependencies.sh`
**Purpose**: Install base system packages (Python, build tools, PostgreSQL client, etc.)
**Update**: Re-run script to update packages
**Notes**: Required before any other deployment

### 02 - Docker Installation 🔧
**Script**: `02_install_docker.sh <username>`
**Purpose**: Install Docker CE, Docker Compose, configure user permissions
**Update**: Use script 51 to pin version
**Notes**: Adds user to docker group, requires logout/login

### 07 - SSH Configuration 🔧
**Script**: `07_enablessh.sh`
**Purpose**: Enable and configure SSH server
**Update**: Re-run to apply config changes
**Notes**: Sets up SSH keys, configures sshd

---

## All-in-One Stack (1 script)

### 08 - Minimal AI Stack 🐳🌐🔄
**Script**: `08_minimal_ai_stack.sh <username>`
**Purpose**: Legacy all-in-one deployment (Ollama + Qdrant + Open WebUI + Pipelines)
**Services**: Ollama, Qdrant, Open WebUI, Pipelines, Redis, MinIO, SearXNG, Tika, MCPO
**Update**: Components don't support `--update`, redeploy instead
**Port**: 3000 (Open WebUI)
**Notes**: Simple deployment for testing, not recommended for production scaling

---

## Cloud Services (2 scripts)

### 09 - Nextcloud 🐳🌐🔄
**Script**: `09_deploy_nextcloud.sh`
**Purpose**: Cloud storage, file sync, collaboration platform
**Port**: 80
**Domain**: nextcloud.valuechainhackers.xyz
**Update**: `bash 09_deploy_nextcloud.sh --update`
**Default Creds**: Create admin on first login
**Features**: WebDAV, CalDAV, file sharing, office integration

###  10 - Supabase 🐳🌐🔄
**Script**: `10_deploy_supabase.sh`
**Purpose**: Backend-as-a-Service (PostgreSQL + Auth + Storage + Functions)
**Port**: 3000 (Studio), 8000 (API)
**Domain**: supabase.valuechainhackers.xyz
**Update**: `bash 10_deploy_supabase.sh --update`
**Features**: Database, authentication, storage, real-time subscriptions, edge functions

---

## AI/ML Core Services (17 scripts)

### 11 - Ollama 🔧🔗🔄
**Script**: `11_deploy_shared_ollama.sh`
**Purpose**: Local LLM inference engine
**Port**: 11434
**Planned IP**: 10.0.5.100
**Domain**: ollama.valuechainhackers.xyz
**Update**: `bash 11_deploy_shared_ollama.sh --update`
**Models**: Pull with `ollama pull <model>`
**Notes**: Native install for performance, GPU support via CUDA

### 12 - Qdrant 🔧🌐🔄
**Script**: `12_deploy_shared_qdrant.sh`
**Purpose**: Vector database for RAG and embeddings
**Port**: 6333 (API), 6334 (Web UI)
**Planned IP**: 10.0.5.101
**Domain**: qdrant.valuechainhackers.xyz
**Update**: `bash 12_deploy_shared_qdrant.sh --update`
**Notes**: Native for performance, stores embeddings for semantic search

### 13 - PostgreSQL 🐳🔗🔄
**Script**: `13_deploy_shared_postgres.sh <password>`
**Purpose**: Shared relational database for all services
**Port**: 5432
**Planned IP**: 10.0.5.102
**Domain**: postgres.valuechainhackers.xyz
**Update**: `bash 13_deploy_shared_postgres.sh --update`
**User**: dbadmin
**Databases**: Langfuse, Flowise, n8n, Gitea, BookStack, Metabase, etc. (auto-created)
**Notes**: Single PostgreSQL instance for all services

### 14 - Redis 🐳🔗🔄
**Script**: `14_deploy_shared_redis.sh <password>`
**Purpose**: Cache and session storage
**Port**: 6379
**Planned IP**: 10.0.5.103
**Domain**: redis.valuechainhackers.xyz
**Update**: `bash 14_deploy_shared_redis.sh --update`
**Notes**: Persistent storage enabled

### 16 - MinIO 🐳🌐🔄
**Script**: `16_deploy_shared_minio.sh`
**Purpose**: S3-compatible object storage
**Port**: 9001 (Console), 9000 (API)
**Planned IP**: 10.0.5.104
**Domain**: minio.valuechainhackers.xyz
**Update**: `bash 16_deploy_shared_minio.sh --update`
**Default Creds**: minioadmin / minioadmin
**Notes**: Change credentials in production

### 17 - SearXNG 🐳🌐🔄
**Script**: `17_deploy_shared_searxng.sh <secret>`
**Purpose**: Privacy-respecting meta search engine
**Port**: 8080
**Planned IP**: 10.0.5.105
**Domain**: searxng.valuechainhackers.xyz
**Update**: `bash 17_deploy_shared_searxng.sh --update`
**Notes**: Aggregates results from multiple search engines

### 18 - Langfuse 🐳🌐🔄
**Script**: `18_deploy_shared_langfuse.sh <postgres_host> <postgres_password>`
**Purpose**: LLM observability and tracing
**Port**: 3002
**Planned IP**: 10.0.5.106
**Domain**: langfuse.valuechainhackers.xyz
**Update**: `bash 18_deploy_shared_langfuse.sh --update`
**Requires**: PostgreSQL
**Features**: Prompt management, usage tracking, debugging

### 19 - Neo4j 🐳🌐🔄
**Script**: `19_deploy_shared_neo4j.sh <password>`
**Purpose**: Graph database for knowledge graphs
**Port**: 7474 (Browser), 7687 (Bolt)
**Planned IP**: 10.0.5.107
**Domain**: neo4j.valuechainhackers.xyz
**Update**: `bash 19_deploy_shared_neo4j.sh --update`
**User**: neo4j
**Notes**: Useful for relationship-based data

### 20 - Jupyter 🐳🌐🔄
**Script**: `20_deploy_shared_jupyter.sh`
**Purpose**: Data science notebooks
**Port**: 8888
**Planned IP**: 10.0.5.108
**Domain**: jupyter.valuechainhackers.xyz
**Update**: `bash 20_deploy_shared_jupyter.sh --update`
**Token**: Check logs: `docker logs jupyter-shared`
**Notes**: Supports Python, R, Julia

### 21 - n8n 🐳🌐🔄
**Script**: `21_deploy_shared_n8n.sh <postgres_host> <postgres_password>`
**Purpose**: Workflow automation (Zapier alternative)
**Port**: 5678
**Planned IP**: 10.0.5.109
**Domain**: n8n.valuechainhackers.xyz
**Update**: `bash 21_deploy_shared_n8n.sh --update`
**Requires**: PostgreSQL
**Features**: 400+ integrations, visual workflow builder

### 22 - Flowise 🐳🌐🔄
**Script**: `22_deploy_shared_flowise.sh <postgres_host> <postgres_password>`
**Purpose**: Visual AI workflow builder (LangChain UI)
**Port**: 3001
**Planned IP**: 10.0.5.110
**Domain**: flowise.valuechainhackers.xyz
**Update**: `bash 22_deploy_shared_flowise.sh --update`
**Requires**: PostgreSQL
**Features**: Drag-and-drop LLM chains, RAG flows

### 23 - Tika 🐳🔗🔄
**Script**: `23_deploy_shared_tika.sh`
**Purpose**: Text extraction from documents
**Port**: 9998
**Planned IP**: 10.0.5.111
**Domain**: tika.valuechainhackers.xyz
**Update**: `bash 23_deploy_shared_tika.sh --update`
**Formats**: PDF, Word, Excel, PowerPoint, images, etc.

### 24 - Docling 🐳🌐🔄
**Script**: `24_deploy_shared_docling.sh`
**Purpose**: Advanced document parsing
**Port**: 5001
**Planned IP**: 10.0.5.112
**Domain**: docling.valuechainhackers.xyz
**Update**: `bash 24_deploy_shared_docling.sh --update`
**Features**: Better than Tika for complex documents

### 25 - Whisper 🐳🔗🔄
**Script**: `25_deploy_shared_whisper.sh`
**Purpose**: Speech-to-text (standard)
**Port**: 9000
**Planned IP**: 10.0.5.113
**Domain**: whisper.valuechainhackers.xyz
**Update**: `bash 25_deploy_shared_whisper.sh --update`
**Model**: base (configurable)
**Notes**: Use script 44 for faster version

### 26 - LibreTranslate 🐳🌐🔄
**Script**: `26_deploy_shared_libretranslate.sh`
**Purpose**: Translation service
**Port**: 5000
**Planned IP**: 10.0.5.114
**Domain**: translate.valuechainhackers.xyz
**Update**: `bash 26_deploy_shared_libretranslate.sh --update`
**Languages**: 100+ languages supported

### 27 - MCPO 🐳🌐🔄
**Script**: `27_deploy_shared_mcpo.sh`
**Purpose**: Model Context Protocol to OpenAPI proxy
**Port**: 8765
**Planned IP**: 10.0.5.115
**Domain**: mcpo.valuechainhackers.xyz
**Update**: `bash 27_deploy_shared_mcpo.sh --update`
**Notes**: Converts MCP tools to REST APIs

---

## Enterprise Tools (8 scripts)

### 28 - Gitea 🐳🌐🔄
**Script**: `28_deploy_shared_gitea.sh <postgres_host> <postgres_password>`
**Purpose**: Git service (GitHub alternative)
**Port**: 3003 (Web), 2222 (SSH)
**Planned IP**: 10.0.5.120
**Domain**: git.valuechainhackers.xyz
**Update**: `bash 28_deploy_shared_gitea.sh --update`
**Requires**: PostgreSQL
**Features**: Repos, issues, PRs, CI/CD integration

### 29 - Monitoring Stack 🐳🌐🔄
**Script**: `29_deploy_shared_monitoring.sh`
**Purpose**: Complete monitoring (Prometheus + Grafana + Loki)
**Ports**: 9090 (Prometheus), 3004 (Grafana), 3100 (Loki)
**Planned IPs**: 10.0.5.121-123
**Domains**: prometheus/grafana/loki.valuechainhackers.xyz
**Update**: `bash 29_deploy_shared_monitoring.sh --update`
**Grafana Creds**: admin / admin (change on first login)

### 30 - BookStack 🐳🌐🔄
**Script**: `30_deploy_shared_bookstack.sh <postgres_host> <postgres_password>`
**Purpose**: Wiki and documentation platform
**Port**: 3005
**Planned IP**: 10.0.5.124
**Domain**: wiki.valuechainhackers.xyz
**Update**: `bash 30_deploy_shared_bookstack.sh --update`
**Requires**: PostgreSQL
**Default Creds**: admin@admin.com / password

### 31 - Metabase 🐳🌐🔄
**Script**: `31_deploy_shared_metabase.sh <postgres_host> <postgres_password>`
**Purpose**: Business intelligence and analytics
**Port**: 3006
**Planned IP**: 10.0.5.125
**Domain**: metabase.valuechainhackers.xyz
**Update**: `bash 31_deploy_shared_metabase.sh --update`
**Requires**: PostgreSQL
**Features**: Dashboards, SQL queries, visualizations

### 32 - Playwright 🐳🔗🔄
**Script**: `32_deploy_shared_playwright.sh`
**Purpose**: Browser automation API
**Port**: 3007
**Planned IP**: 10.0.5.126
**Domain**: playwright.valuechainhackers.xyz
**Update**: `bash 32_deploy_shared_playwright.sh --update`
**Use Cases**: Web scraping, testing, automation

### 33 - code-server 🐳🌐🔄
**Script**: `33_deploy_shared_code_server.sh`
**Purpose**: VS Code in the browser
**Port**: 8443
**Planned IP**: 10.0.5.127
**Domain**: code.valuechainhackers.xyz
**Update**: `bash 33_deploy_shared_code_server.sh --update`
**Password**: Check `/opt/code-server/.config/code-server/config.yaml`

### 34 - Portainer 🐳🌐🔄
**Script**: `34_deploy_shared_portainer.sh`
**Purpose**: Docker container management UI
**Port**: 9443 (HTTPS), 8000 (Edge agent)
**Planned IP**: 10.0.5.128
**Domain**: portainer.valuechainhackers.xyz
**Update**: `bash 34_deploy_shared_portainer.sh --update`
**Setup**: Create admin on first login

### 35 - Formbricks 🐳🌐🔄
**Script**: `35_deploy_shared_formbricks.sh <postgres_host> <postgres_password>`
**Purpose**: User feedback and surveys
**Port**: 3008
**Planned IP**: 10.0.5.129
**Domain**: formbricks.valuechainhackers.xyz
**Update**: `bash 35_deploy_shared_formbricks.sh --update`
**Requires**: PostgreSQL

---

## Communication & Business (6 scripts)

### 36 - Mailcow 🐳🌐🔄
**Script**: `36_deploy_shared_mailserver.sh <domain>`
**Purpose**: Full mail server (SMTP, IMAP, webmail)
**Ports**: 25, 587 (SMTP), 993 (IMAP), 80/443 (Web)
**Planned IP**: 10.0.5.140
**Domain**: mail.valuechainhackers.xyz
**Update**: `bash 36_deploy_shared_mailserver.sh --update`
**Default Creds**: admin / moohoo
**Notes**: Requires DNS configuration (MX, SPF, DKIM, DMARC)

### 37 - EspoCRM 🐳🌐🔄
**Script**: `37_deploy_shared_crm.sh <postgres_host> <postgres_password>`
**Purpose**: Customer relationship management
**Port**: 3009
**Planned IP**: 10.0.5.141
**Domain**: crm.valuechainhackers.xyz
**Update**: `bash 37_deploy_shared_crm.sh --update`
**Requires**: PostgreSQL
**Features**: Contacts, leads, opportunities, campaigns

### 38 - Matrix + Element 🐳🌐🔄
**Script**: `38_deploy_shared_matrix.sh <postgres_host> <postgres_password> <server_name>`
**Purpose**: Secure team chat (Slack alternative)
**Ports**: 8008 (Synapse), 3010 (Element)
**Planned IPs**: 10.0.5.142 (Synapse), 10.0.5.143 (Element)
**Domains**: matrix/element.valuechainhackers.xyz
**Update**: `bash 38_deploy_shared_matrix.sh --update`
**Requires**: PostgreSQL
**Create Admin**: `docker exec -it matrix-synapse register_new_matrix_user ...`

### 39 - Apache Superset 🐳🌐🔄
**Script**: `39_deploy_shared_superset.sh <postgres_host> <postgres_password> <redis_host> <redis_password>`
**Purpose**: Enterprise business intelligence
**Port**: 3011
**Planned IP**: 10.0.5.144
**Domain**: superset.valuechainhackers.xyz
**Update**: `bash 39_deploy_shared_superset.sh --update`
**Requires**: PostgreSQL, Redis
**Default Creds**: admin / admin

### 40 - DuckDB 🐳🔗🔄
**Script**: `40_deploy_shared_duckdb.sh`
**Purpose**: Analytical database with HTTP API
**Port**: 8089
**Planned IP**: 10.0.5.145
**Domain**: duckdb.valuechainhackers.xyz
**Update**: `bash 40_deploy_shared_duckdb.sh --update`
**API**: POST JSON with SQL queries

### 41 - Authentik 🐳🌐🔄
**Script**: `41_deploy_shared_authentik.sh <postgres_host> <postgres_password> <redis_host> <redis_password>`
**Purpose**: Single Sign-On and identity provider
**Port**: 9000 (HTTP), 9443 (HTTPS)
**Planned IP**: 10.0.5.146
**Domain**: auth.valuechainhackers.xyz
**Update**: `bash 41_deploy_shared_authentik.sh --update`
**Requires**: PostgreSQL, Redis
**Features**: OAuth2, OIDC, SAML, LDAP provider

---

## Image Generation & A/V (4 scripts)

### 42 - ComfyUI 🐳🌐🔄
**Script**: `42_deploy_shared_comfyui.sh`
**Purpose**: Node-based Stable Diffusion interface
**Port**: 8188
**Planned IP**: 10.0.5.160
**Domain**: comfyui.valuechainhackers.xyz
**Update**: `bash 42_deploy_shared_comfyui.sh --update`
**GPU**: Detected automatically
**Models**: Place in `/opt/comfyui/models/checkpoints/`

### 43 - AUTOMATIC1111 🐳🌐🔄
**Script**: `43_deploy_shared_automatic1111.sh`
**Purpose**: Classic Stable Diffusion WebUI
**Port**: 7860
**Planned IP**: 10.0.5.161
**Domain**: sd.valuechainhackers.xyz
**Update**: `bash 43_deploy_shared_automatic1111.sh --update`
**GPU**: Detected automatically
**Features**: img2img, inpainting, extensions

### 44 - faster-whisper 🐳🔗🔄
**Script**: `44_deploy_shared_faster_whisper.sh`
**Purpose**: Optimized speech-to-text (faster than script 25)
**Port**: 8000
**Planned IP**: 10.0.5.162
**Domain**: stt.valuechainhackers.xyz
**Update**: `bash 44_deploy_shared_faster_whisper.sh --update`
**GPU**: Uses large-v3 if available, base otherwise
**API**: OpenAI-compatible

### 45 - openedai-speech 🐳🔗🔄
**Script**: `45_deploy_shared_openedai_speech.sh`
**Purpose**: Fast text-to-speech with Piper/Coqui
**Port**: 8001
**Planned IP**: 10.0.5.163
**Domain**: tts.valuechainhackers.xyz
**Update**: `bash 45_deploy_shared_openedai_speech.sh --update`
**API**: OpenAI-compatible
**Voices**: OpenAI voice names + Piper voices

---

## LLM Tools & Interfaces (3 scripts)

### 46 - ChainForge 🐳🌐🔄
**Script**: `46_deploy_shared_chainforge.sh`
**Purpose**: Visual prompt engineering and LLM evaluation
**Port**: 8002
**Planned IP**: 10.0.5.180
**Domain**: chainforge.valuechainhackers.xyz
**Update**: `bash 46_deploy_shared_chainforge.sh --update`
**Features**: Flow programming, multi-model comparison, prompt testing

### 47 - big-AGI 🐳🌐🔄
**Script**: `47_deploy_shared_big_agi.sh`
**Purpose**: Advanced multi-model AI interface
**Port**: 3012
**Planned IP**: 10.0.5.181
**Domain**: bigagi.valuechainhackers.xyz
**Update**: `bash 47_deploy_shared_big_agi.sh --update`
**Features**: Beam search, personas, voice I/O, split view

### 48 - Kotaemon 🐳🌐🔄
**Script**: `48_deploy_shared_kotaemon.sh`
**Purpose**: RAG-focused document QA system
**Port**: 7860
**Planned IP**: 10.0.5.182
**Domain**: kotaemon.valuechainhackers.xyz
**Update**: `bash 48_deploy_shared_kotaemon.sh --update`
**Features**: Advanced document parsing, source citations, multi-document search

---

## Network Configuration (2 scripts)

### 50 - Layer 2 Network Setup 🔧
**Script**: `50_configure_layer2_network.sh <interface>`
**Purpose**: Configure Docker macvlan for Layer 2 bridge networking
**Usage**: `bash 50_configure_layer2_network.sh ens18`
**Creates**: `openwebui-macvlan` network
**Helper**: `/root/deploy_openwebui_layer2.sh`
**Use Case**: Production Open WebUI with DHCP IPs from physical network

### 51 - Pin Docker Version 🔧
**Script**: `51_pin_docker_version.sh [version]`
**Purpose**: Lock Docker to specific stable version
**Default**: 24.0.7
**Recommended**: 24.0.7, 23.0.6, 20.10.24
**Usage**: `bash 51_pin_docker_version.sh 24.0.7`
**Notes**: Prevents auto-updates that break Layer 2 networking

---

## Utilities (1 script)

### 99 - Docker Cleanup 🔧
**Script**: `99_cleanup_docker.sh [--aggressive]`
**Purpose**: Remove unused Docker resources to free disk space
**Usage**:
- `bash 99_cleanup_docker.sh` - Safe cleanup (stopped containers, dangling images)
- `bash 99_cleanup_docker.sh --aggressive` - Remove ALL unused images and volumes
**Notes**: Run when disk space is low

---

## Quick Reference

### By Category
- **Base**: 01, 02, 07
- **All-in-One**: 08
- **Cloud**: 09, 10
- **AI/ML**: 11-27 (17 services)
- **Enterprise**: 28-35 (8 services)
- **Communication**: 36-41 (6 services)
- **Image/A/V**: 42-45 (4 services)
- **LLM Tools**: 46-48 (3 services)
- **Network**: 50, 51
- **Utilities**: 99

### Update All Services
```bash
for i in {11..48}; do
  [ -f "${i}_deploy_shared_*.sh" ] && bash ${i}_deploy_shared_*.sh --update
done
```

### Common Patterns
- **PostgreSQL dependent**: 13, 18, 21, 22, 28, 30, 31, 35, 37, 38, 39, 41
- **Redis dependent**: 14, 39, 41
- **GPU accelerated**: 11, 42, 43, 44
- **OpenAI-compatible APIs**: 44, 45
- **Web UI included**: All except Ollama, Tika, Whisper, faster-whisper, openedai-speech, MCPO, Playwright, DuckDB

### Port Conflicts to Avoid
- 5000: LibreTranslate (26), Tika uses 9998 instead
- 7860: AUTOMATIC1111 (43) OR Kotaemon (48) - deploy only one or change port
- 9000: Whisper (25) OR Authentik (41) - different purposes, check deployment

---

## Maintenance Schedule

**Daily**: Check logs for errors
**Weekly**: Update critical services (11, 12, 13, 14)
**Monthly**: Update all services, clean up Docker
**Quarterly**: Review unused services, update documentation

**Monitoring**: Use scripts 29 (Prometheus+Grafana) and 18 (Langfuse for LLM tracking)
