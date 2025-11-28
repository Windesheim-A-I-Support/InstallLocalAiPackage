#!/bin/bash
set -e

# Shared Mail Server (Mailcow)
# Full-featured mail server with webmail, IMAP, SMTP
# Requires: Domain name, DNS configured
# Usage: bash 36_deploy_shared_mailserver.sh [--update] <domain>

DOMAIN="${2:-mail.valuechainhackers.xyz}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

if [ -z "$DOMAIN" ] && [ "$1" != "--update" ]; then
  echo "❌ Usage: bash 36_deploy_shared_mailserver.sh <domain>"
  echo "Example: bash 36_deploy_shared_mailserver.sh mail.example.com"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Mailcow ===\"
  cd /opt/mailcow-dockerized
  ./update.sh
  echo "✅ Mailcow updated"
  exit 0
fi

echo "=== Mailcow Mail Server Deployment ==="

# Install git if needed
command -v git >/dev/null 2>&1 || apt-get install -y git

cd /opt
if [ ! -d "mailcow-dockerized" ]; then
  git clone https://github.com/mailcow/mailcow-dockerized
fi

cd mailcow-dockerized

# Generate configuration
./generate_config.sh

# Update domain in config
sed -i "s/^MAILCOW_HOSTNAME=.*/MAILCOW_HOSTNAME=$DOMAIN/" mailcow.conf

# Set timezone
sed -i "s/^TZ=.*/TZ=UTC/" mailcow.conf

docker compose pull
docker compose up -d

echo "✅ Mailcow deployed"
echo ""
echo "Admin UI: https://$DOMAIN"
echo "Webmail: https://$DOMAIN/SOGo"
echo ""
echo "Default admin: admin"
echo "Default password: moohoo"
echo ""
echo "⚠️  IMPORTANT:"
echo "1. Change admin password immediately"
echo "2. Configure DNS records (MX, SPF, DKIM, DMARC)"
echo "3. Configure reverse DNS (PTR record)"
echo "4. Update Traefik routing if needed"
echo ""
echo "SMTP: $DOMAIN:587 (STARTTLS)"
echo "IMAP: $DOMAIN:993 (SSL/TLS)"
