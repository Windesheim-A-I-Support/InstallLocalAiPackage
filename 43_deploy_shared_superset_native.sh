#!/bin/bash
set -e

# ==============================================================================
# APACHE SUPERSET NATIVE DEPLOYMENT - Data Visualization & BI
# ==============================================================================

CONTAINER_IP="${1:-10.0.5.132}"
SUPERSET_PORT="${2:-8088}"

echo "========================================================="
echo "   APACHE SUPERSET DEPLOYMENT"
echo "========================================================="
echo "Container: ${CONTAINER_IP}"
echo "Port: ${SUPERSET_PORT}"
echo ""

export DEBIAN_FRONTEND=noninteractive

# Install Python and dependencies
echo "--> Installing Python and dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv git curl build-essential \
    libpq-dev python3-dev libsasl2-dev libldap2-dev libssl-dev postgresql-client

# Create superset user
if ! id superset &>/dev/null; then
  useradd -r -s /bin/bash -d /opt/superset -m superset
fi

# Create directory
mkdir -p /opt/superset
cd /opt/superset

# Create virtual environment
echo "--> Creating Python virtual environment..."
su -s /bin/bash -c "python3 -m venv /opt/superset/venv" superset

# Install Superset
echo "--> Installing Apache Superset (this may take 10-15 minutes)..."
su -s /bin/bash -c "/opt/superset/venv/bin/pip install --upgrade pip setuptools" superset
su -s /bin/bash -c "/opt/superset/venv/bin/pip install apache-superset psycopg2-binary redis" superset

# Initialize Superset config
echo "--> Configuring Superset..."
mkdir -p /opt/superset/.superset

cat > /opt/superset/.superset/superset_config.py << 'PYEOF'
import os

SUPERSET_WEBSERVER_PORT = 8088
ROW_LIMIT = 5000
SECRET_KEY = 'thisISaSECRET_1234changeTHIS'

# PostgreSQL for metadata
SQLALCHEMY_DATABASE_URI = 'postgresql://dbadmin:ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8=@10.0.5.102:5432/superset'

# Redis for cache
CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 300,
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_REDIS_HOST': '10.0.5.103',
    'CACHE_REDIS_PORT': 6379,
    'CACHE_REDIS_PASSWORD': 'hzR7TTDZ7zQuZLo0X8pGkdSIKrjpl9Eb',
    'CACHE_REDIS_DB': 1,
}

WTF_CSRF_ENABLED = True
PYEOF

chown -R superset:superset /opt/superset

# Create superset database in PostgreSQL
echo "--> Creating Superset database..."
PGPASSWORD='ulsZ5bM0p/d512Dzl+rgFg4diPo3yGgh1UVZp7r4+E8=' psql -h 10.0.5.102 -U dbadmin -d postgres -c "CREATE DATABASE superset;" 2>/dev/null || echo "Database may already exist"

# Initialize Superset database
echo "--> Initializing Superset database..."
su -s /bin/bash -c "cd /opt/superset && SUPERSET_CONFIG_PATH=/opt/superset/.superset/superset_config.py /opt/superset/venv/bin/superset db upgrade" superset

# Create admin user
echo "--> Creating admin user..."
su -s /bin/bash -c "cd /opt/superset && SUPERSET_CONFIG_PATH=/opt/superset/.superset/superset_config.py /opt/superset/venv/bin/superset fab create-admin --username admin --firstname Admin --lastname User --email admin@forensics.local --password admin" superset || echo "Admin user may already exist"

# Initialize Superset
su -s /bin/bash -c "cd /opt/superset && SUPERSET_CONFIG_PATH=/opt/superset/.superset/superset_config.py /opt/superset/venv/bin/superset init" superset

# Create systemd service
echo "--> Creating systemd service..."
cat > /etc/systemd/system/superset.service << SVCEOF
[Unit]
Description=Apache Superset
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=superset
Group=superset
WorkingDirectory=/opt/superset
Environment="SUPERSET_CONFIG_PATH=/opt/superset/.superset/superset_config.py"
ExecStart=/opt/superset/venv/bin/superset run -h 0.0.0.0 -p 8088
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SVCEOF

# Start service
systemctl daemon-reload
systemctl enable superset
systemctl start superset

echo "Waiting for Superset to start..."
sleep 10

# Save credentials
mkdir -p /root/.credentials
cat > /root/.credentials/superset.txt << CRED
=== Apache Superset ===
URL: http://${CONTAINER_IP}:${SUPERSET_PORT}

Admin Credentials:
Username: admin
Password: admin
⚠️ CHANGE PASSWORD ON FIRST LOGIN!

Database Connections Available:
- PostgreSQL (10.0.5.102:5432)
- Neo4j (10.0.5.107:7687)
- Redis (10.0.5.103:6379)

Service: systemctl status superset
Logs: journalctl -u superset -f
Config: /opt/superset/.superset/superset_config.py
CRED

chmod 600 /root/.credentials/superset.txt

echo "✅ Apache Superset deployed at http://${CONTAINER_IP}:${SUPERSET_PORT}"
echo "   Login: admin / admin (CHANGE THIS!)"
