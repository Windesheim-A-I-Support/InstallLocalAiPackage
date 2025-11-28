#!/bin/bash
set -e

# Shared Neo4j graph database
# Usage: bash 19_deploy_shared_neo4j.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating Neo4j ==="
  cd /opt/neo4j
  docker compose pull
  docker compose up -d
  echo "✅ Neo4j updated"
  exit 0
fi

echo "=== Neo4j Shared Service Deployment ==="

# Create directory
mkdir -p /opt/neo4j/{data,logs}
cd /opt/neo4j

# Generate password
NEO4J_PASS=$(openssl rand -base64 24)

# Create docker-compose
cat > docker-compose.yml << EOF
version: '3.8'

services:
  neo4j:
    image: neo4j:5-community
    container_name: neo4j-shared
    restart: unless-stopped
    ports:
      - "7474:7474"
      - "7687:7687"
    environment:
      NEO4J_AUTH: neo4j/${NEO4J_PASS}
      NEO4J_PLUGINS: '["apoc", "graph-data-science"]'
      NEO4J_dbms_security_procedures_unrestricted: apoc.*,gds.*
      NEO4J_dbms_memory_heap_initial__size: 512m
      NEO4J_dbms_memory_heap_max__size: 2G
    volumes:
      - ./data:/data
      - ./logs:/logs
EOF

# Start service
docker compose up -d

echo "✅ Neo4j deployed"
echo ""
echo "Browser: http://$(hostname -I | awk '{print $1}'):7474"
echo "Bolt: bolt://$(hostname -I | awk '{print $1}'):7687"
echo ""
echo "Username: neo4j"
echo "Password: $NEO4J_PASS"
echo ""
echo "Connect from Open WebUI via pipelines:"
echo "  NEO4J_URI=bolt://neo4j:${NEO4J_PASS}@$(hostname -I | awk '{print $1}'):7687"
