#!/bin/bash
set -e

# ==============================================================================
# MARIADB NATIVE DEPLOYMENT
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
# Based on official MariaDB documentation
# Sources:
#   - https://mariadb.org/download/
#   - https://mariadb.com/kb/en/installing-mariadb-deb-files/
#   - https://mariadb.com/kb/en/mariadb-package-repository-setup-and-usage/
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.103}"
MYSQL_ROOT_PASSWORD="${2:-$(openssl rand -base64 32)}"
MYSQL_PORT="${3:-3306}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   MARIADB NATIVE DEPLOYMENT"
echo "========================================================="
echo ""
echo "This deploys:"
echo "  • MariaDB Server (native package)"
echo "  • MySQL-compatible database"
echo "  • Systemd service"
echo ""
echo "Container: ${CONTAINER_IP}"
echo "Port: ${MYSQL_PORT}"
echo ""
echo ""

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# STEP 1: INSTALL MARIADB
# ==============================================================================
echo "--> [1/5] Installing MariaDB Server..."

apt-get update
apt-get install -y mariadb-server mariadb-client

# Verify installation
MARIADB_VERSION=$(mariadb --version 2>&1 | head -n1)
echo "✅ MariaDB installed: $MARIADB_VERSION"

# ==============================================================================
# STEP 2: CONFIGURE MARIADB
# ==============================================================================
echo "--> [2/5] Configuring MariaDB..."

# Stop MariaDB to configure
systemctl stop mariadb

# Configure MariaDB to listen on all interfaces
cat > /etc/mysql/mariadb.conf.d/99-custom.cnf <<EOF
[mysqld]
# Network settings
bind-address = 0.0.0.0
port = ${MYSQL_PORT}

# Character set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# InnoDB settings
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Query cache (disabled in modern versions, for compatibility)
query_cache_type = 0
query_cache_size = 0

# Connection settings
max_connections = 200
max_allowed_packet = 64M

# Logging
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
EOF

echo "✅ Configuration updated"

# ==============================================================================
# STEP 3: START MARIADB
# ==============================================================================
echo "--> [3/5] Starting MariaDB..."

systemctl enable mariadb
systemctl start mariadb

# Wait for MariaDB to start
sleep 5

if systemctl is-active --quiet mariadb; then
    echo "✅ MariaDB is running"
else
    echo "❌ MariaDB failed to start"
    journalctl -u mariadb --no-pager -n 50
    exit 1
fi

# ==============================================================================
# STEP 4: SECURE INSTALLATION
# ==============================================================================
echo "--> [4/5] Securing MariaDB installation..."

# Set root password and secure installation
mysql <<EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Disallow root login remotely (we'll create a separate admin user)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Create admin user for remote access
CREATE USER 'dbadmin'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'dbadmin'@'%' WITH GRANT OPTION;

-- Flush privileges
FLUSH PRIVILEGES;
EOF

echo "✅ MariaDB secured"

# ==============================================================================
# STEP 5: CREATE DATABASES FOR SERVICES
# ==============================================================================
echo "--> [5/5] Creating databases for services..."

# Create databases and users for common services
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
-- BookStack database
CREATE DATABASE IF NOT EXISTS bookstack CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'bookstack'@'%' IDENTIFIED BY '$(openssl rand -base64 24)';
GRANT ALL PRIVILEGES ON bookstack.* TO 'bookstack'@'%';

-- Gitea database
CREATE DATABASE IF NOT EXISTS gitea CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'gitea'@'%' IDENTIFIED BY '$(openssl rand -base64 24)';
GRANT ALL PRIVILEGES ON gitea.* TO 'gitea'@'%';

-- n8n database
CREATE DATABASE IF NOT EXISTS n8n CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'n8n'@'%' IDENTIFIED BY '$(openssl rand -base64 24)';
GRANT ALL PRIVILEGES ON n8n.* TO 'n8n'@'%';

FLUSH PRIVILEGES;

-- Show databases
SHOW DATABASES;
EOF

echo "✅ Service databases created"

# ==============================================================================
# SAVE CREDENTIALS
# ==============================================================================
echo ""
echo "Saving credentials..."

mkdir -p /root/.credentials

# Get user passwords
BOOKSTACK_PASSWORD=$(mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -sN -e "SELECT authentication_string FROM mysql.user WHERE User='bookstack' LIMIT 1;" 2>/dev/null || echo "See credentials file")
GITEA_PASSWORD=$(mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -sN -e "SELECT authentication_string FROM mysql.user WHERE User='gitea' LIMIT 1;" 2>/dev/null || echo "See credentials file")
N8N_PASSWORD=$(mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -sN -e "SELECT authentication_string FROM mysql.user WHERE User='n8n' LIMIT 1;" 2>/dev/null || echo "See credentials file")

cat > /root/.credentials/mariadb.txt <<CRED
=== MariaDB Database Server ===

Server:
  Host: ${CONTAINER_IP}
  Port: ${MYSQL_PORT}

Root Credentials:
  Username: root
  Password: ${MYSQL_ROOT_PASSWORD}
  Connection: mysql -h ${CONTAINER_IP} -u root -p

Admin User (Remote Access):
  Username: dbadmin
  Password: ${MYSQL_ROOT_PASSWORD}
  Connection: mysql -h ${CONTAINER_IP} -u dbadmin -p
  URL: mysql://dbadmin:${MYSQL_ROOT_PASSWORD}@${CONTAINER_IP}:${MYSQL_PORT}/

Service Databases Created:

  BookStack:
    Database: bookstack
    Username: bookstack
    Password: [Run on container: grep bookstack /root/.credentials/mariadb.txt]

  Gitea:
    Database: gitea
    Username: gitea
    Password: [Run on container: grep gitea /root/.credentials/mariadb.txt]

  n8n:
    Database: n8n
    Username: n8n
    Password: [Run on container: grep n8n /root/.credentials/mariadb.txt]

Service Management:
  systemctl status mariadb
  systemctl restart mariadb
  systemctl stop mariadb

Configuration:
  Main config: /etc/mysql/mariadb.conf.d/99-custom.cnf
  Error log: /var/log/mysql/error.log
  Slow query log: /var/log/mysql/slow.log

Common Commands:
  # Connect to MySQL
  mysql -u root -p

  # Create new database
  CREATE DATABASE mydb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

  # Create new user
  CREATE USER 'myuser'@'%' IDENTIFIED BY 'password';
  GRANT ALL PRIVILEGES ON mydb.* TO 'myuser'@'%';
  FLUSH PRIVILEGES;

  # List databases
  SHOW DATABASES;

  # List users
  SELECT User, Host FROM mysql.user;

Backup:
  # Backup all databases
  mysqldump -u root -p --all-databases > backup.sql

  # Backup specific database
  mysqldump -u root -p bookstack > bookstack_backup.sql

  # Restore
  mysql -u root -p < backup.sql

Version: $(mariadb --version | head -n1)
CRED

chmod 600 /root/.credentials/mariadb.txt

echo ""
echo "========================================================="
echo "✅ MARIADB DEPLOYED SUCCESSFULLY"
echo "========================================================="
echo ""
echo "Server: ${CONTAINER_IP}:${MYSQL_PORT}"
echo ""
echo "Root Credentials:"
echo "  Username: root"
echo "  Password: ${MYSQL_ROOT_PASSWORD}"
echo ""
echo "Remote Admin:"
echo "  Username: dbadmin"
echo "  Password: ${MYSQL_ROOT_PASSWORD}"
echo ""
echo "Service Databases: bookstack, gitea, n8n"
echo ""
echo "Service Management:"
echo "  systemctl status mariadb"
echo "  systemctl restart mariadb"
echo ""
echo "Credentials saved to: /root/.credentials/mariadb.txt"
echo "========================================================="
