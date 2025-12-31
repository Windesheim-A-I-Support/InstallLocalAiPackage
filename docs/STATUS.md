# Infrastructure Status & Inventory

**Last Updated:** 2025-12-31
**Status:** 18/27 Working (67%)

---

## 📊 Quick Overview

| Category | Count | Status |
|---|---|---|
| **Total Containers** | 27 | 10.0.5.100-126 + 136 |
| ✅ **Working** | 18 | All core services operational |
| 🔧 **Installing** | 2 | Langfuse (106), Flowise (110) |
| 📋 **Not Deployed** | 7 | Ready to deploy |

---

## ✅ WORKING SERVICES (18)

| IP | Service | Port | Purpose |
|---|---|---|---|
| **Core Infrastructure** ||||
| 10.0.5.100 | Ollama | 11434 | LLM inference engine |
| 10.0.5.101 | Qdrant | 6333 | Vector database |
| 10.0.5.102 | PostgreSQL | 5432 | Relational database |
| 10.0.5.103 | Redis | 6379 | Cache |
| 10.0.5.104 | MinIO | 9001 | S3-compatible storage |
| **AI/LLM Services** ||||
| 10.0.5.105 | SearXNG | 8080 | Meta search (OSINT) |
| 10.0.5.107 | Neo4j | 7474 | Graph database |
| 10.0.5.109 | n8n | 5678 | Workflow automation |
| 10.0.5.112 | Docling | 5001 | Document conversion |
| 10.0.5.113 | Whisper | 9000 | Speech-to-text |
| 10.0.5.114 | LibreTranslate | 5000 | Translation |
| **Productivity** ||||
| 10.0.5.116 | BookStack | 3200 | Documentation wiki |
| 10.0.5.117 | Metabase | 3001 | BI analytics |
| 10.0.5.118 | Playwright | 3000 | Browser automation |
| **Monitoring** ||||
| 10.0.5.121 | Prometheus | 9090 | Metrics collection |
| 10.0.5.122 | Grafana | 3000 | Dashboards |
| 10.0.5.123 | Loki | 3100 | Log aggregation |
| **Pipelines** ||||
| 10.0.5.200 | Pipelines | 9099 | OpenWebUI integration |

---

## 🔧 INSTALLING (2)

| IP | Service | Port | Status | ETA |
|---|---|---|---|---|
| 10.0.5.106 | Langfuse | 3000 | pnpm installing | 30-60 min |
| 10.0.5.110 | Flowise | 3000 | npm installing | 30-60 min |

---

## 📋 NOT DEPLOYED (7 + 2 unclear)

| IP | Service | Port | Script | Status |
|---|---|---|---|---|
| 10.0.5.108 | JupyterInstance | 8888 | - | ❓ Purpose unclear |
| 10.0.5.111 | Tika | 9998 | `34_deploy_shared_tika.sh` | Ready |
| 10.0.5.115 | MCPO | 8080 | - | Skip (needs MCP servers) |
| 10.0.5.119 | Codeserver | 8080 | - | ❓ Purpose unclear |
| 10.0.5.120 | Gitea | 3000 | `32_deploy_shared_gitea.sh` | Ready |
| 10.0.5.124 | JupyterLab | 8888 | `38_deploy_shared_jupyter_native.sh` | ⭐ Ready |
| 10.0.5.125 | Formbricks | 3000 | - | Failed (npm error) |
| 10.0.5.126 | Mailserver | 25/587 | - | Needs script |
| 10.0.5.136 | Chainforge | ? | - | ❓ Purpose unclear |

---

## 🎯 RECOMMENDED NEW SERVICES

### High Priority (127-130)
| IP | Service | Port | CPU | RAM | Purpose |
|---|---|---|---|---|---|
| 127 | Elasticsearch | 9200 | 2 | 4GB | Full-text search |
| 128 | LiteLLM | 4000 | 1 | 2GB | LLM API gateway |
| 129 | Unstructured.io | 8000 | 2 | 3GB | Document preprocessing |
| 130 | Superset | 8088 | 2 | 4GB | Data visualization |

### Medium Priority (131-134)
| IP | Service | Port | CPU | RAM | Purpose |
|---|---|---|---|---|---|
| 131 | Airflow | 8080 | 2 | 4GB | Workflow orchestration |
| 132 | Haystack | 8000 | 2 | 3GB | RAG framework |
| 133 | LangGraph | 8000 | 2 | 3GB | Multi-agent workflows |
| 134 | MLflow | 5000 | 1 | 2GB | ML experiment tracking |

### Low Priority (135-138)
| IP | Service | Port | CPU | RAM | Purpose |
|---|---|---|---|---|---|
| 135 | Plaso | 5000 | 2 | 4GB | Forensic timelines |
| 137 | JupyterHub | 8000 | 2 | 4GB | Multi-user notebooks |
| 138 | Volatility3 | 8080 | 4 | 8GB | Memory forensics |

---

## 🔄 Integration Architecture

```
AI/LLM Stack:
  OpenWebUI (200) → Ollama (100) → Langfuse (106)
                 ↓
              Qdrant (101) ← Embeddings
                 ↓
              Flowise (110) → n8n (109) → Workflows

Data Processing:
  Documents → Docling (112) → LibreTranslate (114)
           ↓
        PostgreSQL (102) ← → Neo4j (107)
           ↓
        Qdrant (101)
           ↓
        RAG Queries

Monitoring:
  All Services → Prometheus (121) → Grafana (122)
              ↓
           Loki (123) ← Logs
```

---

## 📋 CURRENT TASKS

### ✅ Completed Today
- [x] Documentation consolidation (14 files → 3 files)
- [x] Repository restructuring (scripts/, docs/, logs/, archive/)
- [x] Created workforchris.md with 31 container specs

### 🔄 In Progress (Waiting)
- [ ] **Waiting for Chris:** Create Proxmox containers (see [workforchris.md](../workforchris.md))
- [ ] **Waiting for installs:** Langfuse (106) pnpm install running
- [ ] **Waiting for installs:** Flowise (110) npm install running

### 📋 Ready to Deploy (When Containers Created)
**Existing Containers:**
- [ ] Deploy JupyterLab to 124 (script ready: `scripts/38_deploy_shared_jupyter_native.sh`)
- [ ] Deploy Tika to 111 (script ready: `scripts/34_deploy_shared_tika.sh`)
- [ ] Deploy Gitea to 120 (script ready: `scripts/32_deploy_shared_gitea.sh`)

**New Containers (After Chris Creates Them):**
- [ ] Deploy Elasticsearch to 127 (script ready: `scripts/40_deploy_shared_elasticsearch_native.sh`)
- [ ] Deploy LiteLLM to 128 (script ready: `scripts/39_deploy_shared_litellm_native.sh`)
- [ ] Deploy Unstructured to 129 (script ready: `scripts/41_deploy_shared_unstructured_native.sh`)
- [ ] Deploy Superset to 130 (script ready: `scripts/43_deploy_shared_superset_native.sh`)
- [ ] Deploy Airflow to 131 (script ready: `scripts/42_deploy_shared_airflow_native.sh`)
- [ ] Deploy Haystack to 132 (script ready: `scripts/44_deploy_shared_haystack_native.sh`)
- [ ] Deploy LangGraph to 133 (script ready: `scripts/46_deploy_shared_langgraph_native.sh`)
- [ ] Deploy MLflow to 134 (script ready: `scripts/48_deploy_shared_mlflow_native.sh`)
- [ ] Deploy 20+ extra services if containers 139-158 created

### 🔜 After Installs Complete
- [ ] Finish Langfuse deployment (build → migrations → systemd)
- [ ] Finish Flowise deployment (systemd service)
- [ ] Verify both services working

### ❓ Clarifications Needed
- [ ] JupyterInstance (108) vs JupyterLab (124) - what's the difference?
- [ ] Codeserver (119) - deploy VS Code Server?
- [ ] Chainforge (136) - keep or repurpose?

---

## 🔍 Quick Health Check

```bash
# Check all working services
for ip in 100 101 104 105 107 109 112 113 114 116 117 118 121 122 123; do
  echo -n "10.0.5.$ip: "
  timeout 2 curl -s http://10.0.5.$ip 2>&1 | head -1
done

# Check specific service
ssh root@10.0.5.XXX "systemctl status <service>"
ssh root@10.0.5.XXX "journalctl -u <service> -f"

# Get credentials
cat /root/.credentials/<service>.txt
```

---

## 📊 Service Credentials

See [CREDENTIALS.md](CREDENTIALS.md) for all login information.

---

**Files:**
- This file: Current status & inventory
- [CREDENTIALS.md](CREDENTIALS.md): Login credentials
- [REFERENCE.md](REFERENCE.md): Architecture, rules, deployment guide
- [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md): Navigation (can be removed)
