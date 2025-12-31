#!/bin/bash
set -e

# ==============================================================================
# ELASTICSEARCH NATIVE DEPLOYMENT - Log Aggregation & Search
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.119}"
ES_HTTP_PORT="${2:-9200}"
ES_TRANSPORT_PORT="${3:-9300}"

echo "========================================================="
echo "   ELASTICSEARCH DEPLOYMENT"
echo "========================================================="
echo "Container: ${CONTAINER_IP}"
echo "HTTP Port: ${ES_HTTP_PORT}"
echo ""

export DEBIAN_FRONTEND=noninteractive

# Install Java 21 (required for Elasticsearch 8.x)
echo "--> Installing Java 21..."
apt-get update
apt-get install -y wget gnupg apt-transport-https ca-certificates

# Add Adoptium repository for Java 21
mkdir -p /etc/apt/keyrings
rm -f /etc/apt/keyrings/adoptium.gpg
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | \
    gpg --batch --dearmor -o /etc/apt/keyrings/adoptium.gpg

echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" | \
    tee /etc/apt/sources.list.d/adoptium.list > /dev/null

apt-get update
apt-get install -y temurin-21-jdk

# Add Elasticsearch repository
echo "--> Adding Elasticsearch repository..."
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --batch --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | \
    tee /etc/apt/sources.list.d/elastic-8.x.list

apt-get update

# Install Elasticsearch
echo "--> Installing Elasticsearch (this may take several minutes)..."
apt-get install -y elasticsearch

# Configure Elasticsearch
echo "--> Configuring Elasticsearch..."
cat > /etc/elasticsearch/elasticsearch.yml << ESCONFIG
cluster.name: forensics-cluster
node.name: node-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
http.port: ${ES_HTTP_PORT}
transport.port: ${ES_TRANSPORT_PORT}
discovery.type: single-node
xpack.security.enabled: false
xpack.security.enrollment.enabled: false
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false
ESCONFIG

# Set system limits
echo "--> Setting system limits..."
echo "elasticsearch - nofile 65535" >> /etc/security/limits.conf
echo "elasticsearch - memlock unlimited" >> /etc/security/limits.conf

# Configure JVM options
echo "--> Configuring JVM heap size..."
cat > /etc/elasticsearch/jvm.options.d/heap.options << JVMOPTS
-Xms2g
-Xmx2g
JVMOPTS

# Start Elasticsearch
echo "--> Starting Elasticsearch..."
systemctl daemon-reload
systemctl enable elasticsearch
systemctl start elasticsearch

echo "Waiting for Elasticsearch to start (this may take 30-60 seconds)..."
sleep 30

# Wait for Elasticsearch to be ready
for i in {1..30}; do
    if curl -s http://localhost:${ES_HTTP_PORT}/_cluster/health &>/dev/null; then
        echo "Elasticsearch is ready!"
        break
    fi
    echo "Waiting for Elasticsearch... (attempt $i/30)"
    sleep 2
done

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/elasticsearch.txt << CRED
=== Elasticsearch ===
URL: http://${CONTAINER_IP}:${ES_HTTP_PORT}
Health: http://${CONTAINER_IP}:${ES_HTTP_PORT}/_cluster/health

Cluster: forensics-cluster
Node: node-1

API Usage:
# Check cluster health
curl http://${CONTAINER_IP}:${ES_HTTP_PORT}/_cluster/health

# List indices
curl http://${CONTAINER_IP}:${ES_HTTP_PORT}/_cat/indices?v

# Create index
curl -X PUT http://${CONTAINER_IP}:${ES_HTTP_PORT}/logs

# Index document
curl -X POST http://${CONTAINER_IP}:${ES_HTTP_PORT}/logs/_doc \\
  -H "Content-Type: application/json" \\
  -d '{"timestamp": "2025-12-29", "message": "Test log"}'

Service: systemctl status elasticsearch
Logs: journalctl -u elasticsearch -f
Config: /etc/elasticsearch/elasticsearch.yml

Security: DISABLED (for internal network use)
CRED

chmod 600 /root/.credentials/elasticsearch.txt

echo "✅ Elasticsearch deployed at http://${CONTAINER_IP}:${ES_HTTP_PORT}"
