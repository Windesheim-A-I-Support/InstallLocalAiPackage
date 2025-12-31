#!/bin/bash
set -e

# ==============================================================================
# NEO4J NATIVE DEPLOYMENT
# ==============================================================================
# Based on official Neo4j Debian installation documentation
# Source: https://neo4j.com/docs/operations-manual/current/installation/linux/debian/
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.107}"
NEO4J_VERSION="${2:-1:2025.11.2}"  # Latest stable
NEO4J_PASSWORD="${3:-$(openssl rand -base64 16)}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   NEO4J GRAPH DATABASE DEPLOYMENT"
echo "========================================================="
echo ""
echo "This deploys:"
echo "  • Neo4j Community Edition v${NEO4J_VERSION}"
echo "  • Graph database service"
echo "  • Neo4j Browser web interface"
echo ""
echo "Container: ${CONTAINER_IP}"
echo "Access at: http://${CONTAINER_IP}:7474"
echo "Bolt protocol: bolt://${CONTAINER_IP}:7687"
echo ""
echo ""

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# STEP 1: INSTALL JAVA 21 FROM ADOPTIUM
# ==============================================================================
echo "--> [1/7] Installing Java 21 from Adoptium..."

# Install prerequisites
apt-get update
apt-get install -y wget gnupg apt-transport-https

# Add Adoptium GPG key and repository
mkdir -p /etc/apt/keyrings
rm -f /etc/apt/keyrings/adoptium.gpg
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | \
    gpg --batch --dearmor -o /etc/apt/keyrings/adoptium.gpg

echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" | \
    tee /etc/apt/sources.list.d/adoptium.list > /dev/null

# Update and install Java 21
apt-get update
apt-get install -y temurin-21-jdk

# Verify Java installation
java -version
echo "✅ Java 21 installed"

# ==============================================================================
# STEP 2: ADD NEO4J REPOSITORY
# ==============================================================================
echo "--> [2/7] Adding Neo4j repository..."

# Install prerequisites
apt-get install -y wget gnupg

# Create keyrings directory
mkdir -p /etc/apt/keyrings

# Download and install GPG key (using IPv4 to avoid network issues)
rm -f /etc/apt/keyrings/neotechnology.gpg
wget -4 -O - https://debian.neo4j.com/neotechnology.gpg.key | \
    gpg --batch --dearmor -o /etc/apt/keyrings/neotechnology.gpg

# Set permissions
chmod a+r /etc/apt/keyrings/neotechnology.gpg

# Add Neo4j repository
echo 'deb [signed-by=/etc/apt/keyrings/neotechnology.gpg] https://debian.neo4j.com stable latest' | \
    tee /etc/apt/sources.list.d/neo4j.list > /dev/null

# Update package list
apt-get update

echo "✅ Neo4j repository added"

# ==============================================================================
# STEP 3: INSTALL NEO4J
# ==============================================================================
echo "--> [3/7] Installing Neo4j..."

apt-get install -y neo4j="$NEO4J_VERSION"

# Verify installation
NEO4J_INSTALLED_VERSION=$(dpkg -l | grep neo4j | awk '{print $3}')
echo "✅ Neo4j installed: $NEO4J_INSTALLED_VERSION"

# ==============================================================================
# STEP 4: CONFIGURE NEO4J
# ==============================================================================
echo "--> [4/7] Configuring Neo4j..."

# Set initial password
neo4j-admin dbms set-initial-password "$NEO4J_PASSWORD"
echo "✅ Initial password set"

# Configure Neo4j to listen on all interfaces
NEO4J_CONF="/etc/neo4j/neo4j.conf"

# Backup original config
cp "$NEO4J_CONF" "$NEO4J_CONF.bak"

# Update configuration
cat >> "$NEO4J_CONF" <<EOF

# ==============================================================================
# Custom Configuration Added by Deployment Script
# ==============================================================================

# Listen on all interfaces
server.default_listen_address=0.0.0.0

# HTTP Connector (Neo4j Browser)
server.http.enabled=true
server.http.listen_address=:7474

# HTTPS Connector (disabled for internal network)
server.https.enabled=false

# Bolt Connector (recommended for applications)
server.bolt.enabled=true
server.bolt.listen_address=:7687

# Database location
server.directories.data=/var/lib/neo4j/data
server.directories.logs=/var/log/neo4j

# Memory settings
server.memory.heap.initial_size=512m
server.memory.heap.max_size=1g
server.memory.pagecache.size=512m

# Allow upgrade from older versions
server.allow_upgrade=true

# Transaction settings
db.tx_log.rotation.retention_policy=2 days
EOF

echo "✅ Configuration updated"

# ==============================================================================
# STEP 5: START NEO4J SERVICE
# ==============================================================================
echo "--> [5/7] Starting Neo4j service..."

# Enable and start Neo4j
systemctl enable neo4j
systemctl start neo4j

# Wait for service to start
echo "Waiting for Neo4j to start (this may take 30-60 seconds)..."
sleep 10

# Check service status
if systemctl is-active --quiet neo4j; then
    echo "✅ Neo4j service is running"
else
    echo "⚠️  Neo4j service may still be starting"
    echo "Check status with: systemctl status neo4j"
fi

# Wait for Neo4j to be ready (check HTTP endpoint)
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:7474 > /dev/null 2>&1; then
        echo "✅ Neo4j HTTP endpoint is responding"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo "⚠️  Neo4j may still be initializing"
        echo "Check logs with: journalctl -u neo4j -f"
    else
        sleep 2
    fi
done

# ==============================================================================
# STEP 6: SAVE CREDENTIALS
# ==============================================================================
echo "--> [6/7] Saving credentials..."

mkdir -p /root/.credentials
cat > /root/.credentials/neo4j.txt <<CRED
=== Neo4j Graph Database Credentials ===

Web Interface (Neo4j Browser):
  URL: http://${CONTAINER_IP}:7474
  Username: neo4j
  Password: ${NEO4J_PASSWORD}

Bolt Protocol (for applications):
  URL: bolt://${CONTAINER_IP}:7687
  Username: neo4j
  Password: ${NEO4J_PASSWORD}

Connection String Examples:
  Python (neo4j driver):
    from neo4j import GraphDatabase
    driver = GraphDatabase.driver("bolt://${CONTAINER_IP}:7687", auth=("neo4j", "${NEO4J_PASSWORD}"))

  Cypher Shell:
    cypher-shell -a bolt://${CONTAINER_IP}:7687 -u neo4j -p '${NEO4J_PASSWORD}'

Service Management:
  systemctl status neo4j
  systemctl restart neo4j
  systemctl stop neo4j
  journalctl -u neo4j -f

Configuration:
  Config: /etc/neo4j/neo4j.conf
  Data: /var/lib/neo4j/data
  Logs: /var/log/neo4j

Neo4j Admin Commands:
  # Change password
  neo4j-admin dbms set-initial-password <new-password>

  # Backup database
  neo4j-admin database dump neo4j --to-path=/backup

  # Restore database
  neo4j-admin database load neo4j --from-path=/backup

  # Check status
  neo4j status

Cypher Query Examples:
  # Create node
  CREATE (n:Person {name: 'Alice', age: 30}) RETURN n

  # Find nodes
  MATCH (n:Person) RETURN n

  # Create relationship
  MATCH (a:Person {name: 'Alice'}), (b:Person {name: 'Bob'})
  CREATE (a)-[:KNOWS]->(b)

Version: ${NEO4J_INSTALLED_VERSION}
CRED

chmod 600 /root/.credentials/neo4j.txt

echo ""
echo "========================================================="
echo "✅ NEO4J DEPLOYED SUCCESSFULLY"
echo "========================================================="
echo ""
echo "Access Neo4j Browser at: http://${CONTAINER_IP}:7474"
echo ""
echo "Login Credentials:"
echo "  Username: neo4j"
echo "  Password: ${NEO4J_PASSWORD}"
echo ""
echo "Bolt Protocol (for apps): bolt://${CONTAINER_IP}:7687"
echo ""
echo "Next Steps:"
echo "  1. Open http://${CONTAINER_IP}:7474 in your browser"
echo "  2. Login with credentials above"
echo "  3. Try some Cypher queries!"
echo ""
echo "Service Management:"
echo "  systemctl status neo4j"
echo "  systemctl restart neo4j"
echo "  journalctl -u neo4j -f"
echo ""
echo "Credentials saved to: /root/.credentials/neo4j.txt"
echo "========================================================="
