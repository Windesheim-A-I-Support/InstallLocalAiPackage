#!/bin/bash
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

set -e

# Shared BookStack Documentation Platform - NATIVE INSTALLATION
# Requires PostgreSQL (13_deploy_shared_postgres.sh)
# Usage: bash 30_deploy_shared_bookstack_native.sh [--update]

# Debian 12 compatibility checks
if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Check if running on Debian 12
if ! grep -q "Debian GNU/Linux 12" /etc/os-release 2>/dev/null; then
  echo "⚠️  Warning: This script is optimized for Debian 12"
  echo "Current OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
fi

# Get PostgreSQL password from environment
POSTGRES_HOST="${POSTGRES_HOST:-10.0.5.102}"
POSTGRES_PASS="${POSTGRES_PASS:-ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8=}"

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating BookStack ==="
  cd /var/www/bookstack
  su -s /bin/bash -c "git pull origin release" www-data
  su -s /bin/bash -c "composer install --no-dev" www-data
  su -s /bin/bash -c "php artisan migrate --force" www-data
  su -s /bin/bash -c "php artisan cache:clear" www-data
  su -s /bin/bash -c "php artisan view:clear" www-data
  systemctl restart apache2
  echo "✅ BookStack updated"
  exit 0
fi

echo "=== BookStack Native Deployment ==="

# Install Apache, PHP, and dependencies
echo "Installing Apache, PHP 8.2, and dependencies..."
apt-get update
apt-get install -y apache2 libapache2-mod-php \
  php php-cli php-fpm php-curl php-mbstring php-ldap php-tidy php-xml php-zip \
  php-gd php-mysql php-pgsql \
  git curl wget unzip composer postgresql-client

# Enable Apache modules
a2enmod rewrite
a2enmod php8.2

# Create database
echo "Creating BookStack database..."
BOOKSTACK_DB_PASS=$(openssl rand -base64 32)
PGPASSWORD="$POSTGRES_PASS" psql -h "$POSTGRES_HOST" -U dbadmin -d postgres << EOF
-- Drop existing role/database if they exist from previous runs
DROP DATABASE IF EXISTS bookstack;
DROP ROLE IF EXISTS bookstack;

-- Create role and database
CREATE ROLE bookstack WITH LOGIN PASSWORD '${BOOKSTACK_DB_PASS}';
CREATE DATABASE bookstack OWNER dbadmin;

-- Grant all permissions to bookstack role
GRANT ALL PRIVILEGES ON DATABASE bookstack TO bookstack;

-- Connect to bookstack database and grant schema permissions
\c bookstack
GRANT ALL ON SCHEMA public TO bookstack;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bookstack;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO bookstack;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO bookstack;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO bookstack;
\q
EOF

# Clone BookStack
echo "Cloning BookStack repository..."
cd /var/www
git -c http.version=HTTP/1.1 clone https://github.com/BookStackApp/BookStack.git --branch release --single-branch bookstack
cd bookstack

# Set permissions
chown -R www-data:www-data /var/www/bookstack
chmod -R 755 /var/www/bookstack

# Install Composer dependencies
echo "Installing Composer dependencies..."
su -s /bin/bash -c "composer install --no-dev" www-data

# Create .env file
echo "Creating environment configuration..."
cp .env.example .env

# Generate app key
APP_KEY=$(su -s /bin/bash -c "php artisan key:generate --show" www-data)

# Configure .env
cat > .env << EOF
APP_NAME="BookStack"
APP_ENV=production
APP_KEY=${APP_KEY}
APP_URL=http://$(hostname -I | awk '{print $1}')
APP_DEBUG=false
APP_LANG=en
APP_AUTO_LANG_PUBLIC=true

DB_CONNECTION=pgsql
DB_HOST=${POSTGRES_HOST}
DB_PORT=5432
DB_DATABASE=bookstack
DB_USERNAME=bookstack
DB_PASSWORD=${BOOKSTACK_DB_PASS}

CACHE_DRIVER=file
SESSION_DRIVER=file
SESSION_LIFETIME=120

MAIL_DRIVER=smtp
MAIL_HOST=localhost
MAIL_PORT=1025
MAIL_FROM=bookstack@localhost
MAIL_FROM_NAME="BookStack"

# File uploads
STORAGE_TYPE=local_secure
STORAGE_IMAGE_TYPE=local_secure
EOF

chown www-data:www-data /var/www/bookstack/.env
chmod 600 /var/www/bookstack/.env

# Run migrations
echo "Running database migrations..."
su -s /bin/bash -c "php artisan migrate --force" www-data

# Clear caches
su -s /bin/bash -c "php artisan cache:clear" www-data
su -s /bin/bash -c "php artisan view:clear" www-data

# Create Apache virtual host
echo "Creating Apache virtual host..."
cat > /etc/apache2/sites-available/bookstack.conf << 'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/bookstack/public/

    <Directory /var/www/bookstack/public/>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/bookstack-error.log
    CustomLog ${APACHE_LOG_DIR}/bookstack-access.log combined
</VirtualHost>
EOF

# Disable default site and enable BookStack
a2dissite 000-default
a2ensite bookstack

# Restart Apache
systemctl restart apache2

# Wait for service to start
echo "Waiting for BookStack to start..."
for i in {1..30}; do
  if curl -f http://localhost >/dev/null 2>&1; then
    echo "✅ BookStack is responding"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ BookStack failed to start within timeout"
    systemctl status apache2
    exit 1
  fi
  sleep 2
done

# Check if service is running
if systemctl is-active --quiet apache2; then
  echo "✅ Apache service is running"
else
  echo "❌ Apache service failed to start"
  systemctl status apache2
  exit 1
fi

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/bookstack.txt << EOF
=== BookStack Credentials ===
URL: http://$(hostname -I | awk '{print $1}')

Default Login:
Email: admin@admin.com
Password: password

⚠️  IMPORTANT: Change the default password immediately!

Database: postgresql://bookstack:${BOOKSTACK_DB_PASS}@${POSTGRES_HOST}:5432/bookstack

Service: systemctl status apache2
Logs: tail -f /var/log/apache2/bookstack-error.log
Config: /var/www/bookstack/.env
Path: /var/www/bookstack/
EOF

chmod 600 /root/.credentials/bookstack.txt

echo ""
echo "=========================================="
echo "✅ BookStack deployed successfully!"
echo "=========================================="
echo "URL: http://$(hostname -I | awk '{print $1}')"
echo ""
echo "Default Login:"
echo "  Email: admin@admin.com"
echo "  Password: password"
echo ""
echo "⚠️  IMPORTANT: Change the default password immediately!"
echo ""
echo "Credentials: /root/.credentials/bookstack.txt"
echo "Service: systemctl status apache2"
echo "Logs: tail -f /var/log/apache2/bookstack-error.log"
echo "=========================================="
