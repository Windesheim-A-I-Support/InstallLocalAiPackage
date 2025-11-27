#!/bin/bash
set -e

# ==============================================================================
# MASTER DEPLOYMENT SCRIPT - Local AI Stack on Debian 12
# ==============================================================================
# This script orchestrates the complete deployment from a BLANK Debian 12 image
# to a fully functional AI stack.
#
# USAGE:
#   As root:     bash 00_full_deployment.sh
#
# WHAT THIS DOES:
#   1. Installs system dependencies (sudo, git, curl, python3)
#   2. Installs Docker Engine
#   3. Creates ai-admin user
#   4. Switches to ai-admin and:
#      - Clones local-ai-packaged repository
#      - Generates all .env secrets
#      - Configures service integrations
#      - Deploys the stack
#   5. Optionally generates Traefik configuration
# ==============================================================================

# Configuration
AI_USER="ai-admin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  print_error "This script must be run as root"
  echo "Usage: sudo bash $0"
  exit 1
fi

print_step "LOCAL AI STACK - FULL DEPLOYMENT"
echo ""
echo "This will:"
echo "  1. Install system dependencies"
echo "  2. Install Docker"
echo "  3. Create user: $AI_USER"
echo "  4. Clone and configure local-ai-packaged"
echo "  5. Deploy the complete AI stack"
echo ""
print_warning "This takes 15-30 minutes depending on your connection"
echo ""
read -p "Press ENTER to continue or Ctrl+C to cancel..."
echo ""

# ==============================================================================
# PHASE 1: SYSTEM PREPARATION (as root)
# ==============================================================================

print_step "PHASE 1: SYSTEM DEPENDENCIES"
cd "$SCRIPT_DIR"
if [ -f "01_system_dependencies.sh" ]; then
    bash 01_system_dependencies.sh
    print_success "System dependencies installed"
else
    print_error "Script not found: 01_system_dependencies.sh"
    exit 1
fi

print_step "PHASE 2: DOCKER INSTALLATION"
if [ -f "02_install_docker.sh" ]; then
    bash 02_install_docker.sh "$AI_USER"
    print_success "Docker installed and $AI_USER user created"
else
    print_error "Script not found: 02_install_docker.sh"
    exit 1
fi

# ==============================================================================
# PHASE 2: APPLICATION DEPLOYMENT (as ai-admin)
# ==============================================================================

print_step "PHASE 3: SWITCHING TO USER $AI_USER"
print_warning "The remaining steps will run as $AI_USER (not root)"
echo ""

# Copy scripts to ai-admin's home for easy access
USER_HOME="/home/$AI_USER"
cp "$SCRIPT_DIR"/0*.sh "$USER_HOME/" 2>/dev/null || true
chown "$AI_USER:$AI_USER" "$USER_HOME"/*.sh 2>/dev/null || true

# Run remaining steps as ai-admin
su - "$AI_USER" << 'USERSCRIPT'
set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 3: Clone repository and setup environment
print_step "PHASE 3: CLONE REPOSITORY & SETUP ENVIRONMENT"
if [ -f "$HOME/03_clone_and_setup_env.sh" ]; then
    # Run non-interactively
    bash "$HOME/03_clone_and_setup_env.sh" <<< $'y\ny'
    print_success "Repository cloned and .env configured"
else
    print_error "Script not found: 03_clone_and_setup_env.sh"
    exit 1
fi

# Step 4: Configure service integrations
print_step "PHASE 4: CONFIGURE SERVICE INTEGRATIONS"
if [ -f "$HOME/04_configure_integrations.sh" ]; then
    bash "$HOME/04_configure_integrations.sh"
    print_success "Service integrations configured"
else
    print_error "Script not found: 04_configure_integrations.sh"
    exit 1
fi

# Step 5: Deploy the stack
print_step "PHASE 5: DEPLOY AI STACK"
if [ -f "$HOME/05_deploy_stack.sh" ]; then
    print_error "About to run deployment - this takes 5-10 minutes!"
    echo "Press ENTER to continue..."
    read
    bash "$HOME/05_deploy_stack.sh" cpu private <<< $'\n'
    print_success "AI Stack deployed successfully!"
else
    print_error "Script not found: 05_deploy_stack.sh"
    exit 1
fi

USERSCRIPT

# ==============================================================================
# FINAL STEPS
# ==============================================================================

print_step "DEPLOYMENT COMPLETE!"
echo ""
print_success "The AI stack is now running!"
echo ""
echo "Running containers:"
su - "$AI_USER" -c "docker ps --format 'table {{.Names}}\t{{.Status}}'"
echo ""
echo "To check logs:"
echo "  su - $AI_USER"
echo "  docker logs <container-name>"
echo ""
echo "To generate Traefik configuration:"
echo "  su - $AI_USER"
echo "  bash 06_generate_traefik_config.sh"
echo ""
print_success "All done! 🎉"
