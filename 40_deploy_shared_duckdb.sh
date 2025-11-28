#!/bin/bash
set -e

# Shared DuckDB HTTP Server
# Fast analytical database with HTTP API
# Usage: bash 40_deploy_shared_duckdb.sh [--update]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Update mode
if [ "$1" = "--update" ]; then
  echo "=== Updating DuckDB ===\"
  cd /opt/duckdb
  docker compose pull
  docker compose up -d
  echo "✅ DuckDB updated"
  exit 0
fi

echo "=== DuckDB HTTP Server Deployment ==="

mkdir -p /opt/duckdb/{data,extensions}
cd /opt/duckdb

# Create a simple DuckDB HTTP server using Python
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

RUN pip install --no-cache-dir duckdb flask flask-cors pandas

WORKDIR /app

COPY server.py .

EXPOSE 8089

CMD ["python", "server.py"]
EOF

cat > server.py << 'EOF'
from flask import Flask, request, jsonify
from flask_cors import CORS
import duckdb
import os

app = Flask(__name__)
CORS(app)

DB_PATH = "/data/duckdb.db"
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

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  duckdb:
    build: .
    container_name: duckdb-shared
    restart: unless-stopped
    ports:
      - "8089:8089"
    volumes:
      - ./data:/data
      - ./extensions:/extensions
    environment:
      DUCKDB_EXTENSIONS_PATH: /extensions
EOF

docker compose build
docker compose up -d

# Create a test query
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
echo "Test query:"
echo "curl -X POST http://$(hostname -I | awk '{print $1}'):8089/query \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"sql\": \"SELECT 42 as answer\"}'"
echo ""
echo "Or run: ./test_query.sh"
