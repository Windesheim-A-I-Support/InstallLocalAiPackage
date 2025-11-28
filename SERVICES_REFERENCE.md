# Services Reference

**Central Hub**: Open WebUI (connects to all services)

## Shared Services Infrastructure

| Service | Host | Port | URL | Purpose |
|---------|------|------|-----|---------|
| **AI/ML Core** |
| Ollama | 10.0.5.24 | 11434 | http://10.0.5.24:11434 | LLM inference |
| Pipelines | 10.0.5.24 | 9099 | http://10.0.5.24:9099 | Open WebUI plugin framework |
| **Vector & Search** |
| Qdrant | 10.0.5.24 | 6333 | http://10.0.5.24:6333 | Vector database for RAG |
| SearXNG | 10.0.5.24 | 8080 | http://10.0.5.24:8080 | Web search aggregator |
| **Databases** |
| PostgreSQL | 10.0.5.24 | 5432 | postgresql://10.0.5.24:5432 | Relational database |
| Redis | 10.0.5.24 | 6379 | redis://10.0.5.24:6379 | Cache & sessions |
| Neo4j | 10.0.5.24 | 7474/7687 | http://10.0.5.24:7474 | Graph database |
| **Storage** |
| MinIO | 10.0.5.24 | 9001 | http://10.0.5.24:9001 | S3-compatible object storage |
| Nextcloud | 10.0.5.26 | 80 | https://nextcloud.valuechainhackers.xyz | WebDAV file sync |
| **Workflow & Automation** |
| n8n | 10.0.5.24 | 5678 | http://10.0.5.24:5678 | Workflow automation |
| Flowise | 10.0.5.24 | 3001 | http://10.0.5.24:3001 | Visual AI workflow builder |
| **Document Processing** |
| Docling | 10.0.5.24 | 5001 | http://10.0.5.24:5001 | Document parsing |
| Tika | 10.0.5.24 | 9998 | http://10.0.5.24:9998 | Text extraction |
| **Speech & Translation** |
| Whisper | 10.0.5.24 | 9000 | http://10.0.5.24:9000 | Speech-to-text |
| LibreTranslate | 10.0.5.24 | 5000 | http://10.0.5.24:5000 | Translation |
| **Backend Services** |
| Supabase | 10.0.5.27 | 3000 | https://supabase.valuechainhackers.xyz | Backend-as-a-Service |
| MCPO | 10.0.5.24 | 8765 | http://10.0.5.24:8765 | MCP-to-OpenAPI proxy |
| **Development** |
| Jupyter | 10.0.5.24 | 8888 | http://10.0.5.24:8888 | Data science notebooks |
| code-server | 10.0.5.24 | 8443 | http://10.0.5.24:8443 | VS Code in browser |
| Gitea | 10.0.5.24 | 3003 | http://10.0.5.24:3003 | Git service |
| **Monitoring & Analytics** |
| Langfuse | 10.0.5.24 | 3002 | http://10.0.5.24:3002 | LLM observability |
| Prometheus | 10.0.5.24 | 9090 | http://10.0.5.24:9090 | Metrics collection |
| Grafana | 10.0.5.24 | 3004 | http://10.0.5.24:3004 | Metrics visualization |
| Loki | 10.0.5.24 | 3100 | http://10.0.5.24:3100 | Log aggregation |
| Metabase | 10.0.5.24 | 3006 | http://10.0.5.24:3006 | Business intelligence |
| **Documentation** |
| BookStack | 10.0.5.24 | 3005 | http://10.0.5.24:3005 | Wiki/documentation |
| **Feedback & Surveys** |
| Formbricks | 10.0.5.24 | 3008 | http://10.0.5.24:3008 | User feedback/surveys |
| **Browser Automation** |
| Playwright | 10.0.5.24 | 3007 | http://10.0.5.24:3007 | Browser automation API |
| **Container Management** |
| Portainer | 10.0.5.24 | 9443 | https://10.0.5.24:9443 | Docker UI |
| **Communication** |
| Mailcow | 10.0.5.24 | 25/587/993 | https://mail.valuechainhackers.xyz | Mail server (SMTP/IMAP) |
| Matrix/Element | 10.0.5.24 | 3010/8008 | http://10.0.5.24:3010 | Team chat |
| **CRM & Business** |
| EspoCRM | 10.0.5.24 | 3009 | http://10.0.5.24:3009 | Customer relationship mgmt |
| Apache Superset | 10.0.5.24 | 3011 | http://10.0.5.24:3011 | Enterprise BI/analytics |
| **Additional Databases** |
| DuckDB | 10.0.5.24 | 8089 | http://10.0.5.24:8089 | Analytical database API |
| **Authentication** |
| Authentik | 10.0.5.24 | 9000 | http://10.0.5.24:9000 | SSO/OAuth2/SAML provider |
| **Image Generation** |
| ComfyUI | 10.0.5.24 | 8188 | http://10.0.5.24:8188 | Node-based Stable Diffusion |
| AUTOMATIC1111 | 10.0.5.24 | 7860 | http://10.0.5.24:7860 | Classic SD WebUI |
| **Enhanced Audio** |
| faster-whisper | 10.0.5.24 | 8000 | http://10.0.5.24:8000 | Optimized STT (faster) |
| openedai-speech | 10.0.5.24 | 8001 | http://10.0.5.24:8001 | Fast TTS (Piper/Coqui) |
| **LLM Tools** |
| ChainForge | 10.0.5.24 | 8002 | http://10.0.5.24:8002 | Prompt engineering & eval |
| big-AGI | 10.0.5.24 | 3012 | http://10.0.5.24:3012 | Advanced multi-model UI |
| Kotaemon | 10.0.5.24 | 7860 | http://10.0.5.24:7860 | RAG document QA system |

## Open WebUI Connection Variables

Configure these in each Open WebUI instance:

```bash
# AI/ML
OLLAMA_BASE_URL=http://10.0.5.24:11434
PIPELINES_URLS=["http://10.0.5.24:9099"]
PIPELINES_API_KEY=0p3n-w3bu!

# Vector Database
VECTOR_DB=qdrant
QDRANT_URI=http://10.0.5.24:6333

# Databases
DATABASE_URL=postgresql://dbadmin:PASSWORD@10.0.5.24:5432/openwebui
REDIS_URL=redis://10.0.5.24:6379/0

# Storage
S3_ENDPOINT_URL=http://10.0.5.24:9001
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET_NAME=openwebui

# Search
ENABLE_RAG_WEB_SEARCH=true
RAG_WEB_SEARCH_ENGINE=searxng
SEARXNG_QUERY_URL=http://10.0.5.24:8080/search?q=<query>

# Speech & Translation (Standard)
AUDIO_STT_ENGINE=openai-whisper
AUDIO_STT_OPENAI_WHISPER_API_BASE_URL=http://10.0.5.24:9000
AUDIO_TTS_ENGINE=openai
AUDIO_TTS_OPENAI_API_BASE_URL=http://10.0.5.24:11434/v1

# Speech & Translation (Enhanced - Faster/Better)
AUDIO_STT_ENGINE=openai
AUDIO_STT_OPENAI_API_BASE_URL=http://10.0.5.24:8000/v1
AUDIO_TTS_ENGINE=openai
AUDIO_TTS_OPENAI_API_BASE_URL=http://10.0.5.24:8001/v1

# Image Generation
AUTOMATIC1111_BASE_URL=http://10.0.5.24:7860
COMFYUI_BASE_URL=http://10.0.5.24:8188

# Document Processing
DOCS_DIR=/app/backend/data/docs
RAG_EMBEDDING_ENGINE=ollama

# Authentication
WEBUI_AUTH=true
WEBUI_SECRET_KEY=<generated>
ENABLE_SIGNUP=true
DEFAULT_USER_ROLE=user

# Integration Services
NEXTCLOUD_URL=https://nextcloud.valuechainhackers.xyz
N8N_WEBHOOK_URL=http://10.0.5.24:5678/webhook
LANGFUSE_PUBLIC_KEY=<from_langfuse>
LANGFUSE_SECRET_KEY=<from_langfuse>
LANGFUSE_HOST=http://10.0.5.24:3002
```

## Individual Services Requiring PostgreSQL

| Service | Database Name | Default User | Default Pass |
|---------|---------------|--------------|--------------|
| Langfuse | langfuse | dbadmin | See .env |
| Flowise | flowise | dbadmin | See .env |
| n8n | n8n | dbadmin | See .env |
| Gitea | gitea | dbadmin | See .env |
| BookStack | bookstack | dbadmin | See .env |
| Metabase | metabase | dbadmin | See .env |
| Formbricks | formbricks | dbadmin | See .env |

All databases are auto-created by deployment scripts.

## Secrets & Credentials

**Generated during deployment** (stored in service-specific .env files):
- WEBUI_SECRET_KEY
- REDIS_PASSWORD
- SEARXNG_SECRET
- PIPELINES_API_KEY
- NEXTAUTH_SECRET (multiple services)
- JWT secrets
- Database passwords

**Check deployment scripts for default credentials.**

## Service Categories

### Required for Open WebUI Core Functionality
- Ollama (LLM)
- Qdrant (RAG)
- PostgreSQL (data)
- Redis (cache)

### Enhanced AI Capabilities
- Pipelines (plugins)
- Whisper (STT)
- LibreTranslate (translation)
- SearXNG (web search)
- Docling/Tika (document parsing)

### Developer Tools
- Jupyter (data science)
- code-server (IDE)
- Gitea (version control)

### Operations & Monitoring
- Langfuse (LLM tracing)
- Prometheus + Grafana (metrics)
- Portainer (container mgmt)

### Business Tools
- n8n (automation)
- Metabase (analytics)
- BookStack (documentation)
- Formbricks (feedback)

### Integration & Backend
- Nextcloud (file storage)
- Supabase (backend)
- MinIO (object storage)
- MCPO (MCP bridge)
