# Local AI Stack - Proxmox Infrastructure
**Complete AI/LLM development environment on Debian 12 LXC containers**

## 📊 Current Status: 18/27 Working (67%)

**Working Services:** 18 | **Installing:** 2 (Langfuse, Flowise) | **Not Deployed:** 7

---

## 📁 Repository Structure

```
InstallLocalAiPackage/
├── README.md                    # This file
├── scripts/                     # All deployment scripts (90+ scripts)
│   ├── XX_deploy_shared_*.sh   # Service deployment scripts
│   ├── XX_configure_*.sh       # Configuration scripts
│   └── monitoring_*.sh         # Health check scripts
├── docs/                        # Documentation (14 files)
│   ├── CONTAINER_INVENTORY.md  # ⭐ Complete container listing
│   ├── CURRENT_STATUS.md       # ⭐ Quick status table
│   ├── TASKS_REMAINING.md      # ⭐ To-do list
│   ├── WORKING_SERVICES_CREDENTIALS.md  # ⭐ Login credentials
│   └── ...                     # Reference docs
├── logs/                        # Health check & monitoring logs
└── archive/                     # Old configs & historical files
```

---

## 🚀 Quick Start

### View Status
```bash
cat docs/CURRENT_STATUS.md              # Quick overview
cat docs/CONTAINER_INVENTORY.md         # Full details
cat docs/WORKING_SERVICES_CREDENTIALS.md  # Login info
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

# Check specific service logs
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

**Full inventory:** See [docs/CONTAINER_INVENTORY.md](docs/CONTAINER_INVENTORY.md)

---

## 📋 Available Deployment Scripts

### Ready to Deploy (Existing Containers)
```bash
scripts/38_deploy_shared_jupyter_native.sh    # JupyterLab → 124
scripts/34_deploy_shared_tika.sh              # Tika → 111
scripts/32_deploy_shared_gitea.sh             # Gitea → 120
```

### New Services (Need New Containers)
```bash
scripts/40_deploy_shared_elasticsearch_native.sh   # Elasticsearch → 127
scripts/39_deploy_shared_litellm_native.sh         # LiteLLM → 128
scripts/41_deploy_shared_unstructured_native.sh    # Unstructured → 129
scripts/43_deploy_shared_superset_native.sh        # Superset → 130
scripts/42_deploy_shared_haystack_native.sh        # Haystack → 131
scripts/44_deploy_shared_langgraph_native.sh       # LangGraph → 132
scripts/45_deploy_shared_graphrag_native.sh        # GraphRAG → 133
scripts/46_deploy_shared_plaso_native.sh           # Plaso → 135
scripts/47_deploy_shared_volatility3_native.sh     # Volatility3 → 138
```

**Full script list:** See [docs/NATIVE_SCRIPTS_SUMMARY.md](docs/NATIVE_SCRIPTS_SUMMARY.md)

---

## 🎯 Key Principles

1. **NO Docker on shared services (100-199)** - Native deployments only
2. **All services use systemd** - Consistent management
3. **Credentials in `/root/.credentials/`** - Centralized storage
4. **Health checks required** - All deployments must verify
5. **Traefik routing** - All external access through reverse proxy

**Details:** See [docs/ARCHITECTURE_RULES.md](docs/ARCHITECTURE_RULES.md)

---

## 📖 Documentation

| File | Purpose |
|---|---|
| [DOCUMENTATION_INDEX.md](docs/DOCUMENTATION_INDEX.md) | Navigation guide |
| [CONTAINER_INVENTORY.md](docs/CONTAINER_INVENTORY.md) | Complete container listing |
| [CURRENT_STATUS.md](docs/CURRENT_STATUS.md) | Service status table |
| [TASKS_REMAINING.md](docs/TASKS_REMAINING.md) | To-do list |
| [WORKING_SERVICES_CREDENTIALS.md](docs/WORKING_SERVICES_CREDENTIALS.md) | Login credentials |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System architecture |
| [HEALTH_CHECK_GUIDE.md](docs/HEALTH_CHECK_GUIDE.md) | How to verify services |

---

## 🔧 Common Tasks

### Deploy New Service
1. Check available containers: `cat docs/CONTAINER_INVENTORY.md`
2. Find script: `ls scripts/*deploy*`
3. Run: `bash scripts/XX_deploy_shared_SERVICE_native.sh`
4. Update status: Edit `docs/CURRENT_STATUS.md`

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

See [docs/TASKS_REMAINING.md](docs/TASKS_REMAINING.md) for current priorities.

**Immediate:**
1. Complete Langfuse & Flowise installations
2. Deploy JupyterLab to container 124
3. Deploy Tika & Gitea

**Planned:**
- Elasticsearch, LiteLLM, Unstructured.io, Superset
- Advanced RAG: Haystack, LangGraph, GraphRAG
- Forensics: Plaso, Volatility3

---

**Total Scripts:** 76 deployment scripts
**Total Containers:** 27 (18 working, 2 installing, 7 pending)
**Documentation:** 14 essential files
**Last Updated:** 2025-12-31
