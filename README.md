# Local AI Stack Deployment

Complete enterprise AI infrastructure with **48 deployment scripts** for Debian 12.

## Infrastructure

**Traefik:** 10.0.4.10 → `/opt/traefik-stack/dynamic`

**Servers:**
- **10.0.5.24** - AI Stack - `ai-24.valuechainhackers.xyz`
- **10.0.5.26** - Nextcloud - `nextcloud.valuechainhackers.xyz`
- **10.0.5.27** - Supabase - `supabase.valuechainhackers.xyz`

## Architecture

**Shared Services** (1x deployment, N instances connect):
- 45+ services: Ollama, Qdrant, PostgreSQL, Redis, MinIO, etc.

**AI Interfaces** (3 options):
- **Open WebUI** - Production AI chat (script 08 or 15)
- **big-AGI** - Advanced multi-model interface (script 47)
- **ChainForge** - Prompt engineering & evaluation (script 46)

**Scalability:**
- Deploy shared services once
- Connect unlimited AI interface instances
- All interfaces can use the same backend services

## Quick Start

### All-in-One (Legacy - Simple)
```bash
bash 01_system_dependencies.sh
bash 02_install_docker.sh ai-admin
bash 08_minimal_ai_stack.sh ai-admin
```

### Scalable (Recommended - Production)
```bash
# 1. Base system
bash 01_system_dependencies.sh
bash 02_install_docker.sh ai-admin

# 2. Deploy core shared services (once)
bash 11_deploy_shared_ollama.sh
bash 12_deploy_shared_qdrant.sh
bash 13_deploy_shared_postgres.sh
bash 14_deploy_shared_redis.sh

# 3. Choose your AI interface(s)
bash 15_deploy_openwebui_instance.sh webui1 3000  # Production chat
bash 47_deploy_shared_big_agi.sh                   # Advanced features
bash 46_deploy_shared_chainforge.sh                # Prompt engineering

# 4. Optional: Image generation
bash 42_deploy_shared_comfyui.sh                   # Modern Stable Diffusion
# bash 43_deploy_shared_automatic1111.sh           # Classic SD WebUI

# 5. Optional: Enhanced audio
bash 44_deploy_shared_faster_whisper.sh            # Better STT
bash 45_deploy_shared_openedai_speech.sh           # Better TTS
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
- `47` big-AGI (advanced multi-model AI interface)

**AI Interfaces:**
- `08` All-in-one stack (legacy)
- `15` Open WebUI instance (scalable)
- `46` ChainForge (prompt engineering)
- `47` big-AGI (advanced multi-model)

**Cloud:**
- `09` Nextcloud `10` Supabase

**Utilities:**
- `99` Docker cleanup

**Update any service:** `bash script.sh --update`

## Post-Deployment

### Access Your AI Interfaces

**Open WebUI:**
- URL: `https://ai-24.valuechainhackers.xyz` (or `http://10.0.5.24:3000`)
- Configure Pipelines: Admin Panel → Settings → Connections
  - Add: `http://pipelines:9099` / `0p3n-w3bu!`

**big-AGI:**
- URL: `http://10.0.5.24:3012`
- Configure Ollama: Models settings → Add endpoint `http://host.docker.internal:11434`

**ChainForge:**
- URL: `http://10.0.5.24:8002`
- Connect to Ollama at `http://10.0.5.24:11434`

### Pull Ollama Models

```bash
# For all-in-one stack
docker exec -it minimal-ai-ollama ollama pull qwen2.5:3b
docker exec -it minimal-ai-ollama ollama pull nomic-embed-text

# For native Ollama installation
ollama pull qwen2.5:3b
ollama pull nomic-embed-text
```

### Maintenance

**Update services:**
```bash
bash 11_deploy_shared_ollama.sh --update
bash 47_deploy_shared_big_agi.sh --update
# etc.
```

**Clean up disk space:**
```bash
bash 99_cleanup_docker.sh              # Safe cleanup
bash 99_cleanup_docker.sh --aggressive # Remove all unused images/volumes
```

## AI Interface Comparison

| Feature | Open WebUI | big-AGI | ChainForge |
|---------|------------|---------|------------|
| **Best For** | Production chat | Power users | Prompt engineering |
| **Multi-Model** | Switch models | Use simultaneously | Compare side-by-side |
| **RAG** | ✅ Built-in | ✅ Supported | ❌ |
| **Pipelines** | ✅ Plugin system | ❌ | ❌ |
| **Personas** | ⚠️ Basic | ✅ Advanced | ❌ |
| **Beam Search** | ❌ | ✅ | ✅ |
| **Flow Programming** | ❌ | ❌ | ✅ Visual |
| **Voice I/O** | ✅ | ✅ | ❌ |
| **Image Gen** | ✅ Via pipelines | ⚠️ Limited | ❌ |
| **Evaluation** | ❌ | ⚠️ Basic | ✅ Advanced |
| **Deployment** | Multiple instances | Single shared | Single shared |

## Documentation

- **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** - 📊 Complete infrastructure overview
- **[SERVICES_REFERENCE.md](SERVICES_REFERENCE.md)** - 🔗 Service inventory & connection URLs
- **[AUTHENTICATION_STRATEGY.md](AUTHENTICATION_STRATEGY.md)** - 🔐 Auth & SSO strategy
- [SCALING_GUIDE.md](SCALING_GUIDE.md) - Architecture patterns
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Step-by-step instructions
- [ENV-REFERENCE.md](ENV-REFERENCE.md) - Environment variables

## Service Count

- **48 deployment scripts** (01-47, 99)
- **45+ services** available
- **3 AI interfaces** to choose from
- **All support `--update` flag**
