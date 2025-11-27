#!/bin/bash
set -e

# ==============================================================================
# STEP 5: DEPLOY AI STACK
# This script runs the official start_services.py script
#
# IMPORTANT: This must be run LAST, after all .env and override files are configured
# Once this runs, you CANNOT change Supabase .env files (it's a known bug)
# ==============================================================================

# Configuration
REPO_DIR="/opt/local-ai-packaged"
PROFILE="${1:-cpu}"
ENVIRONMENT="${2:-private}"

# Check if running as the AI user (not root)
if [ "$EUID" -eq 0 ]; then
  echo "❌ Error: Do NOT run this script as root."
  exit 1
fi

echo "========================================================="
echo "   STEP 5: DEPLOYING AI STACK"
echo "========================================================="
echo ""
echo "Profile: $PROFILE"
echo "Environment: $ENVIRONMENT"
echo ""

# Change to repository directory
if [ ! -d "$REPO_DIR" ]; then
    echo "❌ Error: Repository directory $REPO_DIR not found."
    echo "   Please run 03_clone_and_setup_env.sh first."
    exit 1
fi

cd "$REPO_DIR"

# Fix git safe.directory (prevents "dubious ownership" errors in start_services.py)
git config --global --add safe.directory "$REPO_DIR" 2>/dev/null || true
git config --global --add safe.directory "$REPO_DIR/supabase" 2>/dev/null || true

# Verify prerequisites
echo "--> [1/3] Checking prerequisites..."

if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found."
    echo "   Please run 03_clone_and_setup_env.sh first."
    exit 1
fi

if [ ! -f "docker-compose.override.private.yml" ]; then
    echo "❌ Error: docker-compose.override.private.yml not found."
    echo "   The repository should have this file."
    exit 1
fi

if [ ! -f "start_services.py" ]; then
    echo "❌ Error: start_services.py not found."
    echo "   Check your repository clone."
    exit 1
fi

echo "✅ All prerequisites met"

# Check Docker is running
echo "--> [2/3] Checking Docker..."
if ! docker ps &>/dev/null; then
    echo "❌ Error: Docker is not running or you don't have permission."
    echo "   Make sure you're in the docker group: groups | grep docker"
    exit 1
fi
echo "✅ Docker is running"

# Run the deployment
echo "--> [3/3] Starting deployment..."
echo ""
echo "========================================================="
echo "   RUNNING: python3 start_services.py --profile $PROFILE --environment $ENVIRONMENT"
echo "========================================================="
echo ""
echo "⚠️  WARNING: This will take 5-10 minutes on first run!"
echo "⚠️  DO NOT interrupt this process."
echo "⚠️  Once started, you CANNOT change Supabase .env files."
echo ""
read -p "Press ENTER to continue or Ctrl+C to cancel..."
echo ""

# Run the official deployment script
python3 start_services.py --profile "$PROFILE" --environment "$ENVIRONMENT"

echo ""
echo "========================================================="
echo "✅ STEP 5 COMPLETE: AI Stack deployed"
echo "========================================================="
echo ""
echo "Services should now be starting up. Check with:"
echo "  docker ps"
echo ""
echo "To check logs:"
echo "  docker logs <container-name>"
echo ""
echo "Next step (optional): Run 06_generate_traefik_config.sh"
echo "========================================================="
