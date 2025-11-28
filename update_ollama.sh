#!/bin/bash
set -e

# Update Ollama to latest version

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== Updating Ollama ==="

# Backup current version info
ollama --version > /tmp/ollama_version_before.txt 2>&1 || true

# Update
curl -fsSL https://ollama.com/install.sh | sh

# Restart service
systemctl restart ollama

# Show new version
echo ""
echo "✅ Ollama updated"
echo "New version: $(ollama --version)"
