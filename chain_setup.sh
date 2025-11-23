#!/bin/bash
set -e # Exit immediately if a command fails

# ==============================================================================
# MASTER CHAIN INSTALLER
# Orchestrates: System Dep -> Docker Install -> Repo Clone -> Ultra Node Setup
# ==============================================================================

# 1. ROOT CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as ROOT to start."
  exit 1
fi

echo "========================================================="
echo "   STARTING AUTOMATED CHAIN DEPLOYMENT"
echo "========================================================="

# 2. RUN SYSTEM PREP (01)
echo "--> [Step 1/4] Running System Dependencies..."
chmod +x 01_system_dependencies.sh
./01_system_dependencies.sh

# 3. RUN DOCKER INSTALL (02)
echo "--> [Step 2/4] Running Docker Installation..."
chmod +x 02_install_docker.sh
./02_install_docker.sh

# ------------------------------------------------------------------------------
# THE HANDOFF: We need to know who the new user is to clone the repo correctly.
# ------------------------------------------------------------------------------
echo ""
echo "========================================================="
echo "   HANDOFF TO USER"
echo "========================================================="
echo "Please re-enter the username you created in the previous step."
echo "The rest of the installation will happen under this user's account."
read -p "Username: " TARGET_USER

if ! id "$TARGET_USER" &>/dev/null; then
    echo "❌ Error: User '$TARGET_USER' does not exist. Did the previous step fail?"
    exit 1
fi

# Define paths
USER_HOME="/home/$TARGET_USER"
REPO_DIR="$USER_HOME/local-ai-packaged"
AI_REPO_URL="https://github.com/coleam00/local-ai-packaged.git"

# 4. CLONE REPO & INJECT SCRIPT (Running as the Target User)
echo "--> [Step 3/4] Cloning AI Repository and Injecting Config..."

# We use 'su -c' to run these commands AS the user, not as root
su - "$TARGET_USER" -c "git clone -b stable $AI_REPO_URL $REPO_DIR"

# Move the python script from CURRENT directory (Root's execution folder) 
# to the USER'S new repo folder
cp setup_ultra_node.py "$REPO_DIR/"
chown "$TARGET_USER:$TARGET_USER" "$REPO_DIR/setup_ultra_node.py"

echo "✅ Repository cloned to: $REPO_DIR"

# 5. EXECUTE THE WIZARD (As Target User)
echo "--> [Step 4/4] Launching Ultra Node Wizard..."
echo "---------------------------------------------------------"
echo "Switching context to user: $TARGET_USER"
echo "Starting Python Wizard..."
echo "---------------------------------------------------------"

# This executes the python script inside the user's shell
su - "$TARGET_USER" -c "cd $REPO_DIR && python3 setup_ultra_node.py"

echo ""
echo "========================================================="
echo "   CHAIN COMPLETE"
echo "========================================================="
echo "To start your stack:"
echo "1. Log in as $TARGET_USER"
echo "2. cd local-ai-packaged"
echo "3. python3 start_services.py --profile cpu --environment private"
echo "========================================================="
