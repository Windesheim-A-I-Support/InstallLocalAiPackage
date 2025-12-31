# Tasks Remaining - UPDATED Based on Actual Proxmox

## Current Status: 18/27 Working (67%)

### ✅ COMPLETED THIS SESSION (7 services fixed)
- [x] SearXNG (105:8080) - Fixed from source
- [x] n8n (109:5678) - Already working
- [x] Docling (112:5001) - Already working
- [x] Whisper (113:9000) - Already working
- [x] LibreTranslate (114:5000) - Fixed torch
- [x] BookStack (116:3200) - Fixed Apache port
- [x] Metabase (117:3001) - Created database

---

## 🔧 PRIORITY 1 - Complete In-Progress (2 services)

### 1. Complete Langfuse (106:3000)
**Proxmox Name:** langchain (but deploying Langfuse)  
**Status:** pnpm install running  
**Actions:**
- [ ] Wait for pnpm install (~30-60 min)
- [ ] Run `pnpm build`
- [ ] Run database migrations
- [ ] Create systemd service
- [ ] Verify on http://10.0.5.106:3000

### 2. Complete Flowise (110:3000)
**Proxmox Name:** Flowwize  
**Status:** npm install running  
**Actions:**
- [ ] Wait for npm install (~30-60 min)
- [ ] Create systemd service
- [ ] Verify on http://10.0.5.110:3000

---

## 📋 PRIORITY 2 - Deploy to Existing Containers (7 services)

### 3. Deploy JupyterLab (124:8888) ⭐
**Proxmox Name:** Juypterlab  
**Script:** 38_deploy_shared_jupyter_native.sh ✅  
**Actions:**
- [ ] Run deployment script
- [ ] Verify on http://10.0.5.124:8888

### 4. Deploy Tika (111:9998)
**Proxmox Name:** Tika  
**Script:** 34_deploy_shared_tika.sh  
**Actions:**
- [ ] Retry deployment (previous SSH timeout)
- [ ] Verify on http://10.0.5.111:9998

### 5. Deploy Gitea (120:3000)
**Proxmox Name:** Gitea  
**Script:** 32_deploy_shared_gitea.sh  
**Actions:**
- [ ] Fix SSH auth issue
- [ ] Redeploy
- [ ] Verify on http://10.0.5.120:3000

### 6. Deploy/Investigate JupyterInstance (108:?)
**Proxmox Name:** JuypterInstance  
**Question:** What's the difference from JupyterLab (124)?  
**Actions:**
- [ ] Clarify purpose (separate Jupyter instance? different config?)
- [ ] Deploy if needed

### 7. Deploy/Investigate Codeserver (119:8080?)
**Proxmox Name:** Codeserver  
**Expected:** VS Code Server (code-server)  
**Actions:**
- [ ] Check if deployment script exists
- [ ] Deploy VS Code Server
- [ ] Verify on http://10.0.5.119:8080

### 8. Deploy/Investigate Chainforge (136:?)
**Proxmox Name:** Chainforge  
**Expected:** LLM prompt chain testing tool  
**Actions:**
- [ ] Check if deployment script exists
- [ ] Clarify purpose and port
- [ ] Deploy if needed

### 9. Fix Formbricks (125:3000) - OPTIONAL
**Proxmox Name:** Formbricks  
**Status:** npm workspace error  
**Actions:**
- [ ] Debug and fix npm workspace issue
- [ ] Or skip if not priority

### 10. Deploy Mailserver (126) - OPTIONAL
**Proxmox Name:** Mailserver  
**Status:** No native script exists  
**Actions:**
- [ ] Create Postfix/Dovecot native script
- [ ] Or skip if not needed

### 11. MCPO (115:8080) - SKIP
**Status:** Requires MCP servers to proxy (none configured)  
**Action:** Skip for now

---

## 📊 Progress Tracking

**Current:**
- ✅ Working: 18/27 (67%)
- 🔧 Installing: 2/27 (Langfuse, Flowise)
- 📋 Not Deployed: 7/27

**After Priority 1 completes:**
- ✅ Working: 20/27 (74%)

**After Priority 2 completes:**
- ✅ Working: 25-27/27 (93-100%)
- Depends on: JupyterInstance(108), Codeserver(119), Chainforge(136) clarification

---

## ❓ Questions for User

1. **JupyterInstance (108)** vs **JupyterLab (124)** - What's the difference?
   - Same Jupyter, different configs?
   - Different purposes?
   - Deploy both or just one?

2. **Codeserver (119)** - Deploy VS Code Server?
   - Is there a deployment script?
   - What port should it use?

3. **Chainforge (136)** - What's the plan?
   - LLM prompt testing tool?
   - Deploy it or repurpose?

4. **Formbricks (125)** & **Mailserver (126)** - Priority?
   - Worth fixing or skip for now?

---

## ⏱️ Timeline

**Next 1-2 hours:**
- Langfuse & Flowise complete → 20/27 working

**Next 2-4 hours (if proceed with Priority 2):**
- JupyterLab, Tika, Gitea deployed → 23/27 working
- Clarify 108, 119, 136 → Up to 26/27 working

