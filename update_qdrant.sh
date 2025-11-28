#!/bin/bash
set -e

# Update Qdrant to latest version

VERSION="${1:-latest}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== Updating Qdrant ==="

# Stop service
systemctl stop qdrant

# Backup
cp /usr/local/bin/qdrant /usr/local/bin/qdrant.backup

# Get latest version if not specified
if [ "$VERSION" = "latest" ]; then
  VERSION=$(curl -s https://api.github.com/repos/qdrant/qdrant/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
fi

echo "Installing version: $VERSION"

# Download and install
wget -q https://github.com/qdrant/qdrant/releases/download/v${VERSION}/qdrant-x86_64-unknown-linux-musl.tar.gz
tar xzf qdrant-x86_64-unknown-linux-musl.tar.gz
mv qdrant /usr/local/bin/
chmod +x /usr/local/bin/qdrant
rm qdrant-x86_64-unknown-linux-musl.tar.gz

# Start service
systemctl start qdrant

echo ""
echo "✅ Qdrant updated to v$VERSION"
echo "Backup: /usr/local/bin/qdrant.backup"
