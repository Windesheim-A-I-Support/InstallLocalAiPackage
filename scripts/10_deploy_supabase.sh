#!/bin/bash
set -e

# Supabase deployment script (native PostgreSQL + PostgREST)
# Lightweight deployment without Docker

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== Supabase Deployment ==="

# Install PostgreSQL 15
apt update
apt install -y postgresql-15 postgresql-contrib-15

# Generate password
DB_PASS="${1:-SupabaseDB2025!Secure}"

# Configure PostgreSQL
sudo -u postgres psql << EOF
CREATE DATABASE supabase;
CREATE USER supabase WITH ENCRYPTED PASSWORD '$DB_PASS';
ALTER USER supabase WITH SUPERUSER;
GRANT ALL PRIVILEGES ON DATABASE supabase TO supabase;
EOF

# Install extensions
sudo -u postgres psql -d supabase << 'EOF'
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";
EOF

# Create roles for API access
sudo -u postgres psql -d supabase << EOF
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE service_role NOLOGIN;
GRANT anon TO supabase;
GRANT authenticated TO supabase;
GRANT service_role TO supabase;
EOF

# Install PostgREST
wget -q https://github.com/PostgREST/postgrest/releases/download/v12.2.3/postgrest-v12.2.3-linux-static-x64.tar.xz
tar xf postgrest-v12.2.3-linux-static-x64.tar.xz
mv postgrest /usr/local/bin/
chmod +x /usr/local/bin/postgrest

# Configure PostgREST
mkdir -p /etc/postgrest
cat > /etc/postgrest/config << EOF
db-uri = "postgres://supabase:$DB_PASS@localhost:5432/supabase"
db-schemas = "public"
db-anon-role = "anon"
server-host = "0.0.0.0"
server-port = 3000
jwt-secret = "your-super-secret-jwt-token-with-at-least-32-characters-long"
EOF

# Create systemd service
cat > /etc/systemd/system/postgrest.service << 'EOF'
[Unit]
Description=PostgREST API
After=postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=postgres
ExecStart=/usr/local/bin/postgrest /etc/postgrest/config
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable postgrest
systemctl start postgrest

echo "✅ Supabase deployed"
echo "Database: supabase"
echo "User: supabase"
echo "Password: $DB_PASS"
echo "API: http://localhost:3000"
