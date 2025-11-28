#!/bin/bash
set -e

# Shared PostgreSQL database
# For Langfuse, N8N, and other services

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== PostgreSQL Shared Service Deployment ==="

# Install PostgreSQL 15
apt update
apt install -y postgresql-15 postgresql-contrib-15

# Configure for external access
cat >> /etc/postgresql/15/main/postgresql.conf << 'EOF'

# External access
listen_addresses = '*'
max_connections = 200
shared_buffers = 256MB
EOF

cat >> /etc/postgresql/15/main/pg_hba.conf << 'EOF'

# Allow external connections
host    all             all             10.0.0.0/8              md5
host    all             all             172.16.0.0/12           md5
EOF

systemctl restart postgresql

# Create databases and users
ADMIN_PASS=$(openssl rand -base64 32)

sudo -u postgres psql << EOF
-- Create admin user
CREATE USER dbadmin WITH ENCRYPTED PASSWORD '$ADMIN_PASS' CREATEDB CREATEROLE;

-- Create databases
CREATE DATABASE langfuse OWNER dbadmin;
CREATE DATABASE n8n OWNER dbadmin;
CREATE DATABASE shared OWNER dbadmin;
EOF

echo "✅ PostgreSQL deployed at port 5432"
echo ""
echo "Admin user: dbadmin"
echo "Admin password: $ADMIN_PASS"
echo ""
echo "Databases created: langfuse, n8n, shared"
echo ""
echo "Connection string template:"
echo "  postgresql://dbadmin:$ADMIN_PASS@$(hostname -I | awk '{print $1}'):5432/langfuse"
echo ""
echo "Save password to /root/.pgpass:"
echo "$(hostname -I | awk '{print $1}'):5432:*:dbadmin:$ADMIN_PASS" | tee -a /root/.pgpass
chmod 600 /root/.pgpass
