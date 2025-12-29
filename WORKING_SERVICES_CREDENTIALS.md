# Working Services - Login Credentials
**Date:** 2025-12-25
**Status:** Live Services Ready for Testing

---

## ✅ FULLY WORKING SERVICES

### 1. Ollama - AI Model Server
**URL:** http://10.0.5.100:11434
**Status:** ✅ WORKING
**Container:** 10.0.5.100

**Models Available:**
- `nomic-embed-text:latest` (137M parameters)
- `qwen2.5:3b` (3.1B parameters)

**API Usage:**
```bash
# List models
curl http://10.0.5.100:11434/api/tags

# Generate text
curl http://10.0.5.100:11434/api/generate -d '{
  "model": "qwen2.5:3b",
  "prompt": "Why is the sky blue?"
}'
```

**No authentication required** - Open API endpoint

---

### 2. BookStack - Documentation Wiki
**URL:** http://10.0.5.116
**Status:** ✅ WORKING (with PostgreSQL - has GROUP BY errors when viewing books)
**Container:** 10.0.5.116

**Login Credentials:**
```
Email: admin@admin.com
Password: password
```
⚠️ **CHANGE PASSWORD ON FIRST LOGIN!**

**Database (PostgreSQL):**
```
Host: 10.0.5.102:5432
Database: bookstack
Username: bookstack
Password: rHbnHTYjZGTgulBDnmcTzB2XYm3s/Kq7ozcvIyFxvLA=
```

**Known Issue:**
- PostgreSQL GROUP BY incompatibility causes errors when viewing books
- Recommended: Redeploy with MySQL using script `30_deploy_shared_bookstack_mysql.sh`

**Management:**
```bash
# SSH to container
sshpass -p 'Localbaby100!' ssh root@10.0.5.116

# Apache service
systemctl status apache2
systemctl restart apache2

# Logs
tail -f /var/log/apache2/bookstack-error.log
```

---

### 3. Pipelines - Open WebUI Plugin System
**URL:** http://10.0.5.200:9099
**Status:** ✅ WORKING
**Container:** 10.0.5.200

**Health Check:**
```bash
curl http://10.0.5.200:9099/
# Returns: {"status":true}
```

**Configuration:**
- Connected to Ollama: http://10.0.5.100:11434
- Plugin directory: /app/pipelines

**Management:**
```bash
# SSH to container
sshpass -p 'Localbaby100!' ssh root@10.0.5.200

# View logs
docker logs simple-pipelines -f

# Restart
cd /opt/simple-openwebui && docker compose restart pipelines
```

---

## ⏳ INITIALIZING SERVICES

### 4. Metabase - Business Intelligence
**URL:** http://10.0.5.117:3001
**Status:** ⏳ INITIALIZING (first startup takes 10-20 minutes)
**Container:** 10.0.5.117

**Initial Setup:**
- Visit http://10.0.5.117:3001 when initialization completes
- Complete setup wizard
- Create admin account

**Database (PostgreSQL):**
```
Host: 10.0.5.102:5432
Database: metabase
Username: metabase
Password: NB+gtzvgY3SbNzb0GoZp16YE0kLIwKJK16r8fbo6p1E=
```

**Check Status:**
```bash
curl http://10.0.5.117:3001/api/health
# Returns: {"status":"initializing","progress":0.X}
# When ready: {"status":"ok"}
```

**Management:**
```bash
# SSH to container
sshpass -p 'Localbaby100!' ssh root@10.0.5.117

# Service status
systemctl status metabase
journalctl -u metabase -f
```

---

## 🔧 DEPLOYING SERVICES

### 5. MySQL/MariaDB - Shared Database
**Container:** 10.0.5.103
**Status:** 🔧 DEPLOYING
**Port:** 3306

**Deployment Script:** `29_deploy_shared_mysql.sh`

**Will provide credentials once deployment completes**

---

### 6. Neo4j - Graph Database
**Container:** 10.0.5.107
**Status:** 🔧 DEPLOYING
**Ports:** 7474 (HTTP), 7687 (Bolt)

**Deployment Script:** `33_deploy_shared_neo4j.sh`

**Expected Access:**
- Neo4j Browser: http://10.0.5.107:7474
- Bolt Protocol: bolt://10.0.5.107:7687

---

### 7. Apache Tika - Text Extraction
**Container:** 10.0.5.111
**Status:** 🔧 DEPLOYING
**Port:** 9998

**Deployment Script:** `34_deploy_shared_tika.sh`

**Expected Access:**
- API: http://10.0.5.111:9998

---

## ❌ NOT WORKING

### Open WebUI - Chat Interface
**URL:** http://10.0.5.200:3000
**Container:** 10.0.5.200
**Status:** ❌ DATABASE PERMISSION ISSUES

**Issue:**
- SQLite file locking issues in LXC environment
- PostgreSQL schema permission errors
- Persistent `permission denied for schema public`

**Workaround Needed:**
- Deploy on different container, OR
- Use Docker deployment on non-LXC host

---

## ✅ ADDITIONAL VERIFIED WORKING SERVICES

### Qdrant - Vector Database
**URL:** http://10.0.5.101:6333
**Status:** ✅ WORKING
**Container:** 10.0.5.101

**Dashboard:** http://10.0.5.101:6333/dashboard
**API:** http://10.0.5.101:6333

---

### Redis - Cache Server
**URL:** 10.0.5.103:6379
**Status:** ✅ WORKING
**Container:** 10.0.5.103

**Password:** `hzR7TTDZ7zQuZLo0X8pGkdSIKrjpl9Eb`

**Connection:**
```bash
redis-cli -h 10.0.5.103 -a 'hzR7TTDZ7zQuZLo0X8pGkdSIKrjpl9Eb' ping
```

---

### MinIO - Object Storage (S3-compatible)
**URL:** http://10.0.5.104:9000
**Console:** http://10.0.5.104:9001
**Status:** ✅ WORKING
**Container:** 10.0.5.104

---

### Prometheus - Metrics
**URL:** http://10.0.5.121:9090
**Status:** ✅ WORKING
**Container:** 10.0.5.121

---

### Grafana - Dashboards
**URL:** http://10.0.5.122:3000
**Status:** ✅ WORKING
**Container:** 10.0.5.122

---

### Loki - Log Aggregation
**URL:** http://10.0.5.123:3100
**Status:** ✅ WORKING
**Container:** 10.0.5.123

---

## 🔧 DEPLOYING NOW (Native Installations)

### SearXNG - Privacy Search Engine
**URL:** http://10.0.5.105:8080
**Status:** 🔧 DEPLOYING NATIVE
**Container:** 10.0.5.105

---

### Langfuse - LLM Tracing
**URL:** http://10.0.5.106:3002
**Status:** 🔧 DEPLOYING NATIVE (Node.js dependencies installing)
**Container:** 10.0.5.106

---

### Neo4j - Graph Database
**URL:** http://10.0.5.107:7474
**Status:** 🔧 DEPLOYING NATIVE
**Container:** 10.0.5.107
**Bolt:** bolt://10.0.5.107:7687

---

### n8n - Workflow Automation
**URL:** http://10.0.5.109:5678
**Status:** ⚠️ DEPLOYING NATIVE (has sudo error - needs fixing)
**Container:** 10.0.5.109

---

### Flowise - Low-Code AI Workflows
**URL:** http://10.0.5.110:3003
**Status:** 🔧 DEPLOYING NATIVE (Node.js dependencies installing)
**Container:** 10.0.5.110

---

### Tika - Text Extraction
**URL:** http://10.0.5.111:9998
**Status:** 🔧 DEPLOYING NATIVE (Java-based)
**Container:** 10.0.5.111

---

### Docling - Document Processing
**URL:** http://10.0.5.112:5001
**Status:** 🔧 DEPLOYING NATIVE (Python dependencies installing)
**Container:** 10.0.5.112

---

### LibreTranslate - Translation Service
**URL:** http://10.0.5.114:5000
**Status:** ⚠️ DEPENDENCY ERROR - torch module issue, service restarting
**Container:** 10.0.5.114

**API Key:** `422588080e22860d9505e8c95b515a476f73a8b6ce9a7b4e46c146d036375578`
**Issue:** ModuleNotFoundError: No module named 'torch._prims_common'

**Test when ready:**
```bash
# List available languages
curl http://10.0.5.114:5000/languages

# Translate text
curl -X POST http://10.0.5.114:5000/translate \
  -H "Content-Type: application/json" \
  -d '{
    "q": "Hello world",
    "source": "en",
    "target": "es",
    "api_key": "422588080e22860d9505e8c95b515a476f73a8b6ce9a7b4e46c146d036375578"
  }'
```

**Supported Languages:** en, es, fr, de, it, pt, nl, ru, ja, zh, ar

---

### Whisper - Audio Transcription
**URL:** http://10.0.5.113:9000
**Status:** 🔧 DEPLOYING NATIVE
**Container:** 10.0.5.113

---

### MCPO - MCP Server
**URL:** http://10.0.5.115:8765
**Status:** 🔧 DEPLOYING NATIVE
**Container:** 10.0.5.115

---

### Playwright - Browser Automation
**URL:** http://10.0.5.118:3007
**Status:** 🔧 DEPLOYING NATIVE
**Container:** 10.0.5.118

---

### Formbricks - Form Builder
**URL:** http://10.0.5.125:3008
**Status:** 🔧 DEPLOYING NATIVE
**Container:** 10.0.5.125

---

### Mailserver - Email Server
**Ports:** 25, 587, 993, 443
**Status:** 🔧 DEPLOYING NATIVE
**Container:** 10.0.5.126

---

## 📊 SHARED INFRASTRUCTURE

### PostgreSQL Database Server
**Host:** 10.0.5.102:5432
**Status:** ✅ WORKING
**Container:** 10.0.5.102

**Superuser Credentials:**
```
Username: postgres
Password: ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8=
```

**Admin User:**
```
Username: dbadmin
Password: ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8=
```

**Databases Created:**
- `metabase` (user: metabase)
- `bookstack` (user: bookstack)
- `openwebui` (user: openwebui) - has permission issues

**Connection:**
```bash
# From any container with psql installed
psql postgresql://dbadmin:ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8=@10.0.5.102:5432/postgres
```

---

### Redis Cache Server
**Host:** 10.0.5.101:6379
**Status:** ❓ NOT TESTED
**Container:** 10.0.5.101

**Credentials:**
```
Password: hzR7TTDZ7zQuZLo0X8pGkdSIKrjpl9Eb
```

**Connection:**
```bash
redis-cli -h 10.0.5.101 -a 'hzR7TTDZ7zQuZLo0X8pGkdSIKrjpl9Eb' ping
```

---

## 🎯 SUMMARY

### Ready to Test NOW:
1. ✅ **Ollama** - http://10.0.5.100:11434 (AI Models)
2. ✅ **BookStack** - http://10.0.5.116 (admin@admin.com / password)
3. ✅ **Pipelines** - http://10.0.5.200:9099 (API endpoint)
4. ✅ **Qdrant** - http://10.0.5.101:6333/dashboard (Vector DB)
5. ✅ **MinIO** - http://10.0.5.104:9001 (Object Storage)
6. ✅ **Prometheus** - http://10.0.5.121:9090 (Metrics)
7. ✅ **Grafana** - http://10.0.5.122:3000 (Dashboards)
8. ✅ **Loki** - http://10.0.5.123:3100 (Logs)

### Currently Deploying (13 services in progress):
**First Batch:**
- 🔧 **SearXNG** (105) - Privacy search engine
- 🔧 **Langfuse** (106) - LLM tracing
- 🔧 **Neo4j** (107) - Graph database
- 🔧 **n8n** (109) - Workflow automation
- 🔧 **Flowise** (110) - AI workflows
- 🔧 **Tika** (111) - Text extraction (container down)
- 🔧 **Docling** (112) - Document processing
- 🔧 **LibreTranslate** (114) - Translation (downloading models)

**Second Batch:**
- 🔧 **Whisper** (113) - Audio transcription
- 🔧 **MCPO** (115) - MCP server
- 🔧 **Playwright** (118) - Browser automation
- 🔧 **Formbricks** (125) - Form builder
- 🔧 **Mailserver** (126) - Email server

### Issues:
- ❌ **Open WebUI** - Database permission errors
- ⚠️ **BookStack** - PostgreSQL GROUP BY errors (works but limited)
- 🔒 **Container 120** - SSH authentication failed (Gitea deployment blocked)

---

## ✅ CURRENT STATUS: Native Deployments Verified

**Network:** ✅ VPN connected
**Docker Verification:** ✅ NO Docker on shared services containers (100-199) - confirmed
**Scripts Verified:** ✅ Using ONLY verified native scripts (_native.sh files)

**Services with NATIVE scripts ready to deploy:**
- ✅ Neo4j (107) - Fixed Java dependency issue, script ready
- ✅ SearXNG (105) - Native Python deployment
- ✅ Langfuse (106) - Native Node.js deployment
- ✅ n8n (109) - Native Node.js deployment, script copied
- ✅ Flowise (110) - Native Node.js deployment, script copied
- ✅ Docling (112) - Native Python deployment, script copied

**Services WITHOUT native scripts (Docker-based only):**
- ❌ Whisper (113), MCPO (115), Playwright (118), Formbricks (125), Mailserver (126)
- **Action:** These need native deployment scripts created or cannot be deployed on shared services

**Note:** Containers are heavily loaded, deployments will proceed once resources available

## 📝 Next Steps

1. **Monitor deployments** - Scripts installing packages (15-30 min each)
2. **Retrieve credentials** - Once complete, get /root/.credentials/*.txt from each container
3. **Continue deploying** - 40+ more services available for deployment
4. **Fix Container 120 SSH** - Gitea deployment blocked by auth issues
5. **Redeploy BookStack with MySQL** - Fix PostgreSQL GROUP BY errors
6. **Check Metabase** - Verify initialization completed

---

**Last Updated:** 2025-12-28 03:25 CET
**Services Working:** 9 verified (Ollama, Qdrant, PostgreSQL, Redis, MinIO, BookStack, Pipelines, Prometheus, Grafana, Loki)
**Active Deployments (NATIVE ONLY - NO DOCKER):**
  - n8n (109): 🔄 Installing npm packages (in progress, warnings ok)
  - Flowise (110): 🔄 Installing npm packages (in progress)
  - Neo4j (107): ❌ Failed (Java 21 dependency) - Fixed script ready as neo4j_deploy_v2.sh
  - SearXNG (105): ❌ Failed (msgspec import) - Script needs rework
  - Langfuse (106): ❌ Failed (permission denied) - Script needs fix
**Script Fixes Completed:**
  - ✅ All GPG commands now use --batch flag (no /dev/tty errors)
  - ✅ All GPG key files removed before creation (no "File exists" errors)
  - ✅ Neo4j: Added Java 21 from Adoptium repository (temurin-21-jdk)
  - ✅ SearXNG: Using explicit venv pip paths
  - ✅ Node.js scripts: Fixed GPG key downloads
**Docker Verification:** ✅ Confirmed NO Docker on shared services containers (100-199)
**Network:** ✅ VPN connected (high latency ~1200ms - deployments slower than usual)
