# Container Inventory - Proxmox LXC Containers
**Last Updated:** 2025-12-31

## 📊 Overview: 18/27 Working (67%)

**Total Containers:** 27 (10.0.5.100-126 + 136)
- ✅ **Working:** 18 services
- 🔧 **Installing:** 2 services (Langfuse, Flowise)
- 📋 **Not Deployed:** 7 services

---

## ✅ DEPLOYED & WORKING (18 services)

| IP | Proxmox Name | Service | Port | Status | Notes |
|---|---|---|---|---|---|
| 10.0.5.100 | Ollama | LLM Engine | 11434 | ✅ Working | Llama models |
| 10.0.5.101 | qdrant | Vector DB | 6333 | ✅ Working | Embeddings storage |
| 10.0.5.102 | PostGres | Database | 5432 | ✅ Working | Shared PostgreSQL |
| 10.0.5.103 | Redis | Cache | 6379 | ✅ Working | Shared cache |
| 10.0.5.104 | Minio | Object Storage | 9001 | ✅ Working | S3-compatible storage |
| 10.0.5.105 | Seargxn | Meta Search | 8080 | ✅ Working | **FIXED** - OSINT search |
| 10.0.5.107 | Neo4j | Graph DB | 7474 | ✅ Working | Knowledge graphs |
| 10.0.5.109 | N8n | Workflow | 5678 | ✅ Working | Automation |
| 10.0.5.112 | Docling | Document AI | 5001 | ✅ Working | Document conversion |
| 10.0.5.113 | whisper | Speech-to-Text | 9000 | ✅ Working | Audio transcription |
| 10.0.5.114 | Libretranslate | Translation | 5000 | ✅ Working | **FIXED** - Text translation |
| 10.0.5.116 | BookStack | Wiki/Docs | 3200 | ✅ Working | **FIXED** - Documentation |
| 10.0.5.117 | Metabase | BI Analytics | 3001 | ✅ Working | **FIXED** - Data visualization |
| 10.0.5.118 | PLaywright | Browser Auto | 3000 | ✅ Working | Web automation |
| 10.0.5.121 | Prometheus | Monitoring | 9090 | ✅ Working | Metrics collection |
| 10.0.5.122 | Grafana | Dashboards | 3000 | ✅ Working | Metrics visualization |
| 10.0.5.123 | Loki | Log Aggregation | 3100 | ✅ Working | Centralized logging |
| 10.0.5.200 | Pipelines | OpenWebUI Pipes | 9099 | ✅ Working | OpenWebUI integration |

---

## 🔧 IN PROGRESS (2 services)

| IP | Proxmox Name | Service | Port | Status | ETA |
|---|---|---|---|---|---|
| 10.0.5.106 | langchain | Langfuse | 3000 | 🔧 pnpm installing | 30-60 min |
| 10.0.5.110 | Flowwize | Flowise | 3000 | 🔧 npm installing | 30-60 min |

---

## 📋 NOT DEPLOYED (7 containers)

| IP | Proxmox Name | Intended Service | Port | Script | Status |
|---|---|---|---|---|---|
| 10.0.5.108 | JuypterInstance | Jupyter Notebook | 8888 | - | Available (clarify purpose) |
| 10.0.5.111 | Tika | Text Extraction | 9998 | [34_deploy_shared_tika.sh](34_deploy_shared_tika.sh) | Ready to deploy |
| 10.0.5.115 | MCPO | MCP Proxy | 8080 | - | Skipped (needs MCP servers) |
| 10.0.5.119 | Codeserver | VS Code Server | 8080 | - | Available (clarify purpose) |
| 10.0.5.120 | Gitea | Git Server | 3000 | [32_deploy_shared_gitea.sh](32_deploy_shared_gitea.sh) | Ready to deploy |
| 10.0.5.124 | Juypterlab | JupyterLab | 8888 | [38_deploy_shared_jupyter_native.sh](38_deploy_shared_jupyter_native.sh) | ⭐ Ready to deploy |
| 10.0.5.125 | Formbricks | Survey Platform | 3000 | - | Failed (npm workspace error) |
| 10.0.5.126 | Mailserver | Email Server | 25/587/993 | - | Needs native script |
| 10.0.5.136 | Chainforge | LLM Testing | ? | - | Available (clarify purpose) |

---

## 📋 RECOMMENDED NEW CONTAINERS (127-145)

### **High Priority - Core AI Infrastructure**

| IP | Service | Port | CPU | RAM | Purpose |
|---|---|---|---|---|---|
| 10.0.5.127 | **Elasticsearch** | 9200 | 2 | 4GB | Full-text search & log analysis |
| 10.0.5.128 | **LiteLLM Proxy** | 4000 | 1 | 2GB | Unified LLM API gateway |
| 10.0.5.129 | **Unstructured.io** | 8000 | 2 | 3GB | Advanced document preprocessing |
| 10.0.5.130 | **Apache Superset** | 8088 | 2 | 4GB | Advanced data visualization |

### **Medium Priority - Advanced RAG & Workflows**

| IP | Service | Port | CPU | RAM | Purpose |
|---|---|---|---|---|---|
| 10.0.5.131 | **Apache Airflow** | 8080 | 2 | 4GB | Workflow orchestration |
| 10.0.5.132 | **Haystack** | 8000 | 2 | 3GB | Production RAG framework |
| 10.0.5.133 | **LangGraph API** | 8000 | 2 | 3GB | Multi-agent state machines |
| 10.0.5.134 | **MLflow** | 5000 | 1 | 2GB | ML experiment tracking |

### **Low Priority - Specialized Tools**

| IP | Service | Port | CPU | RAM | Purpose |
|---|---|---|---|---|---|
| 10.0.5.135 | **Plaso** | 5000 | 2 | 4GB | Digital forensics timelines |
| 10.0.5.137 | **JupyterHub** | 8000 | 2 | 4GB | Multi-user Jupyter environment |
| 10.0.5.138 | **Volatility3** | 8080 | 4 | 8GB | Memory forensics analysis |

**Total Resources Needed:** ~22 CPU cores, ~40GB RAM

---

## 🎯 Container Purpose Clarifications Needed

1. **JuypterInstance (108)** vs **Juypterlab (124)**
   - What's the difference?
   - Deploy both or repurpose one?

2. **Codeserver (119)**
   - Deploy VS Code Server here?

3. **Chainforge (136)**
   - Keep for LLM testing or repurpose for Volatility3?

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
        Qdrant (101) ← Embeddings
           ↓
        OpenWebUI RAG

OSINT & Automation:
  SearXNG (105) → Playwright (118) → n8n (109)
               ↓
            PostgreSQL/Neo4j storage

Monitoring:
  All Services → Prometheus (121) → Grafana (122)
              ↓
           Loki (123) ← Logs
```

---

## ⚙️ Deployment Rules

1. **NO DOCKER** on shared services (100-199) - Native deployments only
2. **Docker allowed** on user containers (200-249)
3. All services use **systemd** for service management
4. Credentials stored in `/root/.credentials/`
5. All deployments must pass HTTP health checks

---

## 📈 Next Steps

### Immediate (In Progress):
1. Complete Langfuse (106) installation → build → migrations → systemd
2. Complete Flowise (110) installation → systemd service
3. Verify both services working

### Priority 1 (Ready to Deploy):
1. Deploy JupyterLab to container 124
2. Deploy Tika to container 111
3. Deploy Gitea to container 120

### Priority 2 (New Infrastructure):
1. Create deployment scripts for high-priority services (127-130)
2. Deploy Elasticsearch, LiteLLM, Unstructured, Superset
3. Integrate with existing stack

---

**Quick Status Check:**
```bash
# Check all working services
for ip in 100 101 104 105 107 109 112 113 114 116 117 118 121 122 123; do
  echo -n "10.0.5.$ip: "
  timeout 2 curl -s http://10.0.5.$ip 2>&1 | head -1
done
```

**Files:**
- Tasks: [TASKS_REMAINING.md](TASKS_REMAINING.md)
- Status: [CURRENT_STATUS.md](CURRENT_STATUS.md)
- Monitor Log: `/tmp/20_cycle_monitor.log`
