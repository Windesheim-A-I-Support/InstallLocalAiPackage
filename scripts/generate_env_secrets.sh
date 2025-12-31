#!/bin/bash
set -e

echo "========================================================="
echo "   GENERATING .ENV SECRETS"
echo "========================================================="

# This script generates secure random values for all required secrets in .env
# Usage: Run this in the local-ai-packaged directory after copying .env.example to .env
# Example: ./generate_env_secrets.sh

if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found. Please copy .env.example to .env first:"
    echo "   cp .env.example .env"
    exit 1
fi

echo "--> Generating secure random secrets..."

# Generate secrets using Python - ONLY for variables in .env.example that need secrets
N8N_ENCRYPTION_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
N8N_USER_MANAGEMENT_JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))")
POSTGRES_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(48))")
NEO4J_PASS=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))")
CLICKHOUSE_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
MINIO_ROOT_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
LANGFUSE_SALT=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
NEXTAUTH_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
ENCRYPTION_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
DASHBOARD_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(20))")
POOLER_TENANT_ID=$(python3 -c "import random; print(random.randint(1000, 9999))")
SECRET_KEY_BASE=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
VAULT_ENC_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
REDIS_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
SEARXNG_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
PIPELINES_API_KEY="0p3n-w3bu!"  # Default pipelines API key

echo "--> Updating .env file with generated secrets..."

# Update .env file with generated values - only the ones that exist in .env.example
sed -i "s|^N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}|" .env
sed -i "s|^N8N_USER_MANAGEMENT_JWT_SECRET=.*|N8N_USER_MANAGEMENT_JWT_SECRET=${N8N_USER_MANAGEMENT_JWT_SECRET}|" .env
sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${POSTGRES_PASSWORD}|" .env
sed -i "s|^JWT_SECRET=.*|JWT_SECRET=${JWT_SECRET}|" .env
sed -i "s|^NEO4J_AUTH=.*|NEO4J_AUTH=neo4j/${NEO4J_PASS}|" .env
sed -i "s|^CLICKHOUSE_PASSWORD=.*|CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}|" .env
sed -i "s|^MINIO_ROOT_PASSWORD=.*|MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}|" .env
sed -i "s|^LANGFUSE_SALT=.*|LANGFUSE_SALT=${LANGFUSE_SALT}|" .env
sed -i "s|^NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=${NEXTAUTH_SECRET}|" .env
sed -i "s|^ENCRYPTION_KEY=.*|ENCRYPTION_KEY=${ENCRYPTION_KEY}|" .env
sed -i "s|^DASHBOARD_PASSWORD=.*|DASHBOARD_PASSWORD=${DASHBOARD_PASSWORD}|" .env
sed -i "s|^POOLER_TENANT_ID=.*|POOLER_TENANT_ID=${POOLER_TENANT_ID}|" .env
sed -i "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=${SECRET_KEY_BASE}|" .env
sed -i "s|^VAULT_ENC_KEY=.*|VAULT_ENC_KEY=${VAULT_ENC_KEY}|" .env
sed -i "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=${REDIS_PASSWORD}|" .env
sed -i "s|^SEARXNG_SECRET=.*|SEARXNG_SECRET=${SEARXNG_SECRET}|" .env
sed -i "s|^PIPELINES_API_KEY=.*|PIPELINES_API_KEY=${PIPELINES_API_KEY}|" .env

echo ""
echo "========================================================="
echo "✅ SECRETS GENERATED SUCCESSFULLY"
echo "========================================================="
echo ""
echo "The following secrets have been generated and saved to .env:"
echo ""
echo "N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY:0:20}..."
echo "N8N_USER_MANAGEMENT_JWT_SECRET: ${N8N_USER_MANAGEMENT_JWT_SECRET:0:20}..."
echo "POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:0:20}..."
echo "JWT_SECRET: ${JWT_SECRET:0:20}..."
echo "NEO4J_AUTH: neo4j/${NEO4J_PASS:0:10}..."
echo "CLICKHOUSE_PASSWORD: ${CLICKHOUSE_PASSWORD:0:20}..."
echo "MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:0:20}..."
echo "LANGFUSE_SALT: ${LANGFUSE_SALT:0:20}..."
echo "NEXTAUTH_SECRET: ${NEXTAUTH_SECRET:0:20}..."
echo "ENCRYPTION_KEY: ${ENCRYPTION_KEY:0:20}..."
echo "DASHBOARD_PASSWORD: ${DASHBOARD_PASSWORD:0:10}..."
echo "POOLER_TENANT_ID: ${POOLER_TENANT_ID}"
echo "SECRET_KEY_BASE: ${SECRET_KEY_BASE:0:20}..."
echo "VAULT_ENC_KEY: ${VAULT_ENC_KEY:0:20}..."
echo "REDIS_PASSWORD: ${REDIS_PASSWORD:0:20}..."
echo "SEARXNG_SECRET: ${SEARXNG_SECRET:0:20}..."
echo "PIPELINES_API_KEY: ${PIPELINES_API_KEY}"
echo ""
echo "Your .env file is now ready for deployment!"
echo "========================================================="
