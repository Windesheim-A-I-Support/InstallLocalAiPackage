# Local AI Stack - Proxmox Infrastructure
**Complete AI/LLM development environment on Debian 12 LXC containers**

## 📊 Current Status: 18/27 Working (67%)

**Working Services:** 18 | **Installing:** 2 (Langfuse, Flowise) | **Not Deployed:** 7

---

## 📁 Repository Structure

```
InstallLocalAiPackage/
├── README.md                    # This file
├── scripts/                     # 91 deployment scripts
│   ├── XX_deploy_shared_*.sh   # Service deployments
│   ├── XX_configure_*.sh       # Configurations
│   └── monitoring_*.sh         # Health checks
├── docs/                        # 3 files only!
│   ├── STATUS.md               # ⭐ Status, inventory, tasks
│   ├── CREDENTIALS.md          # ⭐ Login credentials
│   └── REFERENCE.md            # ⭐ Architecture & deployment guide
├── logs/                        # Health check logs
└── archive/                     # Old configs
```

---

## 🚀 Quick Start

### View Status
```bash
cat docs/STATUS.md          # Everything: status, inventory, tasks
cat docs/CREDENTIALS.md     # Login credentials
cat docs/REFERENCE.md       # Architecture & deployment guide
```

### Deploy a Service
```bash
# Example: Deploy JupyterLab to container 124
bash scripts/38_deploy_shared_jupyter_native.sh

# Example: Deploy Elasticsearch to new container 127
bash scripts/40_deploy_shared_elasticsearch_native.sh
```

### Check Service Health
```bash
# Quick check all working services
for ip in 100 101 104 105 107 109 112 113 114 116 117 118 121 122 123; do
  echo -n "10.0.5.$ip: "
  timeout 2 curl -s http://10.0.5.$ip 2>&1 | head -1
done

# Check specific service
ssh root@10.0.5.XXX "journalctl -u <service> -f"
```

---

## 🏗️ Infrastructure Overview

### Network Architecture
- **Shared Services:** 10.0.5.100-199 (Native deployments, NO Docker)
- **User Containers:** 10.0.5.200-249 (Docker allowed)
- **Traefik Proxy:** 10.0.4.10 (SSL/TLS routing)

### Core Services (Always Running)
| Service | IP | Port | Purpose |
|---|---|---|---|
| Ollama | 10.0.5.100 | 11434 | LLM inference |
| Qdrant | 10.0.5.101 | 6333 | Vector database |
| PostgreSQL | 10.0.5.102 | 5432 | Relational database |
| Redis | 10.0.5.103 | 6379 | Cache |
| MinIO | 10.0.5.104 | 9001 | Object storage |
| Neo4j | 10.0.5.107 | 7474 | Graph database |

### AI/LLM Services
| Service | IP | Port | Status |
|---|---|---|---|
| Langfuse | 10.0.5.106 | 3000 | 🔧 Installing |
| Flowise | 10.0.5.110 | 3000 | 🔧 Installing |
| n8n | 10.0.5.109 | 5678 | ✅ Working |
| SearXNG | 10.0.5.105 | 8080 | ✅ Working |
| Docling | 10.0.5.112 | 5001 | ✅ Working |
| LibreTranslate | 10.0.5.114 | 5000 | ✅ Working |
| Whisper | 10.0.5.113 | 9000 | ✅ Working |

### Monitoring Stack
| Service | IP | Port |
|---|---|---|
| Prometheus | 10.0.5.121 | 9090 |
| Grafana | 10.0.5.122 | 3000 |
| Loki | 10.0.5.123 | 3100 |

**Full inventory:** See [docs/STATUS.md](docs/STATUS.md)

---

## 🎯 Key Principles

1. **NO Docker on shared services (100-199)** - Native deployments only
2. **All services use systemd** - Consistent management
3. **Credentials in `/root/.credentials/`** - Centralized storage
4. **Health checks required** - All deployments must verify
5. **Traefik routing** - All external access through reverse proxy

**Details:** See [docs/REFERENCE.md](docs/REFERENCE.md)

---

## 📖 Documentation (3 Files Only!)

| File | Purpose |
|---|---|
| [STATUS.md](docs/STATUS.md) | **Current status, inventory, tasks** - Everything you need |
| [CREDENTIALS.md](docs/CREDENTIALS.md) | **Login credentials** - All service logins |
| [REFERENCE.md](docs/REFERENCE.md) | **Architecture, rules, deployment** - Complete reference |

---

## 🔧 Common Tasks

### Deploy New Service
1. Check available containers: `cat docs/STATUS.md`
2. Find script: `ls scripts/*deploy*` or see `docs/REFERENCE.md`
3. Run: `bash scripts/XX_deploy_shared_SERVICE_native.sh`
4. Update status: Edit `docs/STATUS.md`

### Troubleshoot Service
```bash
# Check logs
ssh root@10.0.5.XXX "journalctl -u <service> -f"

# Check status
ssh root@10.0.5.XXX "systemctl status <service>"

# Get credentials
cat /root/.credentials/<service>.txt
```

### Update Service
```bash
# Most scripts support --update flag
bash scripts/XX_deploy_shared_SERVICE_native.sh --update
```

---

## 🎯 Next Steps

See [docs/STATUS.md](docs/STATUS.md) → "CURRENT TASKS" for priorities.

**Immediate:**
1. Complete Langfuse & Flowise installations
2. Deploy JupyterLab to container 124
3. Deploy Tika & Gitea

**Planned:**
- Elasticsearch, LiteLLM, Unstructured.io, Superset
- Advanced RAG: Haystack, LangGraph, GraphRAG
- Forensics: Plaso, Volatility3

---

**Total Scripts:** 91 deployment scripts
**Total Containers:** 27 (18 working, 2 installing, 7 pending)
**Documentation:** 3 files only!
**Last Updated:** 2025-12-31
