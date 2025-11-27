#!/bin/bash
set -e

# ==============================================================================
# STEP 3: CLONE REPOSITORY AND SETUP ENVIRONMENT
# This script:
# 1. Clones the official local-ai-packaged repository
# 2. Copies .env.example to .env
# 3. Generates ALL required secrets (including missing ones from generate_env_secrets.sh)
# ==============================================================================

# Configuration
REPO_URL="https://github.com/coleam00/local-ai-packaged.git"
REPO_BRANCH="stable"
REPO_DIR="/opt/local-ai-packaged"
AI_USER="${1:-ai-admin}"

# Check if running as the AI user (not root)
if [ "$EUID" -eq 0 ]; then
  echo "❌ Error: Do NOT run this script as root."
  echo "   Run as: su - $AI_USER -c 'bash 03_clone_and_setup_env.sh'"
  exit 1
fi

echo "========================================================="
echo "   STEP 3: CLONE REPO & SETUP ENVIRONMENT"
echo "========================================================="

# 1. CREATE /opt DIRECTORY AND SET PERMISSIONS
echo "--> [1/5] Setting up /opt directory..."
if [ ! -d "/opt" ]; then
  sudo mkdir -p /opt
fi

# Give current user ownership of /opt (or at least local-ai-packaged directory)
if [ -d "$REPO_DIR" ]; then
  echo "⚠️  Repository directory already exists at $REPO_DIR"
  read -p "Do you want to remove and re-clone? (y/N): " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    sudo rm -rf "$REPO_DIR"
  else
    echo "Using existing repository..."
    cd "$REPO_DIR"
    # Ensure we have ownership
    sudo chown -R $(whoami):$(whoami) "$REPO_DIR"
    # Skip to env setup
    if [ -f "start_services.py" ]; then
      echo "✅ Repository verified at $REPO_DIR"
    else
      echo "❌ Error: Repository incomplete - start_services.py not found."
      exit 1
    fi
  fi
fi

# 2. CLONE REPOSITORY
if [ ! -d "$REPO_DIR" ]; then
  echo "--> [2/5] Cloning local-ai-packaged repository..."
  sudo mkdir -p /opt
  sudo chown $(whoami):$(whoami) /opt
  git clone -b "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

# Fix git safe.directory (prevents "dubious ownership" errors when run as different user)
git config --global --add safe.directory "$REPO_DIR" 2>/dev/null || true
git config --global --add safe.directory "$REPO_DIR/supabase" 2>/dev/null || true

# Verify critical files exist
if [ ! -f "start_services.py" ]; then
  echo "❌ Error: Repository incomplete - start_services.py not found."
  exit 1
fi

if [ ! -f ".env.example" ]; then
  echo "❌ Error: Repository incomplete - .env.example not found."
  exit 1
fi

# 3. COPY .env.example TO .env
echo "--> [3/5] Setting up .env file..."
if [ -f ".env" ]; then
  echo "⚠️  .env file already exists"
  read -p "Do you want to overwrite it? (y/N): " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    cp .env.example .env
    echo "✅ Copied .env.example to .env"
  else
    echo "Keeping existing .env..."
  fi
else
  cp .env.example .env
  echo "✅ Copied .env.example to .env"
fi

# 3. GENERATE ALL SECRETS (Including missing ones)
echo "--> [4/5] Generating secure secrets..."

# Generate secrets using Python
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

# MISSING SECRETS (not in original generate_env_secrets.sh)
FLOWISE_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(20))")
PG_META_CRYPTO_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

# Update .env file with generated values
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

# Add missing variables if not present
grep -q "^FLOWISE_PASSWORD=" .env || echo "FLOWISE_PASSWORD=${FLOWISE_PASSWORD}" >> .env
sed -i "s|^FLOWISE_PASSWORD=.*|FLOWISE_PASSWORD=${FLOWISE_PASSWORD}|" .env

grep -q "^PG_META_CRYPTO_KEY=" .env || echo "PG_META_CRYPTO_KEY=${PG_META_CRYPTO_KEY}" >> .env
sed -i "s|^PG_META_CRYPTO_KEY=.*|PG_META_CRYPTO_KEY=${PG_META_CRYPTO_KEY}|" .env

grep -q "^FLOWISE_USERNAME=" .env || echo "FLOWISE_USERNAME=admin" >> .env
grep -q "^DOCKER_SOCKET_LOCATION=" .env || echo "DOCKER_SOCKET_LOCATION=/var/run/docker.sock" >> .env
grep -q "^POSTGRES_VERSION=" .env || echo "POSTGRES_VERSION=15" >> .env

# 4. VERIFY .env FILE
echo "--> [5/5] Verifying .env configuration..."

required_vars=(
  "N8N_ENCRYPTION_KEY"
  "POSTGRES_PASSWORD"
  "JWT_SECRET"
  "NEO4J_AUTH"
  "FLOWISE_USERNAME"
  "FLOWISE_PASSWORD"
  "PG_META_CRYPTO_KEY"
)

missing=0
for var in "${required_vars[@]}"; do
  if ! grep -q "^${var}=" .env; then
    echo "❌ Missing: $var"
    missing=$((missing + 1))
  fi
done

if [ $missing -gt 0 ]; then
  echo "❌ Error: $missing required variables are missing from .env"
  exit 1
fi

echo ""
echo "========================================================="
echo "✅ STEP 3 COMPLETE: Repository cloned and configured"
echo "========================================================="
echo ""
echo "Repository location: $REPO_DIR"
echo ""
echo "Generated secrets (first 20 chars shown):"
echo "  N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY:0:20}..."
echo "  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:0:20}..."
echo "  FLOWISE_PASSWORD: ${FLOWISE_PASSWORD:0:20}..."
echo ""
echo "Next step: Run 04_configure_integrations.sh"
echo "========================================================="
