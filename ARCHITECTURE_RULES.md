# CRITICAL ARCHITECTURE RULES

## ⚠️ NO DOCKER FOR SHARED SERVICES! ⚠️

### THE GOLDEN RULE

**SHARED SERVICES (containers 100-199) MUST BE DEPLOYED NATIVELY!**

```
❌ DO NOT USE DOCKER for shared services (100-199)
✅ ONLY USER CONTAINERS (200-249) can use Docker
```

### Why This Rule Exists

1. **Performance**: Native deployments avoid Docker overhead for shared infrastructure
2. **Stability**: System packages provide better stability for critical services
3. **Resource Management**: Native services integrate better with systemd
4. **Maintenance**: Easier updates and monitoring with system packages
5. **Isolation**: User containers can fail/restart without affecting shared services

### Container IP Ranges

| Range | Purpose | Deployment Method |
|-------|---------|------------------|
| **10.0.5.100-199** | SHARED SERVICES | **NATIVE ONLY** (systemd + apt packages) |
| **10.0.5.200-249** | USER CONTAINERS | **DOCKER ALLOWED** (docker-compose) |

### Shared Services (100-199) - NATIVE DEPLOYMENT ONLY

These services MUST be deployed natively using system packages and systemd:

- **100**: Ollama (LLM inference)
- **101**: Qdrant (vector database)
- **102**: PostgreSQL (relational database)
- **103**: Redis (cache)
- **104**: MinIO (object storage)
- **105**: SearXNG (meta-search engine)
- **106-199**: Other shared services

**Deployment Scripts**: All `*_deploy_shared_*.sh` scripts now have NO DOCKER warnings and deploy natively.

### User Containers (200-249) - DOCKER ALLOWED

These containers run per-user services and CAN use Docker:

- **200-249**: Individual user stacks (Open WebUI, N8N, Flowise, etc.)

**Deployment Scripts**: `08_minimal_ai_stack_containerized.sh` deploys user services with Docker.

### Enforcement

All shared service deployment scripts (`*_deploy_shared_*.sh`) now include this warning:

```bash
# ==============================================================================
# ⚠️  CRITICAL: NO DOCKER FOR SHARED SERVICES! ⚠️
# ==============================================================================
# SHARED SERVICES (containers 100-199) MUST BE DEPLOYED NATIVELY!
#
# ❌ DO NOT USE DOCKER for shared services
# ✅ ONLY USER CONTAINERS (200-249) can use Docker
#
# This service deploys NATIVELY using system packages and systemd.
# Docker is ONLY allowed for individual user containers!
# ==============================================================================
```

### What This Means

1. **Installing Shared Services**:
   - Use `apt install` for packages
   - Use `systemctl` for service management
   - Use native configuration files (not docker-compose.yml)
   - No `docker run`, `docker compose`, or Dockerfiles

2. **Installing User Services**:
   - Docker is allowed and encouraged
   - Use docker-compose for orchestration
   - Connect to shared services via their IPs (100-199 range)
   - Each user gets isolated containers

### Migration Guide

If you find a shared service deployed with Docker:

1. **STOP the Docker container immediately**:
   ```bash
   cd /opt/service-name
   docker compose down
   ```

2. **Remove Docker files**:
   ```bash
   rm docker-compose.yml
   ```

3. **Deploy natively** using the appropriate `*_deploy_shared_*.sh` script

4. **Verify** the service is running via systemd:
   ```bash
   systemctl status service-name
   ```

### Summary

**NEVER use Docker for shared services (100-199)**.

**ALWAYS use Docker for user containers (200-249)**.

This architecture ensures stability, performance, and proper isolation between shared infrastructure and user workloads.
