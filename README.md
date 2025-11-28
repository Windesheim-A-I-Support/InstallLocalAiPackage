# Local AI Stack Deployment

Scalable AI infrastructure deployment for Debian 12.

## Infrastructure

**Traefik:** 10.0.4.10 → `/opt/traefik-stack/dynamic`

**Servers:**
- **10.0.5.24** - AI Stack - `ai-24.valuechainhackers.xyz`
- **10.0.5.26** - Nextcloud - `nextcloud.valuechainhackers.xyz`
- **10.0.5.27** - Supabase - `supabase.valuechainhackers.xyz`

## Architecture

**Shared Services** (1x deployment, N instances connect):
- Ollama, Qdrant, PostgreSQL, Redis, MinIO, etc.

**Open WebUI Instances** (Docker, scales horizontally):
- Each instance connects to shared services
- Deploy unlimited instances

## Quick Start

### All-in-One (Legacy)
```bash
bash 01_system_dependencies.sh
bash 02_install_docker.sh ai-admin
bash 08_minimal_ai_stack.sh ai-admin
```

### Scalable (Recommended)
```bash
# 1. Deploy shared services (once)
bash 11_deploy_shared_ollama.sh
bash 12_deploy_shared_qdrant.sh
bash 13_deploy_shared_postgres.sh
bash 14_deploy_shared_redis.sh

# 2. Deploy Open WebUI instances (as needed)
bash 15_deploy_openwebui_instance.sh webui1 3000
bash 15_deploy_openwebui_instance.sh webui2 3001
```

## Deployment Scripts

**Base:**
- `01_system_dependencies.sh` `02_install_docker.sh` `07_enablessh.sh`

**Shared Services (AI/ML):**
- `11` Ollama `12` Qdrant `13` PostgreSQL `14` Redis
- `16` MinIO `17` SearXNG `18` Langfuse `19` Neo4j
- `20` Jupyter `21` N8N `22` Flowise
- `23` Tika `24` Docling `25` Whisper
- `26` LibreTranslate `27` MCPO

**Shared Services (Enterprise):**
- `28` Gitea `29` Monitoring (Prometheus+Grafana+Loki)
- `30` BookStack `31` Metabase `32` Playwright
- `33` code-server `34` Portainer `35` Formbricks

**Shared Services (Communication & Auth):**
- `36` Mailcow `37` EspoCRM `38` Matrix+Element
- `39` Apache Superset `40` DuckDB `41` Authentik

**Shared Services (Image Generation & A/V):**
- `42` ComfyUI `43` AUTOMATIC1111
- `44` faster-whisper `45` openedai-speech

**Shared Services (LLM Tools):**
- `46` ChainForge (prompt engineering & LLM evaluation)

**Instances:**
- `15_deploy_openwebui_instance.sh` - Deploy WebUI

**Cloud:**
- `09_deploy_nextcloud.sh` `10_deploy_supabase.sh`

**Update:** `bash script.sh --update`

## Post-Deployment

Configure Pipelines in Open WebUI:
1. Admin Panel → Settings → Connections
2. Add: `http://pipelines:9099` / `0p3n-w3bu!`

Pull models:
```bash
docker exec -it minimal-ai-ollama ollama pull qwen2.5:3b
docker exec -it minimal-ai-ollama ollama pull nomic-embed-text
```

## Documentation

- [SERVICES_REFERENCE.md](SERVICES_REFERENCE.md) - Complete service inventory & connection URLs
- [AUTHENTICATION_STRATEGY.md](AUTHENTICATION_STRATEGY.md) - Auth & SSO strategy
- [SCALING_GUIDE.md](SCALING_GUIDE.md) - Architecture guide
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Full instructions
- [ENV-REFERENCE.md](ENV-REFERENCE.md) - Environment variables
