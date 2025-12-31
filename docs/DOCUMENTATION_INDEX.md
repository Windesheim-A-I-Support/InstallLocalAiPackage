# Documentation Index
**Last Updated:** 2025-12-31

## 📚 Essential Documentation (14 Files)

### **🎯 Daily Operations** (Use These Regularly)

| File | Purpose |
|---|---|
| [CONTAINER_INVENTORY.md](CONTAINER_INVENTORY.md) | **Complete container listing** - All 27 containers, status, recommendations |
| [CURRENT_STATUS.md](CURRENT_STATUS.md) | **Quick status table** - Fast overview of what's working |
| [TASKS_REMAINING.md](TASKS_REMAINING.md) | **To-do list** - What needs to be done next |
| [WORKING_SERVICES_CREDENTIALS.md](WORKING_SERVICES_CREDENTIALS.md) | **Credentials** - Login info for all services |

### **📖 Reference**

| File | Purpose |
|---|---|
| [README.md](README.md) | **Project overview** - Infrastructure & Traefik routing |
| [ARCHITECTURE.md](ARCHITECTURE.md) | **System architecture** - How services connect |
| [ARCHITECTURE_RULES.md](ARCHITECTURE_RULES.md) | **Design principles** - Why things are structured this way |
| [SHARED_SERVICES_LIMITATIONS.md](SHARED_SERVICES_LIMITATIONS.md) | **No Docker rule** - Why native deployments only |
| [AUTHENTICATION_STRATEGY.md](AUTHENTICATION_STRATEGY.md) | **Security approach** - Auth & access control |

### **🛠️ Deployment Tools**

| File | Purpose |
|---|---|
| [NATIVE_SCRIPTS_SUMMARY.md](NATIVE_SCRIPTS_SUMMARY.md) | **Script catalog** - All deployment scripts |
| [VERIFIED_DEPLOYMENT_SCRIPTS_SOURCES.md](VERIFIED_DEPLOYMENT_SCRIPTS_SOURCES.md) | **Verified sources** - Trusted script origins |
| [DEPRECATED_SCRIPTS.md](DEPRECATED_SCRIPTS.md) | **Avoid these** - Old/broken scripts |
| [HEALTH_CHECK_GUIDE.md](HEALTH_CHECK_GUIDE.md) | **Health checks** - How to verify services |
| [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) | **This file** - Navigation guide |

---

## 🎯 Quick Workflows

### Check Service Status
```bash
# Quick view
cat CURRENT_STATUS.md

# Full details
cat CONTAINER_INVENTORY.md

# Get credentials
cat WORKING_SERVICES_CREDENTIALS.md
```

### Deploy New Service
1. Check available containers: [CONTAINER_INVENTORY.md](CONTAINER_INVENTORY.md)
2. Find deployment script: [NATIVE_SCRIPTS_SUMMARY.md](NATIVE_SCRIPTS_SUMMARY.md)
3. Run script: `bash XX_deploy_shared_SERVICE_native.sh`
4. Update status: [CURRENT_STATUS.md](CURRENT_STATUS.md)
5. Update tasks: [TASKS_REMAINING.md](TASKS_REMAINING.md)
6. Save credentials: [WORKING_SERVICES_CREDENTIALS.md](WORKING_SERVICES_CREDENTIALS.md)

### Troubleshoot Issues
```bash
# Check service logs
journalctl -u <service> -f

# Check health
cat HEALTH_CHECK_GUIDE.md

# Find credentials
cat /root/.credentials/<service>.txt
```

---

## 🗂️ Cleanup History

**2025-12-31 - Major Cleanup:**
- Removed 20 redundant files
- Merged IP_ALLOCATION_MAP.md → CONTAINER_INVENTORY.md
- Removed: deployment status files, old credentials, historical reports
- **Result:** 14 essential files (down from 34)

**Files Removed:**
- 6× Deployment status files
- 2× Old credential snapshots
- 7× Historical reports/sessions
- 5× Redundant reference docs

---

**Total Files:** 14 (essential only)
**Active Daily Files:** 4
**Reference Files:** 5
**Tool Files:** 5
