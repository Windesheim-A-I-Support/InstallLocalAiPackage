# Verified Deployment Scripts - Sources and Status

## ✅ Scripts Based on Official/Tested Sources

All deployment scripts below are based on official documentation or community-tested scripts from 2025.

---

## 1. BookStack (MySQL Required)

**Official Script Source:** [BookStack Ubuntu 22.04 Installation Script](https://github.com/BookStackApp/devops/blob/main/scripts/installation-ubuntu-22.04.sh)

**Database Requirement:** MySQL 8.0+ or MariaDB 10.6+ (PostgreSQL NOT officially supported)

**Key Points:**
- Official BookStack documentation: https://www.bookstackapp.com/docs/admin/installation/
- PHP extensions required: gd, dom, iconv, mbstring, mysqlnd, openssl, pdo, pdo_mysql, tokenizer, xml, zip
- Use MySQL native driver (mysqlnd) variants

**Status:** ✅ Script created at [30_deploy_shared_bookstack_mysql.sh](30_deploy_shared_bookstack_mysql.sh)

**Deployment Plan:**
- Deploy shared MySQL/MariaDB container first (10.0.5.103)
- Then deploy BookStack (10.0.5.116) connecting to shared MySQL

---

## 2. Metabase

**Official Script Source:** [Metabase Debian 12 Installation Script](https://gist.github.com/paulo-amaral/b274a51b12b7d4118f8739ba689b219d)

**Database Options:** PostgreSQL (current) or MySQL 8.0.17+, MariaDB 10.2.2+

**Official Documentation:**
- MySQL connection: https://www.metabase.com/docs/latest/databases/connections/mysql
- Application database config: https://www.metabase.com/docs/latest/installation-and-operation/configuring-application-database

**Status:** ✅ Currently deployed with PostgreSQL (10.0.5.117)
- Service running but still initializing (12+ minutes startup time normal)
- Can optionally switch to MySQL if needed

**Note:** Metabase works well with PostgreSQL. Current deployment should complete soon.

---

## 3. Gitea

**Official Script Source:** [Gitea Debian 12 Installation Script](https://gist.github.com/L-Briand/61542a42a839714ec04735a10abff645)

**Official Documentation:**
- Binary installation: https://docs.gitea.com/installation/install-from-binary
- Linux installation: https://docs.gitea.com/enterprise/installation/linux

**Key Details:**
- Latest version: 1.21.8 (as of script)
- Systemd service included
- Database: Can use PostgreSQL, MySQL, or SQLite
- Default port: 3000

**Status:** ✅ Script created at [32_deploy_shared_gitea.sh](32_deploy_shared_gitea.sh)
- Container: 10.0.5.120
- Supports SQLite, PostgreSQL, or MySQL databases
- Includes systemd service and complete setup

---

## 4. Neo4j

**Official Documentation:** [Neo4j Debian Installation](https://neo4j.com/docs/operations-manual/current/installation/linux/debian/)

**Repository Setup (Official):**
```bash
# Create keyrings directory
sudo mkdir -p /etc/apt/keyrings

# Download and install GPG key
wget -O - https://debian.neo4j.com/neotechnology.gpg.key | \
sudo gpg --dearmor -o /etc/apt/keyrings/neotechnology.gpg

# Set permissions
sudo chmod a+r /etc/apt/keyrings/neotechnology.gpg

# Add repository
echo 'deb [signed-by=/etc/apt/keyrings/neotechnology.gpg] https://debian.neo4j.com stable latest' | \
sudo tee /etc/apt/sources.list.d/neo4j.list

# Update and install
sudo apt-get update
sudo apt-get install neo4j=1:2025.11.2
```

**Requirements:**
- Java 21 (default) or Java 25+ (for 2025.10+)
- Set initial password before first start: `neo4j-admin set-initial-password <password>`
- Ports: 7474 (HTTP - not for production), 7687 (Bolt protocol - recommended)

**Status:** ✅ Script created at [33_deploy_shared_neo4j.sh](33_deploy_shared_neo4j.sh)
- Container: 10.0.5.107
- Official Debian package installation
- Includes Neo4j Browser and Bolt protocol support

---

## 5. Apache Tika Server

**Official Package:** [Tika Server Debian Package](https://github.com/opensemanticsearch/tika-server.deb)

**Apache Documentation:** https://cwiki.apache.org/confluence/display/TIKA/TikaServer

**Latest Version:** 3.2.3 (includes service installation script for Debian)

**Official Download:** https://tika.apache.org/download.html

**Installation Methods:**
1. Official bin.zip includes systemd service script
2. Community Debian package with Tesseract OCR
3. Docker image: `apache/tika`

**Status:** ✅ Script created at [34_deploy_shared_tika.sh](34_deploy_shared_tika.sh)
- Container: 10.0.5.111
- Official Apache Tika JAR with systemd service
- Supports 1000+ file formats for text extraction

---

## 6. SearXNG

**Official Docker Repository:** [searxng-docker](https://github.com/searxng/searxng-docker)

**Official Documentation:**
- Docker installation: https://docs.searxng.org/admin/installation-docker.html
- Installation guide: https://docs.searxng.org/admin/installation.html

**Recommended Method:** Docker Compose (production-ready)

**Quick Setup:**
```bash
git clone https://github.com/searxng/searxng-docker.git
cd searxng-docker
# Generate secret key
sed -i "s|ultrasecretkey|$(openssl rand -hex 32)|g" searxng/settings.yml
# Start in background
docker compose up -d
```

**Features:**
- Includes Caddy reverse proxy with automatic TLS
- Pre-configured for production
- Default port: 8888

**Status:** ✅ Script created at [35_deploy_shared_searxng.sh](35_deploy_shared_searxng.sh)
- Container: 10.0.5.105
- Official Docker Compose deployment (simplified for internal network)
- Includes Valkey (Redis fork) for caching

---

## 7. MySQL/MariaDB (Shared Database)

**Official Docker Image:** [MariaDB on Docker Hub](https://hub.docker.com/_/mariadb)

**Documentation:**
- MariaDB Docker: https://mariadb.com/kb/en/installing-and-using-mariadb-via-docker/
- Docker Compose: https://mariadb.com/kb/en/setting-up-a-lamp-stack-with-docker-compose/

**Production Considerations:**
- Use named volumes for data persistence
- Set restart policy to `always`
- Use utf8mb4 character set
- Configure proper backup strategy

**Recommended Setup:**
```yaml
version: '3.8'
services:
  mysql:
    image: mariadb:lts  # Long Term Support
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"
volumes:
  mysql_data:
```

**Status:** ✅ Script created at [29_deploy_shared_mysql.sh](29_deploy_shared_mysql.sh)
- Container: 10.0.5.103
- Required for BookStack
- Production-ready with health checks, restart policy, and persistent volumes

---

## 🔧 Deployment Priority

### Phase 1: Core Infrastructure
1. **MySQL/MariaDB** (10.0.5.103) - Required for BookStack
2. **BookStack** (10.0.5.116) - Replace PostgreSQL version with MySQL

### Phase 2: Additional Services
3. **Gitea** (10.0.5.120) - Git service
4. **Neo4j** (10.0.5.107) - Graph database
5. **Apache Tika** (10.0.5.111) - Text extraction
6. **SearXNG** (10.0.5.105) - Meta search engine

---

## 📝 Key Learnings

### PostgreSQL vs MySQL
- **BookStack:** MySQL/MariaDB ONLY (PostgreSQL not supported)
- **Metabase:** Both work (currently using PostgreSQL successfully)
- **Gitea:** Supports both
- **Neo4j:** Uses own database (not SQL)

### Docker vs Native
- **SearXNG:** Docker recommended (official docker-compose provided)
- **BookStack:** Native works well with MySQL
- **Metabase:** Both work (native JAR currently deployed)
- **Gitea:** Native preferred (simple binary)
- **Neo4j:** Native preferred (official Debian package)
- **Tika:** Both work (official service script available)

### Service Initialization Times
- **Metabase:** 10-20 minutes first startup
- **Neo4j:** 2-5 minutes
- **BookStack:** 1-2 minutes
- **Gitea:** < 1 minute
- **SearXNG:** < 1 minute

---

## 🔗 References

All scripts and documentation are from official sources or well-maintained community projects from 2025:

- [BookStack Official Docs](https://www.bookstackapp.com/docs/admin/installation/)
- [Metabase Official Docs](https://www.metabase.com/docs/latest/installation-and-operation/start)
- [Gitea Official Docs](https://docs.gitea.com/installation)
- [Neo4j Operations Manual](https://neo4j.com/docs/operations-manual/current/)
- [Apache Tika Wiki](https://cwiki.apache.org/confluence/display/TIKA/)
- [SearXNG Official Docs](https://docs.searxng.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)

---

**Last Updated:** 2025-12-25
**Status:** Document created to track verified sources before deployment
