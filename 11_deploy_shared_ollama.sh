#!/bin/bash
set -e

# Shared Ollama service (native install)
# Can be used by multiple Open WebUI instances

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== Ollama Shared Service Deployment ==="

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Create systemd override for external access
mkdir -p /etc/systemd/system/ollama.service.d
cat > /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_ORIGINS=*"
EOF

systemctl daemon-reload
systemctl restart ollama
systemctl enable ollama

# Pull essential models
echo "Pulling essential models..."
ollama pull qwen2.5:3b
ollama pull nomic-embed-text

echo "✅ Ollama deployed at port 11434"
echo "Models: qwen2.5:3b, nomic-embed-text"
echo ""
echo "Connect from Open WebUI:"
echo "  OLLAMA_BASE_URL=http://$(hostname -I | awk '{print $1}'):11434"
