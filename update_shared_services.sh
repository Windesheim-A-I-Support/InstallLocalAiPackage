#!/bin/bash
set -e

# Update all shared services via apt

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== Updating Shared Services ==="

# Update package lists
apt update

# PostgreSQL
if systemctl is-active --quiet postgresql; then
  echo "Updating PostgreSQL..."
  apt upgrade -y postgresql-15 postgresql-contrib-15
fi

# Redis
if systemctl is-active --quiet redis-server; then
  echo "Updating Redis..."
  apt upgrade -y redis-server
fi

# Nextcloud (manual update required)
if [ -d /var/www/nextcloud ]; then
  echo ""
  echo "⚠️  Nextcloud requires manual update:"
  echo "  sudo -u www-data php /var/www/nextcloud/updater/updater.phar"
fi

# Clean up
apt autoremove -y
apt clean

echo ""
echo "✅ Shared services updated"
echo ""
echo "Restart services:"
echo "  systemctl restart postgresql"
echo "  systemctl restart redis-server"
