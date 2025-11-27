# AI Stack Deployment Instructions
## For Fresh Debian 12 LXC Containers on Proxmox

**Author:** Claude (AI Assistant)
**Date:** 2025-11-25
**Purpose:** Complete instructions for deploying local-ai-packaged with optimal performance

---

## Table of Contents
1. [Quick Start](#quick-start)
2. [LXC Container Configuration](#lxc-container-configuration)
3. [Deployment Steps](#deployment-steps)
4. [Troubleshooting](#troubleshooting)
5. [Performance Notes](#performance-notes)

---

## Quick Start

**If you're in a hurry:** Skip to [Deployment Steps](#deployment-steps) and run the scripts. They work out of the box but will use slower VFS storage driver on unprivileged containers.

**For optimal performance:** Follow [LXC Container Configuration](#lxc-container-configuration) first to enable overlay2 (10-20x faster image extraction).

---

## LXC Container Configuration

### Why Configure LXC?
- **Default behavior:** Unprivileged LXC containers use VFS storage driver (very slow image extraction)
- **With configuration:** Enable overlay2 storage driver (10-20x faster)
- **Runtime impact:** Only affects image pull/extraction speed, not container runtime (~5% difference)

### Option 1: Unprivileged Container with Overlay2 (RECOMMENDED)

On your **Proxmox host**, edit the container configuration:

```bash
# Replace <CTID> with your container ID (e.g., 20507)
nano /etc/pve/lxc/<CTID>.conf
```

Add these lines at the end:

```conf
# Enable overlay2 for Docker in unprivileged LXC
lxc.apparmor.profile: unconfined
lxc.cgroup2.devices.allow: a
lxc.cap.drop:
lxc.mount.auto: proc:rw sys:rw cgroup:rw
```

**Restart the container:**
```bash
pct stop <CTID>
pct start <CTID>
```

### Option 2: Privileged Container (NOT RECOMMENDED)

Privileged containers get overlay2 by default but sacrifice security isolation. Only use if you understand the security implications.

```bash
# Create privileged container
pct create <CTID> <template> --unprivileged 0 --rootfs local-lvm:32
```

### Option 3: Keep VFS (Slowest but Safest)

No configuration needed. The scripts will automatically use VFS. Deployment will take 30-60 minutes instead of 10-20 minutes, but works reliably.

---

## Deployment Steps

### Prerequisites
- Fresh Debian 12 LXC container
- Root access
- Internet connection
- 180GB+ disk space (90GB minimum, but AI stack needs room)

### Step 1: Copy Scripts to Container

On your **local machine** (where scripts are):
```bash
cd /home/chris/Documents/github/InstallLocalAiPackage

# Copy all scripts to the container
scp 0*.sh root@<CONTAINER_IP>:/root/
```

Or use the provided SSH key:
```bash
cd /home/chris/Documents/github/InstallLocalAiPackage
scp -i ~/.ssh/id_ed25519 0*.sh root@<CONTAINER_IP>:/root/
```

### Step 2: SSH into Container

```bash
ssh root@<CONTAINER_IP>
# Or with the Claude Code key:
ssh -i ~/.ssh/id_ed25519 root@<CONTAINER_IP>
```

### Step 3: Run Deployment Scripts

#### Option A: Full Automated Deployment
```bash
cd /root
chmod +x 00_full_deployment.sh
./00_full_deployment.sh
```

#### Option B: Step-by-Step Deployment

**As root:**
```bash
cd /root
chmod +x *.sh

# Step 1: Install system dependencies
./01_system_dependencies.sh

# Step 2: Install Docker (automatically detects overlay2 support)
./02_install_docker.sh

# Step 3: Enable SSH access (if needed)
./03_enablessh.sh
```

**Switch to ai-admin user:**
```bash
su - ai-admin
cd /root  # Or wherever you copied the scripts
```

**As ai-admin:**
```bash
# Step 4: Clone repository and generate secrets
./03_clone_and_setup_env.sh

# Step 5: Configure service integrations
./04_configure_integrations.sh

# Step 6: Deploy the AI stack (THIS TAKES 10-60 MINUTES)
./05_deploy_stack.sh cpu private

# Optional Step 7: Generate Traefik reverse proxy config
./06_generate_traefik_config.sh
```

### What to Expect During Deployment

#### With Overlay2 (Fast)
- **Total time:** 10-20 minutes
- **Phase 1:** System dependencies (2 min)
- **Phase 2:** Docker installation (3 min)
- **Phase 3:** Repository clone (2 min)
- **Phase 4:** Supabase deployment (5-10 min)
- **Phase 5:** AI services deployment (10-15 min)

#### With VFS (Slow)
- **Total time:** 30-60 minutes
- Same phases, but image extraction is much slower
- Be patient during "Extracting" phases - this is normal

---

## Troubleshooting

### Issue: "dubious ownership in repository"

**Symptom:** Deployment hangs after "Pulling" images

**Cause:** Git security feature prevents operations on repositories owned by different users

**Solution:** Already fixed in scripts 03 and 05 with git safe.directory configuration

**Manual fix if needed:**
```bash
cd /opt/local-ai-packaged
git config --global --add safe.directory /opt/local-ai-packaged
git config --global --add safe.directory /opt/local-ai-packaged/supabase
```

### Issue: "disk quota exceeded"

**Symptom:** Docker fails with "failed to register layer: disk quota exceeded"

**Cause:** Not enough disk space for large AI images

**Solution:**
```bash
# On Proxmox host, increase container disk
pct resize <CTID> rootfs +90G

# Inside container, verify
df -h /
```

### Issue: Docker using VFS despite overlay2 configuration

**Check if overlay2 is actually available:**
```bash
modprobe overlay
ls /sys/module/overlay
docker info | grep "Storage Driver"
```

**If still VFS, verify LXC configuration:**
```bash
# On Proxmox host
cat /etc/pve/lxc/<CTID>.conf | grep lxc.apparmor
```

### Issue: Containers not starting

**Check Docker is running:**
```bash
systemctl status docker
docker ps -a
```

**Check logs:**
```bash
docker compose -p localai logs --tail=50
```

**Common causes:**
- Still pulling images (wait longer)
- Out of memory (increase container RAM)
- Port conflicts (check if ports 80/443/5432 are in use)

---

## Performance Notes

### Storage Driver Comparison

| Driver | Image Pull Speed | Runtime Performance | Use Case |
|--------|------------------|---------------------|----------|
| **overlay2** | ⚡⚡⚡ Fast | ⚡⚡⚡ Excellent | Production, configured LXC |
| **vfs** | 🐌 Very Slow | ⚡⚡ Good (-5%) | Default unprivileged LXC |

### Disk Space Usage

| Component | Size | Notes |
|-----------|------|-------|
| System packages | ~500MB | Debian base |
| Docker engine | ~300MB | Docker + containerd |
| Supabase images | ~4GB | 13 container images |
| AI service images | ~15GB | Ollama, Langfuse, N8N, etc. |
| Container data | Variable | Databases, volumes, logs |
| **Total minimum** | **~25GB** | Without model weights |
| **Recommended** | **90-180GB** | With room for models |

### Important Notes

1. **VFS vs Overlay2 Runtime:** Only ~5% performance difference during normal operation
2. **Image Extraction:** 10-20x difference - overlay2 extracts in seconds, VFS takes minutes per layer
3. **First Run:** Always slower (downloading images) - subsequent deployments are much faster
4. **Containerd Version:** Locked to 1.7.28-1 to avoid CVE-2025-52881 breaking LXC Docker

---

## Architecture Overview

### Deployment Flow
```
01_system_dependencies.sh  ← Install base packages
    ↓
02_install_docker.sh       ← Install Docker + detect overlay2
    ↓
03_enablessh.sh            ← Configure SSH (optional)
    ↓
03_clone_and_setup_env.sh  ← Clone repo + generate secrets
    ↓
04_configure_integrations.sh ← Configure service connections
    ↓
05_deploy_stack.sh         ← Deploy Supabase + AI services
    ↓
06_generate_traefik_config.sh ← Generate reverse proxy (optional)
```

### Key Directories
- **Scripts:** `/root/` or user home
- **Repository:** `/opt/local-ai-packaged/`
- **Docker data:** `/var/lib/docker/`
- **Supabase:** `/opt/local-ai-packaged/supabase/`

### Key Files
- **Environment:** `/opt/local-ai-packaged/.env`
- **Docker config:** `/etc/docker/daemon.json`
- **Compose file:** `/opt/local-ai-packaged/docker-compose.yml`
- **Override:** `/opt/local-ai-packaged/docker-compose.override.private.yml`

---

## Next Steps After Deployment

1. **Verify containers are running:**
   ```bash
   docker ps
   ```

2. **Check Supabase is healthy:**
   ```bash
   docker ps | grep supabase
   ```

3. **Access services:**
   - Supabase Studio: http://localhost:3000
   - N8N: http://localhost:5678
   - Flowise: http://localhost:3001
   - Langfuse: http://localhost:3002

4. **Monitor logs:**
   ```bash
   docker compose -p localai logs -f
   ```

5. **Set up Traefik (optional):**
   ```bash
   ./06_generate_traefik_config.sh
   ```

---

## Summary of Fixes Applied

### Git Ownership Error (CRITICAL FIX)
**Problem:** `start_services.py` failed silently with "dubious ownership in repository"

**Solution:** Added git safe.directory configuration to:
- [03_clone_and_setup_env.sh](03_clone_and_setup_env.sh) (lines 66-68)
- [05_deploy_stack.sh](05_deploy_stack.sh) (lines 40-42)

### Storage Driver Detection (PERFORMANCE FIX)
**Problem:** Always used slow VFS even when overlay2 was available

**Solution:** Updated [02_install_docker.sh](02_install_docker.sh) (lines 70-119) to:
- Detect if overlay2 kernel module is available
- Use overlay2 automatically in configured unprivileged containers
- Fall back to VFS if overlay2 is not available

### Disk Space Management
**Problem:** Ran out of space during image extraction

**Solution:** Documentation and warnings about disk requirements

---

## Contact & Support

- **Repository:** https://github.com/coleam00/local-ai-packaged
- **Issues:** Report deployment issues to the repository
- **This guide:** Created during deployment debugging session

---

## Appendix: Manual Overlay2 Configuration

If you want to manually switch from VFS to overlay2 after deployment:

```bash
# WARNING: This deletes all existing containers and images!

# 1. Stop Docker
systemctl stop docker

# 2. Backup important data (if any)
cp -r /var/lib/docker/volumes /backup/docker-volumes

# 3. Remove Docker data
rm -rf /var/lib/docker/*

# 4. Update daemon config
cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# 5. Start Docker
systemctl start docker

# 6. Verify
docker info | grep "Storage Driver"

# 7. Re-deploy
cd /opt/local-ai-packaged
su - ai-admin
./05_deploy_stack.sh cpu private
```

---

**End of Instructions**
