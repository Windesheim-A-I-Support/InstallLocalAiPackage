#!/bin/bash
set -e

# ==============================================================================
# LITELLM PROXY NATIVE DEPLOYMENT - Unified LLM API Gateway
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.108}"
LITELLM_PORT="${2:-4000}"

echo "========================================================="
echo "   LITELLM PROXY DEPLOYMENT"
echo "========================================================="
echo "Container: ${CONTAINER_IP}"
echo "Port: ${LITELLM_PORT}"
echo ""

export DEBIAN_FRONTEND=noninteractive

# Install Python and dependencies
echo "--> Installing Python and dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git curl build-essential

# Create litellm user
if ! id litellm &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/litellm -m litellm
fi

# Create directory
mkdir -p /opt/litellm
cd /opt/litellm

# Create virtual environment
echo "--> Creating Python virtual environment..."
su -s /bin/bash -c "python3 -m venv /opt/litellm/venv" litellm

# Install LiteLLM
echo "--> Installing LiteLLM (this may take several minutes)..."
su -s /bin/bash -c "/opt/litellm/venv/bin/pip install --upgrade pip" litellm
su -s /bin/bash -c "/opt/litellm/venv/bin/pip install 'litellm[proxy]'" litellm

# Create config file
echo "--> Creating LiteLLM config..."
cat > /opt/litellm/config.yaml << 'LITCONFIG'
model_list:
  - model_name: ollama/llama3.2
    litellm_params:
      model: ollama/llama3.2
      api_base: http://10.0.5.100:11434

  - model_name: ollama/nomic-embed-text
    litellm_params:
      model: ollama/nomic-embed-text
      api_base: http://10.0.5.100:11434

litellm_settings:
  drop_params: True
  set_verbose: False

general_settings:
  master_key: sk-litellm-master-key-change-this
  database_url: redis://10.0.5.103:6379
LITCONFIG

chown litellm:litellm /opt/litellm/config.yaml

# Create systemd service
echo "--> Creating systemd service..."
cat > /etc/systemd/system/litellm.service << LITSERVICE
[Unit]
Description=LiteLLM Proxy Server
After=network.target

[Service]
Type=simple
User=litellm
Group=litellm
WorkingDirectory=/opt/litellm
Environment="REDIS_PASSWORD=hzR7TTDZ7zQuZLo0X8pGkdSIKrjpl9Eb"
ExecStart=/opt/litellm/venv/bin/litellm --config /opt/litellm/config.yaml --port 4000 --host 0.0.0.0
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
LITSERVICE

# Start service
systemctl daemon-reload
systemctl enable litellm
systemctl start litellm

echo "Waiting for LiteLLM to start..."
sleep 5

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/litellm.txt << CRED
=== LiteLLM Proxy ===
URL: http://${CONTAINER_IP}:${LITELLM_PORT}
Health: http://${CONTAINER_IP}:${LITELLM_PORT}/health

Master Key: sk-litellm-master-key-change-this

OpenAI-Compatible Endpoint:
Base URL: http://${CONTAINER_IP}:${LITELLM_PORT}
API Key: sk-litellm-master-key-change-this

Example:
curl http://${CONTAINER_IP}:${LITELLM_PORT}/v1/chat/completions \\
  -H "Authorization: Bearer sk-litellm-master-key-change-this" \\
  -H "Content-Type: application/json" \\
  -d '{"model": "ollama/llama3.2", "messages": [{"role": "user", "content": "Hello"}]}'

Service: systemctl status litellm
Logs: journalctl -u litellm -f
Config: /opt/litellm/config.yaml
CRED

chmod 600 /root/.credentials/litellm.txt

echo "✅ LiteLLM Proxy deployed at http://${CONTAINER_IP}:${LITELLM_PORT}"
