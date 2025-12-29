#!/bin/bash
set -e

# ==============================================================================
# SHARED MYSQL/MARIADB DEPLOYMENT
# ==============================================================================
# Based on official MariaDB Docker documentation
# Sources:
#   - https://mariadb.com/kb/en/installing-and-using-mariadb-via-docker/
#   - https://mariadb.com/kb/en/setting-up-a-lamp-stack-with-docker-compose/
#   - https://hub.docker.com/_/mariadb
#   - https://github.com/MariaDB/mariadb-docker/tree/master/examples
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.103}"
MYSQL_ROOT_PASSWORD="${2:-$(openssl rand -base64 32)}"
STACK_DIR="/opt/shared-mysql"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   SHARED MYSQL/MARIADB DEPLOYMENT"
echo "========================================================="
echo ""
echo "This deploys:"
echo "  • MariaDB LTS (Long Term Support)"
echo "  • Docker Compose with production settings"
echo "  • Persistent data volumes"
echo "  • Automatic restart policy"
echo ""
echo "Container: ${CONTAINER_IP}"
echo "Port: 3306"
echo ""
echo ""

# ==============================================================================
# STEP 0: CHECK DOCKER INSTALLATION
# ==============================================================================
echo "--> [0/5] Checking Docker installation..."

if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker not found. Installing Docker..."

    # Update package index
    apt-get update

    # Install prerequisites
    apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Verify docker compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Error: docker compose plugin not available"
    echo "Please install docker-compose-plugin manually"
    exit 1
fi

echo "✅ Docker prerequisites satisfied"

# ==============================================================================
# STEP 1: CREATE DIRECTORY STRUCTURE
# ==============================================================================
echo "--> [1/5] Creating directory structure..."
mkdir -p "$STACK_DIR"
cd "$STACK_DIR"

mkdir -p data
mkdir -p logs
mkdir -p conf

echo "✅ Directory structure created"

# ==============================================================================
# STEP 2: CREATE MYSQL CONFIGURATION
# ==============================================================================
echo "--> [2/5] Creating MySQL configuration..."

cat > conf/my.cnf <<'EOF'
[mysqld]
# Character set and collation
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# Performance settings
max_connections=200
innodb_buffer_pool_size=256M
innodb_log_file_size=64M
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT

# Binary logging (for backups and replication)
log_bin=mysql-bin
binlog_format=ROW
expire_logs_days=7

# Query logging (disable in production for performance)
# general_log=1
# general_log_file=/var/log/mysql/general.log

# Slow query log
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2

# Error log
log_error=/var/log/mysql/error.log

# Skip DNS lookups for faster connections
skip-name-resolve

[client]
default-character-set=utf8mb4
EOF

echo "✅ MySQL configuration created"

# ==============================================================================
# STEP 3: CREATE DOCKER COMPOSE FILE
# ==============================================================================
echo "--> [3/5] Creating docker-compose.yml..."

cat > docker-compose.yml <<EOF
version: '3.8'

services:
  mariadb:
    image: mariadb:lts
    container_name: shared-mysql
    restart: always
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      # Enable remote connections
      MYSQL_ROOT_HOST: '%'
      # Set timezone
      TZ: 'UTC'
    volumes:
      # Data persistence
      - ./data:/var/lib/mysql
      # Log files
      - ./logs:/var/log/mysql
      # Custom configuration
      - ./conf/my.cnf:/etc/mysql/conf.d/custom.cnf:ro
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    networks:
      - mysql-network

networks:
  mysql-network:
    driver: bridge
EOF

echo "✅ docker-compose.yml created"

# ==============================================================================
# STEP 4: STOP EXISTING CONTAINERS (if any)
# ==============================================================================
echo "--> [4/5] Stopping existing containers (if any)..."
docker compose down 2>/dev/null || true
echo "✅ Cleanup complete"

# ==============================================================================
# STEP 5: DEPLOY MYSQL
# ==============================================================================
echo "--> [5/5] Deploying MariaDB..."
echo ""
echo "⚠️  This will pull MariaDB Docker image (~400MB)"
echo ""

# Deploy the stack
docker compose pull
docker compose up -d

# Wait for MySQL to be healthy
echo ""
echo "Waiting for MySQL to become healthy..."
sleep 15

# Check container status
MYSQL_STATUS=$(docker inspect -f '{{.State.Health.Status}}' shared-mysql 2>/dev/null || echo "unknown")

echo ""
echo "Container Health Status: $MYSQL_STATUS"
echo ""

# Test connection
echo "Testing MySQL connection..."
sleep 5

if docker exec shared-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT VERSION();" &>/dev/null; then
    MYSQL_VERSION=$(docker exec shared-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT VERSION();" 2>/dev/null | tail -n1)
    echo "✅ MySQL connection successful: $MYSQL_VERSION"
else
    echo "⚠️  MySQL still initializing, connection test skipped"
fi

# ==============================================================================
# SAVE CREDENTIALS
# ==============================================================================
echo ""
echo "Saving credentials..."

mkdir -p /root/.credentials
cat > /root/.credentials/mysql.txt <<CRED
=== Shared MySQL/MariaDB Credentials ===
URL: ${CONTAINER_IP}:3306

Root User:
  Username: root
  Password: ${MYSQL_ROOT_PASSWORD}

Connection String:
  mysql -h ${CONTAINER_IP} -u root -p'${MYSQL_ROOT_PASSWORD}'

Docker Management:
  cd ${STACK_DIR}
  docker compose ps
  docker compose logs -f
  docker compose restart
  docker compose down

Container:
  docker exec -it shared-mysql mysql -uroot -p'${MYSQL_ROOT_PASSWORD}'
  docker logs shared-mysql -f

Health Check:
  docker inspect shared-mysql | grep Health -A 10

Configuration:
  Data: ${STACK_DIR}/data
  Logs: ${STACK_DIR}/logs
  Config: ${STACK_DIR}/conf/my.cnf

Create Database Example:
  docker exec -it shared-mysql mysql -uroot -p'${MYSQL_ROOT_PASSWORD}' -e "
    CREATE DATABASE myapp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER 'myapp'@'%' IDENTIFIED BY 'password';
    GRANT ALL PRIVILEGES ON myapp.* TO 'myapp'@'%';
    FLUSH PRIVILEGES;
  "

Backup:
  docker exec shared-mysql mysqldump -uroot -p'${MYSQL_ROOT_PASSWORD}' --all-databases > backup.sql

Restore:
  docker exec -i shared-mysql mysql -uroot -p'${MYSQL_ROOT_PASSWORD}' < backup.sql
CRED

chmod 600 /root/.credentials/mysql.txt

echo ""
echo "========================================================="
echo "✅ SHARED MYSQL/MARIADB DEPLOYED"
echo "========================================================="
echo ""
echo "Services are starting up. This may take 30-60 seconds."
echo ""
echo "Access your MySQL at: ${CONTAINER_IP}:3306"
echo ""
echo "Root Credentials:"
echo "  Username: root"
echo "  Password: ${MYSQL_ROOT_PASSWORD}"
echo ""
echo "Connection test:"
echo "  mysql -h ${CONTAINER_IP} -u root -p'${MYSQL_ROOT_PASSWORD}'"
echo ""
echo "Docker container:"
echo "  docker exec -it shared-mysql mysql -uroot -p'${MYSQL_ROOT_PASSWORD}'"
echo ""
echo "To check status:"
echo "  docker ps"
echo "  docker logs shared-mysql -f"
echo ""
echo "To check health:"
echo "  docker inspect shared-mysql | grep Health -A 10"
echo ""
echo "To stop:"
echo "  cd $STACK_DIR && docker compose down"
echo ""
echo "To restart:"
echo "  cd $STACK_DIR && docker compose restart"
echo ""
echo "Credentials saved to: /root/.credentials/mysql.txt"
echo "Stack location: $STACK_DIR"
echo ""
echo "Next: Deploy BookStack using 30_deploy_shared_bookstack_mysql.sh"
echo "========================================================="
