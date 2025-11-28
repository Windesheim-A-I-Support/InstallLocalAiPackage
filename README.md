# Local AI Stack Deployment

Minimal AI stack deployment scripts for Debian 12 with Docker.

## Infrastructure

**Traefik Proxy:** 10.0.4.10 (Dynamic configs in `/opt/traefik-stack/dynamic`)

**Deployed Servers:**
- **10.0.5.24** - AI Stack - `ai-24.valuechainhackers.xyz`
- **10.0.5.26** - Nextcloud - `nextcloud.valuechainhackers.xyz`
- **10.0.5.27** - Supabase - `supabase.valuechainhackers.xyz`

## Quick Start

```bash
# 1. Install dependencies
bash 01_system_dependencies.sh

# 2. Install Docker (creates ai-admin user)
bash 02_install_docker.sh ai-admin

# 3. Deploy minimal AI stack
bash 08_minimal_ai_stack.sh ai-admin
```

## Services (10.0.5.24)

Access via `https://ai-24.valuechainhackers.xyz`:
- Open WebUI (port 3000)
- Ollama (port 11434)
- Qdrant (port 6333)
- Neo4j (port 7474, 7687)
- Jupyter (port 8888)
- Langfuse (port 3001)
- N8N (port 5678)
- Pipelines (port 9099)

**Post-deployment:**
1. Configure Pipelines in Open WebUI Admin Panel → Settings → Connections
   - URL: `http://pipelines:9099`
   - Key: `0p3n-w3bu!`
2. Pull models: `docker exec -it minimal-ai-ollama ollama pull qwen2.5:3b`
3. Pull embeddings: `docker exec -it minimal-ai-ollama ollama pull nomic-embed-text`

## Shared Services

**Nextcloud (10.0.5.26):**
- URL: https://nextcloud.valuechainhackers.xyz
- Admin: admin / Nextcloudbaby100!
- Native: Apache + MariaDB + Redis
- Update: `sudo -u www-data php /var/www/nextcloud/updater/updater.phar`

**Supabase (10.0.5.27):**
- URL: https://supabase.valuechainhackers.xyz
- DB: PostgreSQL 15 + PostgREST + pgvector
- Native install
- Update: `bash update_shared_services.sh`

## Scripts

- `01_system_dependencies.sh` - Install base packages
- `02_install_docker.sh` - Install Docker, create user
- `07_enablessh.sh` - Enable SSH with password auth
- `08_minimal_ai_stack.sh` - Deploy AI stack
- `generate_env_secrets.sh` - Generate .env secrets

## Documentation

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Full deployment instructions
- [ENV-REFERENCE.md](ENV-REFERENCE.md) - Environment variables reference
