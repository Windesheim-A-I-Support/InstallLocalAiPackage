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

# Shared DuckDB HTTP Server
# Fast analytical database with HTTP API
# Usage: bash 40_deploy_shared_duckdb.sh [--update]

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
  echo "=== Updating DuckDB ==="
  echo "✅ DuckDB updated (no update needed for native installation)"
  exit 0
fi

echo "=== DuckDB HTTP Server Deployment ==="

mkdir -p /opt/duckdb/{data,extensions}
cd /opt/duckdb

# Install Python and required packages
apt-get update
apt-get install -y python3 python3-pip python3-venv

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
pip install duckdb flask flask-cors pandas

# Create the DuckDB HTTP server
cat > server.py << 'EOF'
from flask import Flask, request, jsonify
from flask_cors import CORS
import duckdb
import os

app = Flask(__name__)
CORS(app)

DB_PATH = "/opt/duckdb/data/duckdb.db"
con = duckdb.connect(DB_PATH)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "database": DB_PATH})

@app.route('/query', methods=['POST'])
def query():
    try:
        sql = request.json.get('sql', '')
        if not sql:
            return jsonify({"error": "No SQL provided"}), 400

        result = con.execute(sql).fetchall()
        columns = [desc[0] for desc in con.description]

        return jsonify({
            "columns": columns,
            "rows": result,
            "row_count": len(result)
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/execute', methods=['POST'])
def execute():
    try:
        sql = request.json.get('sql', '')
        if not sql:
            return jsonify({"error": "No SQL provided"}), 400

        con.execute(sql)
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8089, debug=False)
EOF

# Create systemd service
cat > /etc/systemd/system/duckdb-server.service << EOF
[Unit]
Description=DuckDB HTTP Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/duckdb
Environment=PATH=/opt/duckdb/venv/bin
ExecStart=/opt/duckdb/venv/bin/python server.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable duckdb-server
systemctl start duckdb-server

# Wait for service to start
sleep 3

# Create a test query script
cat > test_query.sh << 'EOF'
#!/bin/bash
curl -X POST http://localhost:8089/query \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT 42 as answer, '\''DuckDB'\'' as database"}'
EOF
chmod +x test_query.sh

echo "✅ DuckDB HTTP Server deployed"
echo ""
echo "API URL: http://$(hostname -I | awk '{print $1}'):8089"
echo "Database: /opt/duckdb/data/duckdb.db"
echo ""
echo "Service status: $(systemctl is-active duckdb-server)"
echo ""
echo "Test query:"
echo "curl -X POST http://$(hostname -I | awk '{print $1}'):8089/query \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"sql\": \"SELECT 42 as answer\"}'"
echo ""
echo "Or run: ./test_query.sh"
echo ""
echo "Service management:"
echo "  Start: systemctl start duckdb-server"
echo "  Stop: systemctl stop duckdb-server"
echo "  Status: systemctl status duckdb-server"
echo "  Logs: journalctl -u duckdb-server -f"
