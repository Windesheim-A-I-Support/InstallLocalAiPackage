# Current Service Status - Actual Proxmox Containers

**Last Updated:** $(date)

## 📊 Overview: 18/27 Working (67%)

## Service Status by IP

| IP | Proxmox Name | Service | Port | Status |
|---|---|---|---|---|
| 100 | Ollama | LLM Engine | 11434 | ✅ Working |
| 101 | qdrant | Vector DB | 6333 | ✅ Working |
| 102 | PostGres | Database | 5432 | ✅ Working |
| 103 | Redis | Cache | 6379 | ✅ Working |
| 104 | Minio | Object Storage | 9001 | ✅ Working |
| 105 | Seargxn | SearXNG | 8080 | ✅ **FIXED** |
| 106 | langchain | Langfuse | 3000 | 🔧 Installing |
| 107 | Neo4j | Graph DB | 7474 | ✅ Working |
| 108 | JuypterInstance | Jupyter? | ? | ❓ Not deployed |
| 109 | N8n | Workflow | 5678 | ✅ Working |
| 110 | Flowwize | Flowise | 3000 | 🔧 Installing |
| 111 | Tika | Text Extract | 9998 | ❌ Not deployed |
| 112 | Docling | Document AI | 5001 | ✅ Working |
| 113 | whisper | Speech-to-Text | 9000 | ✅ Working |
| 114 | Libretranslate | Translation | 5000 | ✅ **FIXED** |
| 115 | MCPO | MCP Proxy | 8080 | ⏭️ Skipped |
| 116 | BookStack | Wiki | 3200 | ✅ **FIXED** |
| 117 | Metabase | BI Analytics | 3001 | ✅ **FIXED** |
| 118 | PLaywright | Browser Auto | 3000 | ✅ Working |
| 119 | Codeserver | VS Code? | 8080? | ❓ Not deployed |
| 120 | Gitea | Git Server | 3000 | ❌ Not deployed |
| 121 | Prometheus | Monitoring | 9090 | ✅ Working |
| 122 | Grafana | Dashboards | 3000 | ✅ Working |
| 123 | Loki | Logs | 3100 | ✅ Working |
| 124 | Juypterlab | JupyterLab | 8888 | ❌ Not deployed ⭐ |
| 125 | Formbricks | Surveys | 3000 | ❌ Failed |
| 126 | Mailserver | Email | 25/587 | ❌ Not deployed |
| 136 | Chainforge | LLM Testing? | ? | ❓ Not deployed |

**Legend:**
- ✅ Working
- 🔧 Installing (in progress)
- ❌ Not deployed
- ❓ Unclear/needs clarification
- ⏭️ Skipped (not applicable)
- ⭐ High priority to deploy

## Quick Status Check Commands

```bash
# Check all working services
for ip in 100 101 104 105 107 109 112 113 114 116 117 118 121 122 123; do
  timeout 2 curl -s http://10.0.5.$ip 2>&1 | head -1
done

# Check installing services
ssh root@10.0.5.106 "ps aux | grep pnpm"  # Langfuse
ssh root@10.0.5.110 "ps aux | grep npm"   # Flowise
```

## Files

- **Tasks:** TASKS_REMAINING.md
- **IP Map:** IP_ALLOCATION_MAP.md
- **Monitor Log:** /tmp/20_cycle_monitor.log

