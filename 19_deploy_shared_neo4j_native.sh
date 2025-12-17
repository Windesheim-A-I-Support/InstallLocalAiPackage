#!/bin/bash
# ==============================================================================
# ⚠️  CRITICAL: NO DOCKER FOR SHARED SERVICES! ⚠️
# ==============================================================================
# SHARED SERVICES (containers 100-199) MUST BE DEPLOYED NATIVELY!
#
# ❌ DO NOT USE DOCKER for shared services
# ✅ ONLY USER CONTAINERS (200-249) can use Docker
#
# This service deploys NATIVELY using system packages and systemd.
# Docker is ONLY allowed for individual user containers!
# ==============================================================================

set -e

# Shared Neo4j Graph Database - NATIVE INSTALLATION
# Usage: bash 19_deploy_shared_neo4j_native.sh [--update]

# Debian 12 compatibility checks
if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Check if running on Debian 12
if ! grep -q "Debian GNU/Linux 12" /etc/os-release 2>/dev/null; then
  echo "⚠️  Warning: This script is optimized for Debian 12"
  echo "Current OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Neo4j ==="
  apt-get update
  apt-get upgrade -y neo4j
  systemctl restart neo4j
  echo "✅ Neo4j updated"
  exit 0
fi

echo "=== Neo4j Native Deployment ==="

# Install Java 17 (required for Neo4j 5.x)
echo "Installing Java 17..."
apt-get update
apt-get install -y openjdk-17-jre-headless wget gnupg curl

# Add Neo4j repository
echo "Adding Neo4j repository..."
wget -O - https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor -o /usr/share/keyrings/neo4j-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/neo4j-archive-keyring.gpg] https://debian.neo4j.com stable latest' | tee /etc/apt/sources.list.d/neo4j.list

# Install Neo4j
echo "Installing Neo4j..."
apt-get update
apt-get install -y neo4j

# Generate password
NEO4J_PASSWORD=$(openssl rand -base64 32)

# Configure Neo4j
echo "Configuring Neo4j..."
# Set initial password
neo4j-admin dbms set-initial-password "$NEO4J_PASSWORD"

# Configure server settings
cat >> /etc/neo4j/neo4j.conf << EOF

# Network settings
server.default_listen_address=0.0.0.0
server.bolt.listen_address=:7687
server.http.listen_address=:7474

# Memory settings
server.memory.heap.initial_size=1g
server.memory.heap.max_size=2g
server.memory.pagecache.size=1g

# Security
dbms.security.auth_enabled=true

# Logging
server.logs.debug.level=INFO
EOF

# Enable and start Neo4j
echo "Starting Neo4j service..."
systemctl daemon-reload
systemctl enable neo4j
systemctl start neo4j

# Wait for Neo4j to start
echo "Waiting for Neo4j to start..."
for i in {1..30}; do
  if curl -f http://localhost:7474 >/dev/null 2>&1; then
    echo "✅ Neo4j is responding"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Neo4j failed to start within timeout"
    systemctl status neo4j
    exit 1
  fi
  sleep 2
done

# Test connection
if systemctl is-active --quiet neo4j; then
  echo "✅ Neo4j service is running"
else
  echo "❌ Neo4j service failed to start"
  systemctl status neo4j
  exit 1
fi

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/neo4j.txt << EOF
=== Neo4j Credentials ===
HTTP URL: http://$(hostname -I | awk '{print $1}'):7474
Bolt URL: bolt://$(hostname -I | awk '{print $1}'):7687

Username: neo4j
Password: $NEO4J_PASSWORD

Connection String (Bolt): bolt://neo4j:${NEO4J_PASSWORD}@$(hostname -I | awk '{print $1}'):7687

Service: systemctl status neo4j
Logs: journalctl -u neo4j -f
Config: /etc/neo4j/neo4j.conf
Data: /var/lib/neo4j/
EOF

chmod 600 /root/.credentials/neo4j.txt

echo ""
echo "=========================================="
echo "✅ Neo4j deployed successfully!"
echo "=========================================="
echo "Browser: http://$(hostname -I | awk '{print $1}'):7474"
echo "Bolt: bolt://$(hostname -I | awk '{print $1}'):7687"
echo "Username: neo4j"
echo "Password: (saved in /root/.credentials/neo4j.txt)"
echo ""
echo "Credentials: /root/.credentials/neo4j.txt"
echo "Service: systemctl status neo4j"
echo "Logs: journalctl -u neo4j -f"
echo "=========================================="
