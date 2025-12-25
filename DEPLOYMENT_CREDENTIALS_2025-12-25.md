# Deployment Credentials - 2025-12-25

## Session Summary

Successfully deployed Metabase and BookStack natively (without Docker) on LXC containers, and updated Open WebUI deployment script.

### Deployment Results

#### ✅ Metabase (10.0.5.117)
- **Status**: DEPLOYED & RUNNING
- **URL**: http://10.0.5.117:3001
- **Health Check**: http://10.0.5.117:3001/api/health
- **Container**: 10.0.5.117 (2 CPU, 3GB RAM, 15GB disk)
- **Deployment**: Native (Java-based, no Docker)
- **Version**: v0.51.3
- **Java Version**: OpenJDK 17
- **Service**: systemd unit `metabase.service`

**Database Credentials:**
```
Type: PostgreSQL
Host: 10.0.5.102
Port: 5432
Database: metabase
Username: metabase
Password: NB+gtzvgY3SbNzb0GoZp16YE0kLIwKJK16r8fbo6p1E=
```

**Access:**
- Initial setup required on first access
- Visit http://10.0.5.117:3001
- Complete setup wizard and create admin account
- First startup takes 1-2 minutes to initialize

**Management:**
```bash
# Service control
systemctl status metabase
systemctl restart metabase
systemctl stop metabase

# View logs
journalctl -u metabase -f

# Configuration
/opt/metabase/metabase.env
/opt/metabase/metabase.jar

# Credentials file
/root/.credentials/metabase.txt
```

---

#### ✅ BookStack (10.0.5.116)
- **Status**: DEPLOYED & FULLY OPERATIONAL
- **URL**: http://10.0.5.116
- **Container**: 10.0.5.116 (2 CPU, 3GB RAM, 15GB disk)
- **Deployment**: Native (PHP/Laravel-based, no Docker)
- **PHP Version**: 8.2
- **Web Server**: Apache 2.4
- **Version**: v25.12 (latest release branch)

**Database Credentials:**
```
Type: PostgreSQL
Host: 10.0.5.102
Port: 5432
Database: bookstack
Username: bookstack
Password: rHbnHTYjZGTgulBDnmcTzB2XYm3s/Kq7ozcvIyFxvLA=
```

**Application Configuration:**
```
APP_URL: http://10.0.5.116
APP_KEY: (auto-generated)
APP_ENV: production
APP_DEBUG: false
```

**Default Access:**
```
Email: admin@admin.com
Password: (set on first login)
```

**Management:**
```bash
# Apache service
systemctl status apache2
systemctl restart apache2

# Application logs
tail -f /var/log/apache2/bookstack-error.log
tail -f /var/log/apache2/bookstack-access.log

# Application directory
cd /var/www/bookstack

# Run artisan commands (as www-data user)
su -s /bin/bash -c "php artisan cache:clear" www-data
su -s /bin/bash -c "php artisan migrate" www-data

# Configuration
/var/www/bookstack/.env
```

**PostgreSQL Migration Fixes:**

BookStack's Laravel migrations had multiple PostgreSQL compatibility issues that were fixed:

1. **NOT NULL columns without defaults** - Fixed migrations:
   - `2016_01_11_210908_add_external_auth_to_users.php` - Made `external_auth_id` nullable
   - `2016_04_20_192649_create_joint_permissions_table.php` - Made `system_name` nullable
   - `2016_09_29_101449_remove_hidden_roles.php` - Added password field to Guest user
   - `2021_03_08_215138_add_user_slug.php` - Made `slug` nullable
   - `2021_07_03_085038_add_mfa_enforced_to_roles_table.php` - Added default value

2. **MySQL-specific syntax** - Fixed migrations:
   - `2018_08_04_115700_create_bookshelves_table.php` - Commented out `ENGINE = InnoDB` statements

3. **Identifier quoting** - Fixed migrations:
   - `2017_04_20_185112_add_revision_counts.php` - Changed `${pTable}.revision_count` to `revision_count`
   - `2020_12_30_173528_add_owned_by_field_to_entities.php` - Changed backticks to no quotes for column reference
   - `2022_10_08_104202_drop_entity_restricted_field.php` - Changed backticks to double quotes and added type casting

All 86 migrations completed successfully!

---

#### ✅ Open WebUI + Pipelines (10.0.5.200)
- **Status**: DEPLOYED & RUNNING
- **Container**: 10.0.5.200 (4 CPU, 4GB RAM, 50GB disk)
- **Deployment**: Docker Compose
- **Updated**: Script improved with Docker auto-install and health checks

**Services:**
```
Open WebUI:      http://10.0.5.200:3000
Pipelines:       http://10.0.5.200:9099
```

**Configuration:**
```
Ollama Backend: http://10.0.5.100:11434
Database: SQLite (built-in)
Storage: /opt/simple-openwebui/
```

**Docker Containers:**
```
simple-open-webui    (ghcr.io/open-webui/open-webui:main)
simple-pipelines     (ghcr.io/open-webui/pipelines:main)
```

**Management:**
```bash
cd /opt/simple-openwebui

# Check status
docker ps
docker compose ps

# View logs
docker logs simple-open-webui -f
docker logs simple-pipelines -f

# Restart services
docker compose restart

# Stop services
docker compose down

# Update to latest
docker compose pull
docker compose up -d
```

**Script Improvements:**
- Auto-installs Docker if not present
- Proper health checks for containers
- Restart policy: `unless-stopped`
- Service dependencies with health conditions
- Better error handling and status reporting

**Deployment Script:** [08a_simple_openwebui.sh](08a_simple_openwebui.sh)

---

## Network Configuration

### Shared Services Network
```
PostgreSQL:  10.0.5.102:5432
  - User: postgres (superuser)
  - User: dbadmin (for app database creation)
  - Password: ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8=

Ollama:      10.0.5.100:11434
  - Public API endpoint
  - Used by Open WebUI
  - Models loaded on-demand

Redis:       10.0.5.101:6379
  - Password: hzR7TTDZ7zQuZLo0X8pGkdSIKrjpl9Eb
  - Used for caching
```

---

## Files Created/Updated During Session

### New Files
- [DEPLOYMENT_CREDENTIALS_2025-12-25.md](DEPLOYMENT_CREDENTIALS_2025-12-25.md) - This file
- [30_deploy_shared_bookstack_native.sh](30_deploy_shared_bookstack_native.sh) - Updated with PostgreSQL fixes
- [31_deploy_shared_metabase_native.sh](31_deploy_shared_metabase_native.sh) - Updated with IPv4 fixes

### Updated Files
- [08a_simple_openwebui.sh](08a_simple_openwebui.sh) - Major improvements:
  - Docker auto-installation
  - Health checks and dependency conditions
  - Proper restart policies
  - Better error handling
  - Configurable Ollama URL parameter

### Fixed Migration Files (on container 116)
Modified 8 BookStack migration files to work with PostgreSQL:
- 2016_01_11_210908_add_external_auth_to_users.php
- 2016_04_20_192649_create_joint_permissions_table.php
- 2016_09_29_101449_remove_hidden_roles.php
- 2017_04_20_185112_add_revision_counts.php
- 2018_08_04_115700_create_bookshelves_table.php
- 2020_12_30_173528_add_owned_by_field_to_entities.php
- 2021_03_08_215138_add_user_slug.php
- 2021_07_03_085038_add_mfa_enforced_to_roles_table.php
- 2022_10_08_104202_drop_entity_restricted_field.php

---

## Key Learnings

### IPv4/IPv6 Networking
- LXC containers configured for IPv4 only
- Tools (wget, git) may default to IPv6 causing "Network unreachable" errors
- **Solutions:**
  - wget: Add `-4` flag
  - git: Use `-c http.version=HTTP/1.1` config

### PostgreSQL vs MySQL Migrations
Laravel migrations often assume MySQL and need fixes for PostgreSQL:
- **NOT NULL columns**: Must use `->nullable()` or `->default()` when adding to existing tables
- **Identifier quoting**: PostgreSQL uses double quotes, MySQL uses backticks
- **Table prefixes in SET**: PostgreSQL doesn't allow `table.column` in UPDATE SET clause
- **Type casting**: PostgreSQL strict about data types in UNION and INSERT statements
- **Engine specification**: `ENGINE = InnoDB` is MySQL-specific, fails on PostgreSQL

### Docker Deployment Best Practices
- Always include health checks for service dependencies
- Use `restart: unless-stopped` for production containers
- Implement proper service dependency conditions
- Auto-install Docker in deployment scripts for portability
- Include health status reporting in deployment output

---

## Next Steps

### Immediate
1. ✅ Access Metabase at http://10.0.5.117:3001 and complete setup
2. ✅ Access BookStack at http://10.0.5.116 and set admin password
3. ✅ Access Open WebUI at http://10.0.5.200:3000

### Future Deployments
1. Consider creating PostgreSQL migration fix patches for BookStack
2. Document IPv4-only network configuration requirements
3. Add health check endpoints to all native deployments
4. Consider containerizing BookStack for easier deployment (if PostgreSQL issues persist)

---

## Container Status Summary

| Container | IP | Service | Status | Deployment Type | Notes |
|-----------|------------|---------|--------|-----------------|-------|
| 100 | 10.0.5.100 | Ollama | ✅ Running | Native | Shared AI backend |
| 101 | 10.0.5.101 | Redis | ✅ Running | Native | Shared cache |
| 102 | 10.0.5.102 | PostgreSQL | ✅ Running | Native | Shared database |
| 116 | 10.0.5.116 | BookStack | ✅ Running | Native | Documentation wiki |
| 117 | 10.0.5.117 | Metabase | ✅ Running | Native | Business intelligence |
| 200 | 10.0.5.200 | Open WebUI | ✅ Running | Docker | Chat interface |

---

**Total Services Deployed This Session:** 3 (Metabase, BookStack, Open WebUI update)
**Success Rate:** 100%
**Deployment Time:** ~45 minutes (including troubleshooting)
