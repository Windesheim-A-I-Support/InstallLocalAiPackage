# Complete Deployment Guide - Local AI Stack on Debian 12

## 📋 Overview

This guide will take you from a **completely blank Debian 12 LXC container** to a fully functional AI stack with:
- Open WebUI (Chat interface)
- Ollama (LLM inference)
- n8n (Workflow automation)
- Flowise (AI orchestration)
- Qdrant (Vector database)
- Supabase (Backend)
- Langfuse (Observability)
- Neo4j (Graph database)
- SearXNG (Search)
- MinIO (Object storage)

## 🚀 Quick Start (One Command)

If you want the complete automated deployment:

```bash
# As root on the blank Debian 12 container
bash 00_full_deployment.sh
```

This will run all steps automatically and take 15-30 minutes.

## 📝 Step-by-Step Deployment

If you prefer to run each step manually:

### Prerequisites
- Proxmox LXC container with Debian 12 (blank image)
- LXC features enabled: `nesting=1`, `keyctl=1`
- Root access to the container

---

### Step 1: Install System Dependencies

**Run as:** `root`

```bash
bash 01_system_dependencies.sh
```

**What it does:**
- Updates apt repositories
- Installs: `sudo`, `curl`, `ca-certificates`, `gnupg`, `git`, `python3`
- Takes ~2 minutes

---

### Step 2: Install Docker & Create User

**Run as:** `root`

```bash
bash 02_install_docker.sh ai-admin
```

**What it does:**
- Installs Docker Engine (official repository)
- Creates user `ai-admin` (no password, sudo access)
- Adds user to `docker` group
- Takes ~3 minutes

**⚠️ Important:** After this step, all remaining steps run as `ai-admin`, NOT root!

---

### Step 3: Clone Repository & Setup Environment

**Run as:** `ai-admin`

```bash
su - ai-admin
bash 03_clone_and_setup_env.sh
```

**What it does:**
- Clones https://github.com/coleam00/local-ai-packaged (stable branch)
- Copies `.env.example` to `.env`
- Generates ALL secrets (including ones missing from original script):
  - PostgreSQL password
  - JWT secrets
  - Neo4j password
  - Qdrant API key
  - Flowise credentials
  - MinIO passwords
  - And 10+ more
- Takes ~2 minutes

**Output:** Repository at `~/local-ai-packaged` with fully configured `.env` file

---

### Step 4: Configure Service Integrations

**Run as:** `ai-admin`

```bash
bash 04_configure_integrations.sh
```

**What it does:**
- Patches `docker-compose.override.private.yml` with integration settings:
  - Open WebUI → Qdrant (vector DB)
  - Open WebUI → Ollama (LLM)
  - n8n → External packages enabled
  - Flowise → Ollama, Qdrant
  - Ollama → Host binding for container access
- Creates backup: `docker-compose.override.private.yml.backup`
- Takes <1 minute

---

### Step 5: Deploy the Stack

**Run as:** `ai-admin`

```bash
bash 05_deploy_stack.sh cpu private
```

**What it does:**
- Runs `python3 start_services.py --profile cpu --environment private`
- Pulls all Docker images (~5 GB)
- Starts all containers
- Initializes databases
- Takes 5-10 minutes

**⚠️ CRITICAL:** Once this runs, you CANNOT change Supabase `.env` files (it's a known bug in the repo)

**Parameters:**
- `cpu` - Use CPU-only Ollama (alternatives: `gpu-nvidia`, `gpu-amd`, `none`)
- `private` - Internal network only (alternative: `public` for cloud)

**Verify deployment:**
```bash
docker ps
```

You should see 12+ containers running.

---

### Step 6: Generate Traefik Configuration (Optional)

**Run as:** `ai-admin`

```bash
bash 06_generate_traefik_config.sh
```

**What it does:**
- Prompts for:
  - Team name (e.g., `team1`)
  - Domain (e.g., `valuechainhackers.xyz`)
  - Host IP (e.g., `10.0.5.7`)
- Generates `traefik_<team>.yml` with routes for all services
- Takes <1 minute

**Next steps:**
1. Copy file to Traefik server: `scp traefik_team1.yml root@10.0.4.10:/opt/traefik-stack/dynamic/`
2. Add DNS records (see generated file for list)
3. Access services at `https://team1-chat.yourdomain.xyz`

---

## 🔧 Script Reference

| Script | Run As | Purpose | Time |
|--------|--------|---------|------|
| `00_full_deployment.sh` | root | Master script (runs all steps) | 15-30 min |
| `01_system_dependencies.sh` | root | Install system packages | 2 min |
| `02_install_docker.sh` | root | Install Docker, create user | 3 min |
| `03_clone_and_setup_env.sh` | ai-admin | Clone repo, generate secrets | 2 min |
| `04_configure_integrations.sh` | ai-admin | Patch override file | <1 min |
| `05_deploy_stack.sh` | ai-admin | Deploy the stack | 5-10 min |
| `06_generate_traefik_config.sh` | ai-admin | Generate Traefik config | <1 min |

---

## 🌐 Network Architecture

```
Internet (HTTPS)
    ↓
Traefik Reverse Proxy (10.0.4.10)
    ↓
LXC Container (10.0.5.7)
    ↓
Docker Network (172.18.x.x)
    ↓
Services:
  - Open WebUI (8080)
  - Ollama (11434)
  - n8n (5678)
  - Flowise (3001)
  - Supabase (8000)
  - Langfuse (3300)
  - Neo4j (7474, 7687)
  - Qdrant (6333)
  - PostgreSQL (5432)
  - SearXNG (8081)
  - MinIO (9011)
  - Clickhouse (8123)
```

---

## 🔐 Security Notes

### Generated Secrets
All secrets are cryptographically secure (using Python's `secrets` module):
- 32-byte hex values for encryption keys
- URL-safe random strings for passwords
- HMAC-SHA256 JWTs for Supabase

### User Permissions
- `ai-admin` user has:
  - Docker group access (can manage containers)
  - Passwordless sudo (for automation)
  - No password login (SSH key only recommended)

### Network Isolation
- Services communicate internally via Docker network
- External access only through Traefik (HTTPS with Let's Encrypt)
- Unprivileged LXC container (user namespace isolation)

---

## 🐛 Troubleshooting

### Script fails at Step 1
```bash
# Check internet connection
ping -c 3 8.8.8.8

# Check if running as root
whoami  # Should output: root
```

### Docker permission denied at Step 3
```bash
# Verify you're in docker group
groups | grep docker

# If not, log out and back in, or:
newgrp docker
```

### Containers not starting at Step 5
```bash
# Check logs
docker logs <container-name>

# Common issues:
# - Port conflict: docker ps -a (check if ports already in use)
# - Memory: free -h (ensure at least 4GB available)
```

### .env warnings about missing variables
These are expected if the original repo's `.env.example` doesn't include all variables. Script 03 adds them automatically.

---

## 📊 Resource Requirements

### Minimum
- **CPU:** 4 cores
- **RAM:** 8 GB
- **Disk:** 40 GB
- **Network:** 1 Gbps (for initial image pulls)

### Recommended
- **CPU:** 8+ cores
- **RAM:** 16 GB
- **Disk:** 100 GB SSD
- **Network:** 1+ Gbps

---

## 🔄 Post-Deployment

### Verify All Services
```bash
bash diagnose_stack.sh
```

### Check Container Status
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

### View Logs
```bash
docker logs -f open-webui
docker logs -f ollama
docker logs -f n8n
```

### Pull LLM Models
```bash
docker exec -it ollama ollama pull llama3
docker exec -it ollama ollama pull nomic-embed-text
```

---

## 📚 Service URLs (After Traefik Setup)

Assuming team name `team1` and domain `example.com`:

- **Open WebUI:** https://team1-chat.example.com
- **n8n:** https://team1-n8n.example.com
- **Flowise:** https://team1-flowise.example.com
- **Supabase:** https://team1-supabase.example.com
- **Langfuse:** https://team1-langfuse.example.com
- **Neo4j:** https://team1-neo4j.example.com
- **SearXNG:** https://team1-search.example.com
- **MinIO:** https://team1-minio.example.com

---

## 🎯 Next Steps After Deployment

1. **Access Open WebUI** and create your first account
2. **Pull LLM models** via Ollama
3. **Configure Pipelines in Open WebUI:**
   - Go to Admin Panel → Settings → Connections
   - Click "+" to add new OpenAI API connection
   - Enter:
     - Name: `Pipelines`
     - Base URL: `http://pipelines:9099`
     - API Key: `0p3n-w3bu!`
   - Click Save
   - This enables the pipelines plugin framework for Open WebUI
4. **Configure Flowise** with Qdrant and Ollama nodes
5. **Setup n8n workflows** connecting to Ollama
6. **Enable Langfuse tracing** in Open WebUI settings
7. **Create vector collections** in Qdrant for RAG

---

## 📞 Support

- **Repository Issues:** https://github.com/coleam00/local-ai-packaged/issues
- **Deployment Scripts:** Check logs in each script's output
- **Diagnostics:** Run `diagnose_stack.sh` for health checks

---

## 📄 License

These deployment scripts are provided as-is for use with the local-ai-packaged repository.
