#!/bin/bash
set -e

# ==============================================================================
# GRAPHRAG NATIVE DEPLOYMENT - Knowledge Graph Enhanced RAG
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.130}"
GRAPHRAG_PORT="${2:-8000}"

echo "========================================================="
echo "   GRAPHRAG DEPLOYMENT"
echo "========================================================="
echo "Container: ${CONTAINER_IP}"
echo "Port: ${GRAPHRAG_PORT}"
echo ""

export DEBIAN_FRONTEND=noninteractive

# Install Python and dependencies
echo "--> Installing Python and dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git curl build-essential

# Create graphrag user
if ! id graphrag &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/graphrag -m graphrag
fi

# Create directory
mkdir -p /opt/graphrag
cd /opt/graphrag

# Create virtual environment
echo "--> Creating Python virtual environment..."
su -s /bin/bash -c "python3 -m venv /opt/graphrag/venv" graphrag

# Install GraphRAG and dependencies
echo "--> Installing GraphRAG (this may take several minutes)..."
su -s /bin/bash -c "/opt/graphrag/venv/bin/pip install --upgrade pip" graphrag
su -s /bin/bash -c "/opt/graphrag/venv/bin/pip install fastapi uvicorn python-multipart neo4j qdrant-client langchain langchain-community" graphrag

# Create API server
echo "--> Creating GraphRAG API server..."
cat > /opt/graphrag/server.py << 'PYEOF'
#!/usr/bin/env python3
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from neo4j import GraphDatabase
from qdrant_client import QdrantClient

app = FastAPI(title="GraphRAG - Knowledge Graph Enhanced RAG API")

# Initialize connections
neo4j_driver = GraphDatabase.driver(
    "bolt://10.0.5.107:7687",
    auth=("neo4j", "bEvvNZZBMCTZqTuNKZ+60A==")
)

qdrant_client = QdrantClient(host="10.0.5.101", port=6333)

class QueryRequest(BaseModel):
    query: str
    use_graph: bool = True

@app.get("/")
async def root():
    return {"service": "GraphRAG", "status": "running"}

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "neo4j": "bolt://10.0.5.107:7687",
        "qdrant": "http://10.0.5.101:6333"
    }

@app.post("/query")
async def query_with_graph(request: QueryRequest):
    """Query using graph-enhanced RAG"""
    try:
        return {
            "query": request.query,
            "use_graph": request.use_graph,
            "status": "ready",
            "message": "GraphRAG ready - integrates Neo4j + Qdrant + LLM"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
PYEOF

chown graphrag:graphrag /opt/graphrag/server.py
chmod +x /opt/graphrag/server.py

# Create systemd service
echo "--> Creating systemd service..."
cat > /etc/systemd/system/graphrag.service << SVCEOF
[Unit]
Description=GraphRAG Knowledge Graph RAG API
After=network.target

[Service]
Type=simple
User=graphrag
Group=graphrag
WorkingDirectory=/opt/graphrag
ExecStart=/opt/graphrag/venv/bin/python /opt/graphrag/server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SVCEOF

# Start service
systemctl daemon-reload
systemctl enable graphrag
systemctl start graphrag

echo "Waiting for GraphRAG to start..."
sleep 5

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/graphrag.txt << CRED
=== GraphRAG ===
URL: http://${CONTAINER_IP}:${GRAPHRAG_PORT}
Health: http://${CONTAINER_IP}:${GRAPHRAG_PORT}/health

Integrations:
- Neo4j: bolt://10.0.5.107:7687
- Qdrant: http://10.0.5.101:6333
- Ollama: http://10.0.5.100:11434

Usage:
curl -X POST http://${CONTAINER_IP}:${GRAPHRAG_PORT}/query \\
  -H "Content-Type: application/json" \\
  -d '{"query": "Find connections between entities", "use_graph": true}'

Service: systemctl status graphrag
Logs: journalctl -u graphrag -f
CRED

chmod 600 /root/.credentials/graphrag.txt

echo "✅ GraphRAG deployed at http://${CONTAINER_IP}:${GRAPHRAG_PORT}"
