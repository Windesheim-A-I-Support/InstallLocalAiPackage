# Deprecated Scripts

**Last Updated:** 2025-11-30

---

## ⚠️ DO NOT USE THESE SCRIPTS

The following scripts are **DEPRECATED** and should **NOT** be used. They were designed to deploy services as standalone LXC containers, which is **incorrect** for per-user services.

## Deprecated Per-User Scripts

| Script # | Script Name | Reason | Replacement |
|----------|-------------|--------|-------------|
| 15 | `15_deploy_openwebui_instance.sh` | Deploys Open WebUI as standalone - incorrect architecture | Use `52_deploy_user_container.sh` |
| 20 | `20_deploy_shared_jupyter.sh` | Deploys Jupyter as standalone - should be per-user | Use `52_deploy_user_container.sh` |
| 21 | `21_deploy_shared_n8n.sh` | Deploys n8n as standalone - licensing requires per-user | Use `52_deploy_user_container.sh` |
| 22 | `22_deploy_shared_flowise.sh` | Deploys Flowise as standalone - should be per-user | Use `52_deploy_user_container.sh` |
| 33 | `33_deploy_shared_code_server.sh` | Deploys code-server as standalone - should be per-user | Use `52_deploy_user_container.sh` |
| 46 | `46_deploy_shared_chainforge.sh` | Deploys ChainForge as standalone - should be per-user | Use `52_deploy_user_container.sh` |
| 47 | `47_deploy_shared_big_agi.sh` | Deploys big-AGI as standalone - should be per-user | Use `52_deploy_user_container.sh` |
| 48 | `48_deploy_shared_kotaemon.sh` | Deploys Kotaemon as standalone - should be per-user | Use `52_deploy_user_container.sh` |

---

## Correct Architecture

### ❌ WRONG (What deprecated scripts do)
```
One LXC container per service per user:
- Container 200: Open WebUI for user1
- Container 201: n8n for user1
- Container 202: Jupyter for user1
- Container 203: code-server for user1
- ... (50+ containers per user!)
```

### ✅ CORRECT (What script 52 does)
```
One LXC container per user with ALL services inside:
- Container 200 (user1):
  ├── openwebui-user1 (Docker)
  ├── n8n-user1 (Docker)
  ├── jupyter-user1 (Docker)
  ├── code-server-user1 (Docker)
  ├── big-agi-user1 (Docker)
  ├── chainforge-user1 (Docker)
  ├── kotaemon-user1 (Docker)
  └── flowise-user1 (Docker)
```

---

## Migration Path

If you accidentally deployed using the deprecated scripts, here's how to migrate:

### 1. Stop and Remove Old Deployments
```bash
# Stop all containers created by deprecated scripts
cd /opt/open-webui-<instance> && docker compose down
cd /opt/jupyter && docker compose down
cd /opt/n8n && docker compose down
cd /opt/flowise && docker compose down
cd /opt/code-server && docker compose down
cd /opt/chainforge && docker compose down
cd /opt/big-agi && docker compose down
cd /opt/kotaemon && docker compose down

# Optionally backup data directories before removing
```

### 2. Deploy Using New Script
```bash
# Deploy all services for a user in one container
bash 52_deploy_user_container.sh <username> <user_number>

# Example:
bash 52_deploy_user_container.sh alice 1  # Creates container at 10.0.5.200
```

### 3. Migrate Data (If Needed)
```bash
# If you have existing data to migrate:
# 1. Backup old data
# 2. Copy to new container's data directories
# 3. Update ownership/permissions
# 4. Restart Docker containers in new deployment
```

---

## Why These Scripts Are Deprecated

1. **Resource Inefficiency**: Creating separate LXC containers for each service per user wastes resources
2. **Management Complexity**: 8 containers per user × 50 users = 400 containers to manage
3. **Networking Overhead**: Each LXC container needs its own IP address
4. **Incorrect Architecture**: Per-user services should be isolated per user, not shared
5. **Licensing Issues**: n8n Community Edition only supports 1 user - needs separate instances

---

## Correct Usage

### For SHARED Services (Deploy ONCE)
Use the dedicated shared service scripts:
- `11_deploy_shared_ollama.sh` ✅
- `12_deploy_shared_qdrant.sh` ✅
- `13_deploy_shared_postgres.sh` ✅
- `14_deploy_shared_redis.sh` ✅
- etc.

### For PER-USER Services (Deploy Per User)
Use the unified per-user script:
- `52_deploy_user_container.sh` ✅

---

## Questions?

If you're unsure whether a service should be shared or per-user, check:
- [SERVICE_IP_MAP.md](SERVICE_IP_MAP.md) - Comprehensive service catalog
- [SHARED_SERVICES_LIMITATIONS.md](SHARED_SERVICES_LIMITATIONS.md) - Sharing analysis
- [ARCHITECTURE.md](ARCHITECTURE.md) - High-level architecture overview

---

## Exception: LobeChat

Script 49 (`49_deploy_shared_lobechat.sh`) is **NOT deprecated** because:
- LobeChat can be deployed as a shared instance (optional)
- It's a modern alternative to Open WebUI
- Can be used alongside or instead of Open WebUI
- Deployment as shared instance is a valid use case

If you want LobeChat per-user, use script 52 or modify it to include LobeChat.
