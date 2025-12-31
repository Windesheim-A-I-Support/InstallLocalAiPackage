#!/bin/bash
set -e

# Nextcloud deployment script (native install - no Docker)
# Deploys Apache + MariaDB + Redis + Nextcloud

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== Nextcloud Deployment ==="

# Install packages
apt update
apt install -y apache2 mariadb-server php php-{apcu,bcmath,bz2,ctype,curl,dom,fileinfo,gd,gmp,iconv,imagick,intl,json,mbstring,mysql,posix,redis,session,simplexml,xml,xmlreader,xmlwriter,zip,zlib} redis-server wget

# Generate passwords
DB_PASS=$(openssl rand -base64 24)
REDIS_PASS=$(openssl rand -base64 24)
ADMIN_PASS="${1:-Nextcloudbaby100!}"

# Configure MariaDB
mysql -e "CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'nextcloud'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Configure Redis
sed -i "s/^# requirepass.*/requirepass $REDIS_PASS/" /etc/redis/redis.conf
systemctl restart redis-server

# Download Nextcloud
cd /tmp
wget -q https://download.nextcloud.com/server/releases/latest.tar.bz2
tar xjf latest.tar.bz2
mv nextcloud /var/www/
chown -R www-data:www-data /var/www/nextcloud
mkdir -p /opt/nextcloud-data
chown www-data:www-data /opt/nextcloud-data

# Configure Apache
cat > /etc/apache2/sites-available/nextcloud.conf << 'EOF'
<VirtualHost *:80>
  DocumentRoot /var/www/nextcloud
  <Directory /var/www/nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews
  </Directory>
</VirtualHost>
EOF

a2ensite nextcloud
a2enmod rewrite headers env dir mime
systemctl restart apache2

# Install Nextcloud
sudo -u www-data php /var/www/nextcloud/occ maintenance:install \
  --database "mysql" \
  --database-name "nextcloud" \
  --database-user "nextcloud" \
  --database-pass "$DB_PASS" \
  --admin-user "admin" \
  --admin-pass "$ADMIN_PASS" \
  --data-dir "/opt/nextcloud-data"

# Configure trusted domains
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 0 --value=$(hostname -I | awk '{print $1}')
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 1 --value='nextcloud-26.valuechainhackers.xyz'

# Configure Redis
sudo -u www-data php /var/www/nextcloud/occ config:system:set redis host --value='localhost'
sudo -u www-data php /var/www/nextcloud/occ config:system:set redis port --value=6379
sudo -u www-data php /var/www/nextcloud/occ config:system:set redis password --value="$REDIS_PASS"
sudo -u www-data php /var/www/nextcloud/occ config:system:set memcache.local --value='\OC\Memcache\APCu'
sudo -u www-data php /var/www/nextcloud/occ config:system:set memcache.locking --value='\OC\Memcache\Redis'

# Setup cron
crontab -u www-data -l 2>/dev/null | { cat; echo "*/5 * * * * php /var/www/nextcloud/cron.php"; } | crontab -u www-data -

echo "✅ Nextcloud deployed"
echo "Admin: admin / $ADMIN_PASS"
echo "DB Password: $DB_PASS"
echo "Redis Password: $REDIS_PASS"
