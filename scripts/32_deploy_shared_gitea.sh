#!/bin/bash
set -e

# ==============================================================================
# GITEA NATIVE DEPLOYMENT
# ==============================================================================
# Based on official Gitea binary installation documentation
# Sources:
#   - https://docs.gitea.com/installation/install-from-binary
#   - https://gist.github.com/L-Briand/61542a42a839714ec04735a10abff645
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.120}"
GITEA_VERSION="${2:-1.22.7}"  # Latest stable as of Dec 2025
DB_TYPE="${3:-sqlite3}"       # sqlite3, postgres, or mysql
DB_HOST="${4:-10.0.5.102}"    # PostgreSQL host (if using postgres)
DB_PASS="${5:-}"              # Database password (if using postgres/mysql)

GITEA_USER="git"
GITEA_HOME="/home/git"
GITEA_WORK_DIR="/var/lib/gitea"
GITEA_CONFIG_DIR="/etc/gitea"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   GITEA DEPLOYMENT"
echo "========================================================="
echo ""
echo "This deploys:"
echo "  • Gitea v${GITEA_VERSION}"
echo "  • Git version control service"
echo "  • Systemd service"
echo "  • Database: ${DB_TYPE}"
echo ""
echo "Container: ${CONTAINER_IP}"
echo "Access at: http://${CONTAINER_IP}:3000"
echo ""
echo ""

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# STEP 1: INSTALL DEPENDENCIES
# ==============================================================================
echo "--> [1/8] Installing dependencies..."

apt-get update
apt-get install -y git wget curl

# Install database client if needed
if [ "$DB_TYPE" = "postgres" ]; then
    apt-get install -y postgresql-client
elif [ "$DB_TYPE" = "mysql" ]; then
    apt-get install -y mysql-client
fi

echo "✅ Dependencies installed"

# ==============================================================================
# STEP 2: CREATE GITEA USER
# ==============================================================================
echo "--> [2/8] Creating Gitea user..."

if ! id -u "$GITEA_USER" >/dev/null 2>&1; then
    adduser --system --shell /bin/bash --gecos 'Git Version Control' \
            --group --disabled-password --home "$GITEA_HOME" "$GITEA_USER"
    echo "✅ User created: $GITEA_USER"
else
    echo "ℹ️  User already exists: $GITEA_USER"
fi

# ==============================================================================
# STEP 3: CREATE DIRECTORY STRUCTURE
# ==============================================================================
echo "--> [3/8] Creating directory structure..."

mkdir -p "$GITEA_WORK_DIR"/{custom,data,log}
chown -R "$GITEA_USER":"$GITEA_USER" "$GITEA_WORK_DIR"
chmod -R 750 "$GITEA_WORK_DIR"

mkdir -p "$GITEA_CONFIG_DIR"
chown root:"$GITEA_USER" "$GITEA_CONFIG_DIR"
chmod 770 "$GITEA_CONFIG_DIR"

echo "✅ Directory structure created"

# ==============================================================================
# STEP 4: DOWNLOAD GITEA BINARY
# ==============================================================================
echo "--> [4/8] Downloading Gitea v${GITEA_VERSION}..."

DOWNLOAD_URL="https://dl.gitea.com/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64"

# Use IPv4 to avoid network unreachable errors
wget -4 -O /usr/local/bin/gitea "$DOWNLOAD_URL"
chmod +x /usr/local/bin/gitea

# Verify download
if [ ! -f /usr/local/bin/gitea ]; then
    echo "❌ Error: Failed to download Gitea binary"
    exit 1
fi

GITEA_INSTALLED_VERSION=$(/usr/local/bin/gitea --version | head -n1)
echo "✅ Gitea downloaded: $GITEA_INSTALLED_VERSION"

# ==============================================================================
# STEP 5: SETUP DATABASE (if using PostgreSQL/MySQL)
# ==============================================================================
if [ "$DB_TYPE" = "postgres" ] || [ "$DB_TYPE" = "mysql" ]; then
    echo "--> [5/8] Setting up database..."

    # Generate database password if not provided
    if [ -z "$DB_PASS" ]; then
        DB_PASS="$(openssl rand -base64 32)"
    fi

    if [ "$DB_TYPE" = "postgres" ]; then
        # Prompt for PostgreSQL admin password
        echo "Enter PostgreSQL password for dbadmin user:"
        read -s PG_ADMIN_PASS

        PGPASSWORD="$PG_ADMIN_PASS" psql -h "$DB_HOST" -U dbadmin -d postgres <<EOF
CREATE DATABASE gitea WITH ENCODING 'UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8';
CREATE USER gitea WITH PASSWORD '${DB_PASS}';
GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;
EOF
        echo "✅ PostgreSQL database created"
    elif [ "$DB_TYPE" = "mysql" ]; then
        # Prompt for MySQL root password
        echo "Enter MySQL root password:"
        read -s MYSQL_ROOT_PASS

        mysql -h "$DB_HOST" -u root -p"$MYSQL_ROOT_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS gitea CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'gitea'@'%' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON gitea.* TO 'gitea'@'%';
FLUSH PRIVILEGES;
EOF
        echo "✅ MySQL database created"
    fi
else
    echo "--> [5/8] Using SQLite database (no setup needed)"
fi

# ==============================================================================
# STEP 6: CREATE SYSTEMD SERVICE
# ==============================================================================
echo "--> [6/8] Creating systemd service..."

cat > /etc/systemd/system/gitea.service <<EOF
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target

[Service]
Type=simple
User=$GITEA_USER
Group=$GITEA_USER
WorkingDirectory=$GITEA_WORK_DIR
ExecStart=/usr/local/bin/gitea web -c $GITEA_CONFIG_DIR/app.ini
Restart=always
RestartSec=2s
Environment=USER=$GITEA_USER HOME=$GITEA_HOME GITEA_WORK_DIR=$GITEA_WORK_DIR

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Systemd service created"

# ==============================================================================
# STEP 7: CREATE INITIAL CONFIGURATION
# ==============================================================================
echo "--> [7/8] Creating initial configuration..."

if [ "$DB_TYPE" = "postgres" ]; then
    DB_CONFIG="[database]
DB_TYPE  = postgres
HOST     = $DB_HOST:5432
NAME     = gitea
USER     = gitea
PASSWD   = $DB_PASS
SSL_MODE = disable"
elif [ "$DB_TYPE" = "mysql" ]; then
    DB_CONFIG="[database]
DB_TYPE = mysql
HOST    = $DB_HOST:3306
NAME    = gitea
USER    = gitea
PASSWD  = $DB_PASS"
else
    DB_CONFIG="[database]
DB_TYPE = sqlite3
PATH    = $GITEA_WORK_DIR/data/gitea.db"
fi

cat > "$GITEA_CONFIG_DIR/app.ini" <<EOF
APP_NAME = Gitea: Git with a cup of tea
RUN_MODE = prod

[server]
DOMAIN           = $CONTAINER_IP
HTTP_PORT        = 3000
ROOT_URL         = http://$CONTAINER_IP:3000/
DISABLE_SSH      = false
SSH_DOMAIN       = $CONTAINER_IP
SSH_PORT         = 22
LFS_START_SERVER = true
OFFLINE_MODE     = false

$DB_CONFIG

[repository]
ROOT = $GITEA_WORK_DIR/data/gitea-repositories

[security]
INSTALL_LOCK   = false
SECRET_KEY     = $(openssl rand -base64 64 | tr -d '\n')
INTERNAL_TOKEN = $(openssl rand -base64 105 | tr -d '\n')

[service]
DISABLE_REGISTRATION              = false
REQUIRE_SIGNIN_VIEW               = false
REGISTER_EMAIL_CONFIRM            = false
ENABLE_NOTIFY_MAIL                = false
ALLOW_ONLY_EXTERNAL_REGISTRATION  = false
ENABLE_CAPTCHA                    = false
DEFAULT_KEEP_EMAIL_PRIVATE        = false
DEFAULT_ALLOW_CREATE_ORGANIZATION = true
NO_REPLY_ADDRESS                  = noreply.$CONTAINER_IP

[mailer]
ENABLED = false

[session]
PROVIDER = file

[log]
MODE      = file
LEVEL     = info
ROOT_PATH = $GITEA_WORK_DIR/log

[other]
SHOW_FOOTER_VERSION = true
EOF

# Set proper permissions
chown root:"$GITEA_USER" "$GITEA_CONFIG_DIR/app.ini"
chmod 640 "$GITEA_CONFIG_DIR/app.ini"

echo "✅ Configuration created"

# ==============================================================================
# STEP 8: START GITEA SERVICE
# ==============================================================================
echo "--> [8/8] Starting Gitea service..."

systemctl daemon-reload
systemctl enable gitea
systemctl start gitea

# Wait for service to start
sleep 5

# Check service status
if systemctl is-active --quiet gitea; then
    echo "✅ Gitea service is running"
else
    echo "⚠️  Gitea service may still be starting"
fi

# ==============================================================================
# SAVE CREDENTIALS
# ==============================================================================
echo ""
echo "Saving credentials..."

mkdir -p /root/.credentials
cat > /root/.credentials/gitea.txt <<CRED
=== Gitea Credentials ===
URL: http://${CONTAINER_IP}:3000

Initial Setup:
  • Visit the URL above
  • Complete the installation wizard
  • Create your admin account

Database:
  Type: ${DB_TYPE}
$(if [ "$DB_TYPE" != "sqlite3" ]; then
  echo "  Host: ${DB_HOST}"
  echo "  Database: gitea"
  echo "  Username: gitea"
  echo "  Password: ${DB_PASS}"
fi)

Service Management:
  systemctl status gitea
  systemctl restart gitea
  systemctl stop gitea
  journalctl -u gitea -f

Configuration:
  Config: $GITEA_CONFIG_DIR/app.ini
  Work Dir: $GITEA_WORK_DIR
  Logs: $GITEA_WORK_DIR/log

Git Repositories:
  Location: $GITEA_WORK_DIR/data/gitea-repositories

SSH Access:
  ssh git@${CONTAINER_IP}

Gitea CLI:
  sudo -u git gitea --config $GITEA_CONFIG_DIR/app.ini admin user list
CRED

chmod 600 /root/.credentials/gitea.txt

echo ""
echo "========================================================="
echo "✅ GITEA DEPLOYED SUCCESSFULLY"
echo "========================================================="
echo ""
echo "Access Gitea at: http://${CONTAINER_IP}:3000"
echo ""
echo "Next Steps:"
echo "  1. Open http://${CONTAINER_IP}:3000 in your browser"
echo "  2. Complete the installation wizard"
echo "  3. Create your admin account"
echo ""
echo "Database: $DB_TYPE"
if [ "$DB_TYPE" != "sqlite3" ]; then
    echo "  Host: $DB_HOST"
    echo "  Database: gitea"
fi
echo ""
echo "Service Management:"
echo "  systemctl status gitea"
echo "  systemctl restart gitea"
echo "  journalctl -u gitea -f"
echo ""
echo "Credentials saved to: /root/.credentials/gitea.txt"
echo "========================================================="
