#!/bin/bash
set -e

# Shared Playwright browser automation
# Usage: bash 32_deploy_shared_playwright.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Playwright ==="
  cd /opt/playwright
  docker compose pull
  docker compose up -d
  echo "✅ Playwright updated"
  exit 0
fi

echo "=== Playwright Shared Service Deployment ==="

mkdir -p /opt/playwright
cd /opt/playwright

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  playwright:
    image: mcr.microsoft.com/playwright:latest
    container_name: playwright-shared
    restart: unless-stopped
    ports:
      - "3007:3000"
    environment:
      PLAYWRIGHT_BROWSERS_PATH: /ms-playwright
    command: npx playwright run-server --port 3000 --host 0.0.0.0
EOF

docker compose up -d

echo "✅ Playwright deployed"
echo ""
echo "URL: http://$(hostname -I | awk '{print $1}'):3007"
echo ""
echo "Use from pipelines for web automation"
