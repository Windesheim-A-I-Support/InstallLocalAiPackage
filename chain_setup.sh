#!/bin/bash
set -e

# --- CONFIGURATION ---
AI_USER="ai-admin"
# ---------------------

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Run as ROOT."
  exit 1
fi

echo "========================================================="
echo "   AUTOMATED AI DEPLOYMENT CHAIN"
echo "   Target User: $AI_USER"
echo "========================================================="

# 1. SYSTEM PREP
echo "--> [1/4] System Dependencies..."
chmod +x 01_system_dependencies.sh
./01_system_dependencies.sh > /dev/null 2>&1

# 2. DOCKER & USER
echo "--> [2/4] Docker & User Setup..."
chmod +x 02_install_docker.sh
./02_install_docker.sh "$AI_USER" > /dev/null 2>&1

# 3. CLONE REPO
echo "--> [3/4] Cloning AI Repository..."
USER_HOME="/home/$AI_USER"
REPO_DIR="$USER_HOME/local-ai-packaged"
AI_REPO_URL="https://github.com/coleam00/local-ai-packaged.git"

# Clone as the user
su - "$AI_USER" -c "git clone -b stable $AI_REPO_URL $REPO_DIR" > /dev/null 2>&1

# Move Python Wizard
cp setup_ultra_node.py "$REPO_DIR/"
chown "$AI_USER:$AI_USER" "$REPO_DIR/setup_ultra_node.py"

# 4. LAUNCH WIZARD
echo "--> [4/4] Launching Configuration Wizard..."
echo "========================================================="
su - "$AI_USER" -c "cd $REPO_DIR && python3 setup_ultra_node.py"

echo ""
echo "========================================================="
echo "   DEPLOYMENT FINISHED"
echo "========================================================="
echo "To manage your stack:"
echo "   su - $AI_USER"
echo "   cd local-ai-packaged"
echo "   python3 start_services.py --profile cpu --environment private"
echo "========================================================="
