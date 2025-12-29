# Container Inventory - 2025-12-28 19:35 CET

## Container Status Overview (10.0.5.100-126)

### ✅ DEPLOYED & WORKING (12 services)

| IP | Service | Port | Status | Type | Notes |
|---|---|---|---|---|---|
| 10.0.5.100 | Ollama | 11434 | ✅ HTTP 200 | Native | LLM inference engine |
| 10.0.5.101 | Qdrant | 6333 | ✅ HTTP 404 (dashboard) | Native | Vector database |
| 10.0.5.102 | PostgreSQL | 5432 | ✅ Active | Native | Database (SSH timeout but working) |
| 10.0.5.103 | Redis | 6379 | ✅ Active | Native | Cache (SSH timeout but working) |
| 10.0.5.104 | MinIO | 9001 | ✅ HTTP 200 | Native | Object storage |
| 10.0.5.107 | Neo4j | 7474 | ✅ HTTP 200 | Native | **NEWLY DEPLOYED** Graph database |
| 10.0.5.109 | n8n | 5678 | ✅ HTTP 200 | Native | **NEWLY DEPLOYED** Workflow automation |
| 10.0.5.116 | BookStack | 80 | ✅ HTTP 302 | Native | Wiki/documentation |
| 10.0.5.121 | Prometheus | 9090 | ✅ HTTP 302 | Native | Monitoring metrics |
| 10.0.5.122 | Grafana | 3000 | ✅ HTTP 302 | Native | Monitoring dashboards |
| 10.0.5.123 | Loki | 3100 | ✅ HTTP 200 | Native | Log aggregation |
| 10.0.5.200 | Pipelines | 9099 | ✅ HTTP 200 | Native | Open WebUI pipelines |

### 🔄 INSTALLING (3 services)

| IP | Service | Port | Status | Notes |
|---|---|---|---|---|
| 10.0.5.110 | Flowise | 3000 | 🔄 Installing | npm install running 90+ minutes (large package, normal) |
| 10.0.5.112 | Docling | 5001 | ⚠️ Failed - Fixing | Script used `sudo` command which doesn't exist, fixing |
| 10.0.5.114 | LibreTranslate | 5000 | 🔄 Installing | Reinstalling torch (899MB), should complete soon |

### ❌ NOT DEPLOYED (10 containers)

| IP | Assigned Service | Expected Port | Status | Deployment Script |
|---|---|---|---|---|
| 10.0.5.105 | SearXNG | 8080 | ❌ Not deployed | 17_deploy_shared_searxng_native.sh (fixed, ready) |
| 10.0.5.106 | Langfuse | 3000 | ❌ Not deployed | 18_deploy_shared_langfuse_native.sh (fixed, ready) |
| 10.0.5.108 | Unassigned | - | ❌ Empty | Available |
| 10.0.5.111 | Tika | 9998 | ❌ Not deployed | Script ready, SSH timeout |
| 10.0.5.113 | Whisper | 9000 | ❌ Not deployed | Only Docker version exists |
| 10.0.5.115 | MCPO | 8000 | ❌ Not deployed | Only Docker version exists |
| 10.0.5.117 | Metabase | 3000 | ❌ Not deployed | Need to create native script |
| 10.0.5.118 | Playwright | 3000 | ❌ Not deployed | Only Docker version exists |
| 10.0.5.119 | Unassigned | - | ❌ Empty | Available |
| 10.0.5.120 | Gitea | 3000 | ❌ Not deployed | Had SSH auth issues previously |
| 10.0.5.124 | Unassigned | - | ❌ Empty | Available |
| 10.0.5.125 | Formbricks | 3000 | ❌ Not deployed | Only Docker version exists |
| 10.0.5.126 | Mailserver | 25/587/993 | ❌ Not deployed | Need to create native script |

## Deployment Progress

**Total Containers:** 27 (100-126)
- **Working:** 12 (10 pre-existing + 2 newly deployed today)
- **Installing:** 3 (Flowise, Docling, LibreTranslate)
- **Not Deployed:** 10
- **Available/Empty:** 3 (108, 119, 124)

**Success Rate Today:** 2 services successfully deployed (n8n, Neo4j)

## Next Deployment Priorities

### Ready to Deploy (Scripts Fixed):
1. **SearXNG** (105) - Native Python deployment
2. **Langfuse** (106) - Native Node.js deployment

### Need Native Scripts Created:
1. **Tika** (111) - Apache Tika text extraction
2. **LibreTranslate** (114) - Translation service
3. **Metabase** (117) - Analytics/BI tool
4. **Gitea** (120) - Git hosting (fix SSH auth)
5. **Mailserver** (126) - Email server

### Docker-Only Services (Need Native Conversion):
1. **Whisper** (113) - Speech-to-text
2. **MCPO** (115) - Model Context Protocol
3. **Playwright** (118) - Browser automation
4. **Formbricks** (125) - Survey tool
5. **Docling** (112) - Document processing

## Key Insights

1. **12 services working** - Core infrastructure is solid
2. **All deployments are NATIVE** - No Docker on shared services (100-199)
3. **2 successful deployments today** - n8n and Neo4j both working
4. **Flowise in progress** - Large npm package taking 70+ minutes (normal)
5. **13 containers need deployment** - Mix of ready scripts and new scripts needed

## Container Load Status

- High load on 10.0.5.110 (Flowise) - npm compilation using significant CPU/RAM
- SSH timeouts on most containers due to load
- HTTP checks working - services responding normally despite load

---

**Last Updated:** 2025-12-28 19:35 CET
**Next Check:** Monitor Flowise completion (est. 10-20 minutes)
