# Scaling Architecture Guide

## Overview

This architecture separates **shared services** (native installs) from **individual instances** (Docker), allowing rapid scaling of Open WebUI instances.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              Shared Services (Native)               │
├─────────────────────────────────────────────────────┤
│  Server 1 (10.0.5.x):                              │
│    - Ollama (11434) - LLM inference                │
│    - Qdrant (6333) - Vector DB                     │
│    - PostgreSQL (5432) - Shared DB                 │
│    - Redis (6379) - Cache                          │
└─────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼───────┐  ┌─────▼─────┐  ┌───────▼───────┐
│ Open WebUI 1  │  │ WebUI 2   │  │ WebUI 3       │
│ (3000)        │  │ (3001)    │  │ (3002)        │
│ Docker        │  │ Docker    │  │ Docker        │
└───────────────┘  └───────────┘  └───────────────┘
```

## Deployment Steps

### 1. Deploy Shared Services (Once)

On a dedicated server (e.g., 10.0.5.24):

```bash
# Ollama (LLM models)
bash 11_deploy_shared_ollama.sh

# Qdrant (vector DB for RAG)
bash 12_deploy_shared_qdrant.sh

# PostgreSQL (shared database)
bash 13_deploy_shared_postgres.sh

# Redis (caching)
bash 14_deploy_shared_redis.sh
```

**Note credentials from output!**

### 2. Deploy Open WebUI Instances (As Needed)

On same or different servers:

```bash
# Instance 1
bash 15_deploy_openwebui_instance.sh webui1 3000 \
  http://10.0.5.24:11434 \
  http://10.0.5.24:6333 \
  redis://:PASSWORD@10.0.5.24:6379/0

# Instance 2
bash 15_deploy_openwebui_instance.sh webui2 3001 \
  http://10.0.5.24:11434 \
  http://10.0.5.24:6333 \
  redis://:PASSWORD@10.0.5.24:6379/0

# Instance 3...
```

## Benefits

**Scalability:**
- Add new Open WebUI instances in seconds
- Share expensive resources (LLM models, vectors)
- Each instance isolated (users, data, configs)

**Resource Efficiency:**
- Ollama models loaded once, shared by all
- Vector embeddings shared across instances
- Centralized caching reduces redundancy

**Maintenance:**
- Update Ollama once, affects all instances
- Shared DB for analytics/monitoring
- Native installs = easier updates (apt/systemd)

**Cost:**
- 1x Ollama server vs N containers
- 1x Qdrant vs N instances
- Reduced memory/CPU footprint

## Updates

### Update Shared Services

**Ollama:**
```bash
systemctl stop ollama
curl -fsSL https://ollama.com/install.sh | sh
systemctl start ollama
```

**Qdrant:**
```bash
systemctl stop qdrant
wget https://github.com/qdrant/qdrant/releases/download/vX.Y.Z/qdrant-x86_64-unknown-linux-musl.tar.gz
tar xzf qdrant-x86_64-unknown-linux-musl.tar.gz
mv qdrant /usr/local/bin/
systemctl start qdrant
```

**PostgreSQL:**
```bash
apt update && apt upgrade postgresql-15
```

**Redis:**
```bash
apt update && apt upgrade redis-server
```

### Update Open WebUI Instance

```bash
cd /opt/open-webui-INSTANCE
docker compose pull
docker compose up -d
```

## Monitoring

Check shared services:
```bash
# Ollama
curl http://10.0.5.24:11434/api/tags

# Qdrant
curl http://10.0.5.24:6333/collections

# PostgreSQL
psql -h 10.0.5.24 -U dbadmin -d shared -c "\l"

# Redis
redis-cli -h 10.0.5.24 -a PASSWORD ping
```

## Example: Deploy 5 Instances

```bash
# Shared services (once)
bash 11_deploy_shared_ollama.sh
bash 12_deploy_shared_qdrant.sh
bash 13_deploy_shared_postgres.sh
bash 14_deploy_shared_redis.sh

# Get passwords from output, then:
OLLAMA=http://10.0.5.24:11434
QDRANT=http://10.0.5.24:6333
REDIS=redis://:PASSWORD@10.0.5.24:6379/0

# Deploy 5 instances
for i in {1..5}; do
  bash 15_deploy_openwebui_instance.sh webui$i 300$i $OLLAMA $QDRANT $REDIS
done
```

Result: 5 independent Open WebUI instances sharing infrastructure!
