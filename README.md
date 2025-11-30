# Local AI Stack Deployment

Complete enterprise AI infrastructure with **51 deployment scripts** for Debian 12.

## Infrastructure

### Traefik Reverse Proxy (10.0.4.10)

**All services route through Traefik** for SSL/TLS certificates and domain routing.

**Configuration:**
- Server: `10.0.4.10`
- Dynamic configs: `/opt/traefik-stack/dynamic`
- File naming: `205{last_octet}.yml` (e.g., 10.0.5.100 → `205100.yml`)
- SSL/TLS: Automatic via Let's Encrypt
- Configure all services: `bash 53_configure_traefik_routing.sh`

**Example routing:**
- `ollama.valuechainhackers.xyz` → `10.0.5.100:11434`
- `qdrant.valuechainhackers.xyz` → `10.0.5.101:6333`
- `grafana.valuechainhackers.xyz` → `10.0.5.122:3000`

**Servers:**
- **10.0.5.24** - AI Stack - `ai-24.valuechainhackers.xyz`
- **10.0.5.26** - Nextcloud - `nextcloud.valuechainhackers.xyz`
- **10.0.5.27** - Supabase - `supabase.valuechainhackers.xyz`

## Architecture

**⚠️ Important**: Services are deployed on DEDICATED IPs (10.0.5.100+), not all on 10.0.5.24! See [IP_ALLOCATION.md](IP_ALLOCATION.md)

**Shared Infrastructure** (Deploy ONCE on 10.0.5.100-146):
- ~30 truly shareable services: Ollama, Qdrant, PostgreSQL, Redis, MinIO, Gitea, etc.
- One instance serves ALL users/teams
- See [SHARED_SERVICES_LIMITATIONS.md](SHARED_SERVICES_LIMITATIONS.md)

**Per-User/Team Services** (Deploy MULTIPLE on 10.0.5.200+):
- AI Interfaces: Open WebUI, big-AGI, ChainForge, Kotaemon
- Workflows: n8n (⚠️ free = 1 user), Flowise, Jupyter, code-server
- Each user/team gets their own instance

**Scalability:**
- Shared services: Deploy once, connect from anywhere
- Per-user services: Unlimited instances as needed
- 10.0.5.24 is LEGACY deployment, new services go on dedicated IPs

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
bash 48_deploy_shared_kotaemon.sh                  # Document QA

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
- `48` Kotaemon (RAG document QA system)

**AI Interfaces:**
- `08` All-in-one stack (legacy)
- `15` Open WebUI instance (scalable)
- `46` ChainForge (prompt engineering)
- `47` big-AGI (advanced multi-model)
- `48` Kotaemon (document QA)

**Cloud:**
- `09` Nextcloud `10` Supabase

**Network Configuration:**
- `50` Layer 2 network setup
- `51` Pin Docker version

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
- Ollama auto-configured (uses `host.docker.internal:11434`)

**ChainForge:**
- URL: `http://10.0.5.24:8002`
- Ollama auto-configured (uses `host.docker.internal:11434`)

**Kotaemon:**
- URL: `http://10.0.5.24:7860`
- Ollama auto-configured (uses `host.docker.internal:11434`)
- Upload documents and ask questions with RAG

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

| Feature | Open WebUI | big-AGI | ChainForge | Kotaemon |
|---------|------------|---------|------------|----------|
| **Best For** | Production chat | Power users | Prompt engineering | Document QA |
| **Multi-Model** | Switch models | Use simultaneously | Compare side-by-side | Switch models |
| **RAG** | ✅ Built-in | ✅ Supported | ❌ | ✅ Primary focus |
| **Document Upload** | ✅ | ⚠️ Limited | ❌ | ✅ Advanced |
| **Pipelines** | ✅ Plugin system | ❌ | ❌ | ❌ |
| **Personas** | ⚠️ Basic | ✅ Advanced | ❌ | ❌ |
| **Beam Search** | ❌ | ✅ | ✅ | ❌ |
| **Flow Programming** | ❌ | ❌ | ✅ Visual | ❌ |
| **Voice I/O** | ✅ | ✅ | ❌ | ❌ |
| **Image Gen** | ✅ Via pipelines | ⚠️ Limited | ❌ | ❌ |
| **Evaluation** | ❌ | ⚠️ Basic | ✅ Advanced | ❌ |
| **Citations** | ⚠️ Basic | ❌ | ❌ | ✅ Advanced |
| **Deployment** | Multiple instances | Single shared | Single shared | Single shared |

## Documentation

- **[SERVICE_CATALOG.md](SERVICE_CATALOG.md)** - 📖 Detailed catalog of all 51 scripts (ports, updates, features)
- **[SHARED_SERVICES_LIMITATIONS.md](SHARED_SERVICES_LIMITATIONS.md)** - ⚠️ **Which services to share vs deploy per-user**
- **[IP_ALLOCATION.md](IP_ALLOCATION.md)** - 🌐 Network architecture & dedicated IP assignments
- **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** - 📊 Complete infrastructure overview
- **[SERVICES_REFERENCE.md](SERVICES_REFERENCE.md)** - 🔗 Service inventory & connection URLs
- **[AUTHENTICATION_STRATEGY.md](AUTHENTICATION_STRATEGY.md)** - 🔐 Auth & SSO strategy
- [SCALING_GUIDE.md](SCALING_GUIDE.md) - Architecture patterns
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Step-by-step instructions
- [ENV-REFERENCE.md](ENV-REFERENCE.md) - Environment variables

## Service Count

- **51 deployment scripts** (01-48, 50-51, 99)
- **~30 truly shareable services** (deploy once on 10.0.5.100-146)
- **~21 per-user/team services** (deploy multiple on 10.0.5.200+)
- **4 AI interface options**
- **All support `--update` flag**

**⚠️ Critical**: Read [SHARED_SERVICES_LIMITATIONS.md](SHARED_SERVICES_LIMITATIONS.md) before deploying!

## Layer 2 Networking (Advanced)

For production deployments where Open WebUI instances need Layer 2 bridge networking:

```bash
# 1. Pin Docker to stable version (prevents breaking changes)
bash 51_pin_docker_version.sh 24.0.7

# 2. Configure Layer 2 macvlan network
bash 50_configure_layer2_network.sh ens18

# 3. Deploy Open WebUI on Layer 2 (gets IP from DHCP)
bash /root/deploy_openwebui_layer2.sh webui1 10.0.5.200
bash /root/deploy_openwebui_layer2.sh webui2 10.0.5.201
```

**Benefits:**
- Containers get IPs from physical network DHCP
- Avoids Docker networking issues
- Stable with older Docker versions
- Direct Layer 2 connectivity

See [IP_ALLOCATION.md](IP_ALLOCATION.md) for recommended IP ranges.
