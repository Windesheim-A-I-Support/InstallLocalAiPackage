# Native Deployment Scripts Summary

**Created:** 2025-12-07
**Purpose:** Native (non-Docker) deployment scripts for shared services (containers 100-199)

## Overview

Created **11 native deployment scripts** to replace Docker-based deployments with native installations using system packages, systemd services, and proper security configurations.

## ✅ Native Scripts Created

| # | Script | Service | Container | Port | Installation Method | Status |
|---|--------|---------|-----------|------|---------------------|--------|
| 1 | `17_deploy_shared_searxng_native.sh` | SearXNG | 105 | 8080 | Python + systemd | ✅ Already existed |
| 2 | `18_deploy_shared_langfuse_native.sh` | Langfuse | 106 | 3002 | Node.js 20 + Next.js + systemd | ✅ Created |
| 3 | `19_deploy_shared_neo4j_native.sh` | Neo4j | 107 | 7474, 7687 | Apt repository + systemd | ✅ Created |
| 4 | `21_deploy_shared_n8n_native.sh` | n8n | 109 | 5678 | Node.js 20 + npm global + systemd | ✅ Created |
| 5 | `22_deploy_shared_flowise_native.sh` | Flowise | 110 | 3003 | Node.js 20 + npm global + systemd | ✅ Created |
| 6 | `23_deploy_shared_tika_native.sh` | Apache Tika | 111 | 9998 | Java JAR + systemd | ✅ Created |
| 7 | `24_deploy_shared_docling_native.sh` | Docling | 112 | 5001 | Python venv + pip + systemd | ✅ Created |
| 8 | `26_deploy_shared_libretranslate_native.sh` | LibreTranslate | 114 | 5000 | Python venv + pip + systemd | ✅ Created |
| 9 | `28_deploy_shared_gitea_native.sh` | Gitea | 120 | 3000, 22 | Binary download + systemd | ✅ Created |
| 10 | `30_deploy_shared_bookstack_native.sh` | BookStack | 116 | 80 | PHP + Apache + Composer | ✅ Created |
| 11 | `31_deploy_shared_metabase_native.sh` | Metabase | 117 | 3001 | Java JAR + systemd | ✅ Created |
| 12 | `44_deploy_shared_faster_whisper.sh` | Faster Whisper | 134 | 9001 | Python venv + pip + systemd | ✅ Already existed |

## Installation Methods Used

### 1. Node.js Applications (3 scripts)
- **Langfuse** (18): Next.js app - Clone repo, npm install, npm build, systemd
- **n8n** (21): Global npm package - npm install -g, systemd
- **Flowise** (22): Global npm package - npm install -g, systemd

**Common setup:**
- Node.js 20.x from NodeSource repository
- Dedicated system user
- PostgreSQL database for Langfuse and n8n
- Environment files for configuration
- Systemd service with security hardening

### 2. Python Applications (4 scripts)
- **SearXNG** (17): Python venv + pip
- **Docling** (24): Python venv + pip + FastAPI server
- **LibreTranslate** (26): Python venv + pip
- **Faster Whisper** (44): Python venv + pip

**Common setup:**
- Python 3 virtual environment
- Dedicated system user
- Requirements installed via pip
- Systemd service

### 3. Java Applications (3 scripts)
- **Neo4j** (19): Official Debian repository + systemd
- **Apache Tika** (23): Runnable JAR file
- **Metabase** (31): Runnable JAR file

**Common setup:**
- OpenJDK 17 JRE
- Download JAR or install from apt
- Systemd service

### 4. PHP Application (1 script)
- **BookStack** (30): PHP + Apache + Composer + PostgreSQL

**Setup:**
- Apache web server
- PHP 8.2 with required extensions
- Git clone + Composer install
- Apache virtual host

### 5. Binary Application (1 script)
- **Gitea** (120): Pre-compiled binary download

**Setup:**
- Download binary from dl.gitea.io
- Dedicated git user
- PostgreSQL database
- Systemd service

## Common Features Across All Scripts

### Security
- ✅ Dedicated system users (no root execution)
- ✅ Systemd security directives (`NoNewPrivileges`, `ProtectSystem`, `PrivateTmp`)
- ✅ File permission restrictions (600 for credentials, 750 for data)
- ✅ Secrets generated with `openssl rand`

### Configuration
- ✅ Environment files for configuration
- ✅ PostgreSQL database creation where needed
- ✅ Auto-generated passwords saved to `/root/.credentials/`
- ✅ Service binding to `0.0.0.0` for network access

### Service Management
- ✅ Systemd service files
- ✅ Auto-start on boot (`systemctl enable`)
- ✅ Auto-restart on failure (`Restart=always`)
- ✅ Proper dependency ordering (`After=network.target`)

### Update Support
- ✅ All scripts support `--update` flag
- ✅ Update preserves data and configuration
- ✅ Service restart after update

### Testing
- ✅ Wait for service startup (with timeout)
- ✅ Health check with curl
- ✅ Status verification with `systemctl is-active`

## Database Dependencies

Services requiring PostgreSQL (10.0.5.102):
1. **Langfuse** - Database: `langfuse`
2. **n8n** - Database: `n8n`
3. **Gitea** - Database: `gitea` (dedicated user)
4. **BookStack** - Database: `bookstack` (dedicated user)
5. **Metabase** - Database: `metabase` (dedicated user)

PostgreSQL credentials are read from:
- Environment variable: `POSTGRES_PASS`
- Default: `ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8=`
- Host: `10.0.5.102` (shared PostgreSQL container)

## Credentials Storage

All scripts save credentials to `/root/.credentials/<service>.txt`:
- ✅ Access URLs
- ✅ Admin usernames/passwords
- ✅ Database connection strings
- ✅ API keys/secrets
- ✅ Service management commands

Files are chmod 600 (read/write by root only)

## Container Status vs Script Availability

| Container IP | Service | Native Script | Container Status | Can Deploy? |
|--------------|---------|---------------|------------------|-------------|
| 10.0.5.105 | SearXNG | ✅ | ❌ DOWN | Need to start container |
| 10.0.5.106 | Langfuse | ✅ | ❌ DOWN | Need to start container |
| 10.0.5.107 | Neo4j | ✅ | ✅ UP | **YES - READY!** |
| 10.0.5.109 | n8n | ✅ | N/A (PER-USER) | If shared needed |
| 10.0.5.110 | Flowise | ✅ | N/A (PER-USER) | If shared needed |
| 10.0.5.111 | Tika | ✅ | ❌ DOWN | Need to start container |
| 10.0.5.112 | Docling | ✅ | ✅ UP | **YES - READY!** |
| 10.0.5.114 | LibreTranslate | ✅ | ✅ UP | **YES - READY!** |
| 10.0.5.116 | BookStack | ✅ | ❌ DOWN | Need to start container |
| 10.0.5.117 | Metabase | ✅ | ❌ DOWN | Need to start container |
| 10.0.5.120 | Gitea | ✅ | ❌ DOWN | Need to start container |
| 10.0.5.134 | Faster Whisper | ✅ | ❌ DOWN | Need to start container |

## Services Ready for Immediate Deployment

**3 services** have both native scripts AND containers that are UP and accessible:

1. **Neo4j (10.0.5.107)** - Graph database
   - Script: `19_deploy_shared_neo4j_native.sh`
   - Port: 7474 (HTTP), 7687 (Bolt)

2. **Docling (10.0.5.112)** - Document conversion
   - Script: `24_deploy_shared_docling_native.sh`
   - Port: 5001

3. **LibreTranslate (10.0.5.114)** - Translation API
   - Script: `26_deploy_shared_libretranslate_native.sh`
   - Port: 5000

These can be deployed **immediately** using:
```bash
sshpass -p 'Localbaby100!' ssh root@10.0.5.107 'bash -s' < 19_deploy_shared_neo4j_native.sh
sshpass -p 'Localbaby100!' ssh root@10.0.5.112 'bash -s' < 24_deploy_shared_docling_native.sh
sshpass -p 'Localbaby100!' ssh root@10.0.5.114 'bash -s' < 26_deploy_shared_libretranslate_native.sh
```

## Services Needing Container Start

**8 services** have native scripts but containers are DOWN in Proxmox:

1. SearXNG (105)
2. Langfuse (106)
3. Tika (111)
4. BookStack (116)
5. Metabase (117)
6. Gitea (120)
7. Faster Whisper (134)

**Action Required:** Start these containers in Proxmox, then deploy using native scripts

## Services Still Needing Native Scripts

Services that still use Docker and need native scripts:
- Whisper (113)
- MCPO (115)
- Playwright (118)
- Portainer (124)
- Formbricks (125)
- Mailserver (126)
- CRM (127)
- Matrix (128)
- Superset (129)
- DuckDB (130)
- Authentik (146)
- ComfyUI (132)
- Automatic1111 (133)
- OpenedAI Speech (135)
- And others...

## Next Steps

1. **Deploy Ready Services** - Deploy Neo4j, Docling, LibreTranslate immediately
2. **Start Containers** - Start DOWN containers in Proxmox for services with native scripts
3. **Deploy After Start** - Deploy remaining 8 services after containers are started
4. **Create More Scripts** - Create native scripts for remaining Docker-based services
5. **Update Documentation** - Update CREDENTIALS.md, DEPLOYMENT_STATUS.md after deployments

## References

### Official Documentation Used
- [Langfuse Self-Hosting](https://langfuse.com/self-hosting)
- [Neo4j Debian Installation](https://neo4j.com/docs/operations-manual/current/installation/linux/debian/)
- [Apache Tika Server](https://tika.apache.org/download.html)
- [Docling Installation](https://docling-project.github.io/docling/getting_started/installation/)
- [LibreTranslate Installation](https://docs.libretranslate.com/guides/installation/)
- [Gitea Binary Installation](https://docs.gitea.com/installation/install-from-binary)
- [BookStack Installation on Debian](https://www.bookstackapp.com/docs/admin/installation/)
- [Metabase JAR Installation](https://www.metabase.com/docs/latest/installation-and-operation/running-the-metabase-jar-file)
- [n8n Self-Hosting](https://docs.n8n.io/hosting/)
- [Flowise Self-Host](https://docs.flowiseai.com/getting-started)

## Script Locations

All native scripts are in: `/home/chris/Documents/github/InstallLocalAiPackage/`

Pattern: `{number}_deploy_shared_{service}_native.sh`

Example:
```bash
ls -1 *_native.sh
```
