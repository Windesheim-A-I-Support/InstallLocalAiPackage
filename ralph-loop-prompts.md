# Ralph-Loop Prompts for Infrastructure Deployment

**Created:** 2025-12-31
**Purpose:** Ready-to-use ralph-loop prompts for automated service deployment

---

## 📖 HOW TO USE THESE PROMPTS

**CRITICAL INSTRUCTIONS:**

1. Find the prompt you want to use below
2. Click and drag to select ONLY the text starting from `/ralph-loop` to the final `"DONE"`
3. Do NOT select the heading text above it
4. Do NOT select any extra lines after the command
5. Copy the selection (Ctrl+C or Cmd+C)
6. Paste into your terminal (Ctrl+V or Cmd+V)
7. Press Enter

**WHAT TO COPY:** Everything from `/ralph-loop "Deploy...` through `...--completion-promise "DONE"`

**WHAT NOT TO COPY:** Headings, blank lines before/after, or any text that isn't part of the command

---

## 🎯 Prompt 1: Deploy All Pending Services

/ralph-loop "Deploy all pending services to Proxmox containers.

Process:
1. Check which containers exist and are accessible via SSH
2. For each existing container without a deployed service:
   - Identify the correct deployment script from scripts/ directory
   - Run the deployment script
   - Wait for deployment to complete
   - Verify service is running (systemctl status + HTTP check)
   - Save credentials to docs/CREDENTIALS.md
   - Update docs/STATUS.md to mark service as deployed
3. If deployment fails:
   - Check logs: journalctl -u SERVICE -f
   - Troubleshoot and fix the issue
   - Retry deployment
4. Continue until all deployable containers have working services

Containers to deploy (in priority order):
- 124: JupyterLab (scripts/38_deploy_shared_jupyter_native.sh)
- 111: Tika (scripts/34_deploy_shared_tika.sh)
- 120: Gitea (scripts/32_deploy_shared_gitea.sh)
- 127-130: Elasticsearch, LiteLLM, Unstructured, Superset (if containers created)
- 131-134: Airflow, Haystack, LangGraph, MLflow (if containers created)
- 106: Complete Langfuse (if pnpm install finished)
- 110: Complete Flowise (if npm install finished)

Success criteria for each deployment:
- systemctl status SERVICE shows active (running)
- HTTP endpoint responds (curl http://10.0.5.XXX:PORT)
- No errors in journalctl -u SERVICE
- Credentials saved to /root/.credentials/SERVICE.txt
- Service added to docs/STATUS.md as working

When all deployable services are working, output: <promise>DONE</promise>" --max-iterations 50 --completion-promise "DONE"

---

## 🔄 Prompt 2: General Deployment Workflow

/ralph-loop "Execute deployment workflow for infrastructure services.

Context:
- Network: 10.0.5.0/24
- Access: ssh root@10.0.5.XXX
- Repo: /home/chris/Documents/github/InstallLocalAiPackage
- Scripts: scripts/XX_deploy_shared_SERVICE_native.sh
- Docs: docs/STATUS.md, docs/CREDENTIALS.md, docs/REFERENCE.md

Workflow:
1. Read docs/STATUS.md to understand current state
2. Identify next service to deploy from Ready to Deploy section
3. Verify container exists: ssh root@10.0.5.XXX hostname
4. Run deployment script: bash scripts/XX_deploy_shared_SERVICE_native.sh
5. Monitor deployment output for errors
6. Verify deployment:
   - systemctl status SERVICE (active/running)
   - curl http://10.0.5.XXX:PORT (responds)
   - journalctl -u SERVICE (no errors)
7. Extract credentials from /root/.credentials/SERVICE.txt
8. Update docs/STATUS.md (move from Ready to Deploy to Working)
9. Update docs/CREDENTIALS.md with login info
10. Repeat for next service

Error handling:
- If deployment fails: check logs, troubleshoot, fix, retry
- If container does not exist: skip and continue to next
- If script missing: create deployment script, then deploy

Stop conditions:
- All accessible containers have working services
- All deployment scripts have been executed
- No more services in Ready to Deploy list

When workflow complete, output: <promise>DONE</promise>" --max-iterations 50 --completion-promise "DONE"

---

## ⏳ Prompt 3: Monitor In-Progress Installations

/ralph-loop "Monitor and complete in-progress service installations.

Tasks:
1. Check Langfuse (106):
   - SSH to root@10.0.5.106
   - Check if pnpm install finished: ps aux | grep pnpm
   - If finished: run pnpm build, prisma migrate, create systemd service
   - Verify working: curl http://10.0.5.106:3000

2. Check Flowise (110):
   - SSH to root@10.0.5.110
   - Check if npm install finished: ps aux | grep npm
   - If finished: create systemd service per script
   - Verify working: curl http://10.0.5.110:3000

3. For each completed service:
   - Update docs/STATUS.md to mark as working
   - Save credentials to docs/CREDENTIALS.md

Check every 5 minutes. When both services are working, output: <promise>DONE</promise>" --max-iterations 20 --completion-promise "DONE"

---

## 🚀 Prompt 4: Deploy High Priority Services Only

/ralph-loop "Deploy high-priority services to new containers.

Services to deploy (if containers exist):
1. Elasticsearch (127) - scripts/40_deploy_shared_elasticsearch_native.sh
2. LiteLLM (128) - scripts/39_deploy_shared_litellm_native.sh
3. Unstructured (129) - scripts/41_deploy_shared_unstructured_native.sh
4. Superset (130) - scripts/43_deploy_shared_superset_native.sh

Process for each:
1. Verify container exists: ssh root@10.0.5.XXX hostname
2. If not exists: skip and continue to next
3. If exists:
   - Run deployment script
   - Wait for completion
   - Verify: systemctl status + curl check
   - Update docs/STATUS.md
   - Save credentials to docs/CREDENTIALS.md

When all 4 services are deployed or confirmed not deployable, output: <promise>DONE</promise>" --max-iterations 20 --completion-promise "DONE"

---

## 🧪 Prompt 5: Deploy JupyterLab (Single Service Example)

/ralph-loop "Deploy JupyterLab to container 124.

Steps:
1. Verify container exists: ssh root@10.0.5.124 hostname
2. Run deployment: bash scripts/38_deploy_shared_jupyter_native.sh
3. Monitor output for errors
4. Verify deployment:
   - systemctl status jupyter
   - curl http://10.0.5.124:8888
   - journalctl -u jupyter (no errors)
5. Get credentials: cat /root/.credentials/jupyter.txt
6. Update docs/STATUS.md - mark as working
7. Update docs/CREDENTIALS.md - add login info

When service is verified working, output: <promise>DONE</promise>" --max-iterations 10 --completion-promise "DONE"

---

## 🔍 Prompt 6: Health Check All Services

/ralph-loop "Health check all deployed services.

Process:
1. Read docs/STATUS.md to get list of working services
2. For each working service:
   - Check systemctl status SERVICE
   - Check HTTP endpoint: curl http://10.0.5.XXX:PORT
   - Check for errors: journalctl -u SERVICE --since 1 hour ago
3. If any service is down:
   - Attempt to restart: systemctl restart SERVICE
   - Check logs for errors
   - Report the issue
4. Update docs/STATUS.md with current status
5. Generate summary report of all services

When all services checked, output: <promise>DONE</promise>" --max-iterations 30 --completion-promise "DONE"

---

## 📝 Prompt 7: Update Documentation

/ralph-loop "Update documentation for all deployed services.

Tasks:
1. Scan all containers (100-126, 136, 200) for running services
2. For each running service:
   - Check if listed in docs/STATUS.md
   - If not listed, add to Working Services section
   - Extract credentials from /root/.credentials/SERVICE.txt
   - Add to docs/CREDENTIALS.md if not present
3. Verify all services in docs/STATUS.md are actually running
4. Remove any services from Working that are actually down
5. Count total working services and update overview

When documentation is accurate and complete, output: <promise>DONE</promise>" --max-iterations 20 --completion-promise "DONE"

---

## ✅ COPY-PASTE GUIDE

### Example: To deploy JupyterLab

1. Scroll to "Prompt 5: Deploy JupyterLab" above
2. Click at the start of `/ralph-loop` and drag to the end of `"DONE"`
3. Copy that selection
4. Paste into terminal
5. Press Enter

### What you should see in your terminal:

```
/ralph-loop "Deploy JupyterLab to container 124.
[... full prompt text ...]
When service is verified working, output: <promise>DONE</promise>" --max-iterations 10 --completion-promise "DONE"
```

### Common mistakes:

❌ Copying the heading "## 🧪 Prompt 5..."
❌ Copying blank lines before/after
❌ Not copying all the way to "DONE"
❌ Copying the example box shown above

✅ Only copy from `/ralph-loop` to `"DONE"`

---

## 🚨 TROUBLESHOOTING

**Error: "permission check failed"**
- You copied too much (likely included heading or blank lines)
- Try again: select ONLY from `/ralph-loop` to `"DONE"`

**Error: Command not found**
- Make sure you're in the repo directory: `cd /home/chris/Documents/github/InstallLocalAiPackage`
- Check if ralph-loop is available in your environment

**Ralph-loop runs but does nothing**
- Check containers exist: `ssh root@10.0.5.124 hostname`
- Check scripts exist: `ls scripts/38_deploy_shared_jupyter_native.sh`
- Read current status: `cat docs/STATUS.md`

**It stops before finishing**
- Increase `--max-iterations` to a higher number (e.g., 100)
- Check the output for errors
- The loop stops when it outputs `<promise>DONE</promise>`

---

## 📋 PRE-FLIGHT CHECKLIST

Before running any ralph-loop prompt:

- [ ] In repo directory: `cd /home/chris/Documents/github/InstallLocalAiPackage`
- [ ] Containers exist in Proxmox (verify with `ssh root@10.0.5.XXX hostname`)
- [ ] SSH access works without password prompts
- [ ] Deployment scripts exist in `scripts/` directory
- [ ] You've read `docs/STATUS.md` to understand current state

---

**Last Updated:** 2025-12-31

**Remember:** Select and copy ONLY from `/ralph-loop` to the final `"DONE"` - nothing else!
