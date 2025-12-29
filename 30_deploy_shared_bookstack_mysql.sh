#!/bin/bash
set -e

# ==============================================================================
# BookStack Native Deployment with MySQL
# ==============================================================================
# Based on official BookStack installation script for Ubuntu 22.04
# Adapted for Debian 12 LXC containers with shared MySQL
# Source: https://github.com/BookStackApp/devops/blob/main/scripts/installation-ubuntu-22.04.sh
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.116}"
MYSQL_HOST="${2:-10.0.5.103}"  # Shared MySQL container
MYSQL_ROOT_PASS="${3:-}"       # MySQL root password (will prompt if not provided)
BOOKSTACK_DIR="/var/www/bookstack"

# Generate a password for the database
DB_PASS="$(openssl rand -base64 32)"

# Log file for debugging
LOGPATH="/var/log/bookstack_install_$(date +%s).log"

echo "========================================================="
echo "   BOOKSTACK DEPLOYMENT WITH MYSQL"
echo "========================================================="
echo ""
echo "This deploys BookStack with:"
echo "  • Apache 2.4 web server"
echo "  • PHP 8.2"
echo "  • MySQL database (shared at $MYSQL_HOST)"
echo ""
echo "Installation directory: $BOOKSTACK_DIR"
echo "Access at: http://${CONTAINER_IP}"
echo ""

# ==============================================================================
# STEP 1: PRE-INSTALL CHECKS
# ==============================================================================
echo "--> [1/10] Running pre-install checks..."

if [[ $EUID -ne 0 ]]; then
   echo "❌ Error: This script must be run with root/sudo privileges"
   exit 1
fi

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

echo "✅ Pre-install checks passed"

# ==============================================================================
# STEP 2: INSTALL REQUIRED PACKAGES
# ==============================================================================
echo "--> [2/10] Installing required packages..."

apt-get update
apt-get install -y git unzip apache2 php8.2 curl \
    php8.2-curl php8.2-mbstring php8.2-ldap \
    php8.2-xml php8.2-zip php8.2-gd php8.2-mysql \
    libapache2-mod-php8.2 mysql-client composer

echo "✅ Packages installed"

# ==============================================================================
# STEP 3: MYSQL DATABASE SETUP
# ==============================================================================
echo "--> [3/10] Setting up MySQL database..."

# Prompt for MySQL root password if not provided
if [ -z "$MYSQL_ROOT_PASS" ]; then
    echo "Enter MySQL root password for $MYSQL_HOST:"
    read -s MYSQL_ROOT_PASS
fi

# Create database and user
mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS bookstack CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'bookstack'@'%' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON bookstack.* TO 'bookstack'@'%';
FLUSH PRIVILEGES;
EOF

echo "✅ Database created: bookstack"
echo "✅ User created: bookstack@%"

# ==============================================================================
# STEP 4: DOWNLOAD BOOKSTACK
# ==============================================================================
echo "--> [4/10] Downloading BookStack..."

cd /var/www || exit 1
rm -rf bookstack  # Remove if exists from previous failed install
git -c http.version=HTTP/1.1 clone https://github.com/BookStackApp/BookStack.git --branch release --single-branch bookstack

echo "✅ BookStack downloaded"

# ==============================================================================
# STEP 5: INSTALL COMPOSER DEPENDENCIES
# ==============================================================================
echo "--> [5/10] Installing PHP dependencies..."

cd "$BOOKSTACK_DIR" || exit 1
export COMPOSER_ALLOW_SUPERUSER=1
composer install --no-dev --no-plugins

echo "✅ Dependencies installed"

# ==============================================================================
# STEP 6: CONFIGURE ENVIRONMENT
# ==============================================================================
echo "--> [6/10] Creating environment configuration..."

cd "$BOOKSTACK_DIR" || exit 1
cp .env.example .env

# Update .env file
sed -i "s@APP_URL=.*\$@APP_URL=http://$CONTAINER_IP@" .env
sed -i 's/DB_HOST=.*$/DB_HOST='"$MYSQL_HOST"'/' .env
sed -i 's/DB_DATABASE=.*$/DB_DATABASE=bookstack/' .env
sed -i 's/DB_USERNAME=.*$/DB_USERNAME=bookstack/' .env
sed -i "s/DB_PASSWORD=.*\$/DB_PASSWORD=$DB_PASS/" .env

# Generate application key
php artisan key:generate --no-interaction --force

echo "✅ Environment configured"

# ==============================================================================
# STEP 7: RUN DATABASE MIGRATIONS
# ==============================================================================
echo "--> [7/10] Running database migrations..."

php artisan migrate --no-interaction --force

echo "✅ Migrations completed"

# ==============================================================================
# STEP 8: SET FILE PERMISSIONS
# ==============================================================================
echo "--> [8/10] Setting file permissions..."

chown -R www-data:www-data ./
chmod -R 755 ./
chmod -R 775 bootstrap/cache public/uploads storage
chmod 740 .env

echo "✅ Permissions set"

# ==============================================================================
# STEP 9: CONFIGURE APACHE
# ==============================================================================
echo "--> [9/10] Configuring Apache..."

# Enable required modules
a2enmod rewrite
a2enmod php8.2

# Create virtual host
cat > /etc/apache2/sites-available/bookstack.conf <<'EOL'
<VirtualHost *:80>
    ServerName localhost

    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/bookstack/public/

    <Directory /var/www/bookstack/public/>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
        <IfModule mod_rewrite.c>
            <IfModule mod_negotiation.c>
                Options -MultiViews -Indexes
            </IfModule>

            RewriteEngine On

            RewriteCond %{HTTP:Authorization} .
            RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteCond %{REQUEST_URI} (.+)/$
            RewriteRule ^ %1 [L,R=301]

            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule ^ index.php [L]
        </IfModule>
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/bookstack-error.log
    CustomLog ${APACHE_LOG_DIR}/bookstack-access.log combined
</VirtualHost>
EOL

# Enable site and disable default
a2dissite 000-default.conf
a2ensite bookstack.conf

# Restart Apache
systemctl restart apache2

echo "✅ Apache configured"

# ==============================================================================
# STEP 10: SAVE CREDENTIALS
# ==============================================================================
echo "--> [10/10] Saving credentials..."

mkdir -p /root/.credentials
cat > /root/.credentials/bookstack.txt <<EOF
=== BookStack Credentials ===
URL: http://${CONTAINER_IP}

Database:
  Host: ${MYSQL_HOST}
  Database: bookstack
  Username: bookstack
  Password: ${DB_PASS}

Default Login:
  Email: admin@admin.com
  Password: password
  (CHANGE THIS ON FIRST LOGIN!)

Installation:
  Directory: ${BOOKSTACK_DIR}
  Log: ${LOGPATH}

Apache:
  Config: /etc/apache2/sites-available/bookstack.conf
  Logs: /var/log/apache2/bookstack-*.log

Commands:
  systemctl restart apache2
  cd /var/www/bookstack && php artisan cache:clear
EOF

chmod 600 /root/.credentials/bookstack.txt

echo ""
echo "========================================================="
echo "✅ BOOKSTACK DEPLOYED SUCCESSFULLY"
echo "========================================================="
echo ""
echo "Access your BookStack at: http://${CONTAINER_IP}"
echo ""
echo "Default Login:"
echo "  Email: admin@admin.com"
echo "  Password: password"
echo "  ⚠️  CHANGE PASSWORD ON FIRST LOGIN!"
echo ""
echo "Database:"
echo "  Host: ${MYSQL_HOST}"
echo "  Database: bookstack"
echo "  Username: bookstack"
echo ""
echo "Credentials saved to: /root/.credentials/bookstack.txt"
echo "Installation log: ${LOGPATH}"
echo ""
echo "========================================================="
