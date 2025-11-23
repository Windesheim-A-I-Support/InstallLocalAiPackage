#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# ==============================================================================
# DEBIAN 12 "BARE METAL" TO "AI HOST" PREP SCRIPT
# Installs: Sudo, Git, Docker (Official), Python3, Node.js, Build Tools
# ==============================================================================

# 1. ROOT CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   DEBIAN 12 SERVER PREPARATION"
echo "========================================================="

# 2. SYSTEM UPDATE & BASIC TOOLS
echo "--> [1/6] Updating system and installing base tools..."
apt-get update -q && apt-get upgrade -y -q
# 'sudo' is often missing on bare images. 'curl/gnupg' needed for repos.
apt-get install -y -q sudo curl wget git nano htop net-tools ca-certificates gnupg lsb-release build-essential

# 3. INSTALL DOCKER (Official Debian Guide)
echo "--> [2/6] Installing Docker Engine..."
# Clean up conflicting packages if any
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do apt-get remove -y $pkg || true; done

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -q
apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. INSTALL PYTHON ENV
echo "--> [3/6] Installing Python environment..."
# Debian 12 has Python 3.11+, we ensure pip and venv are present
apt-get install -y -q python3-pip python3-venv python3-dev

# 5. INSTALL NODE.JS (NodeSource LTS)
# Even though the stack is Dockerized, having Node on host is useful for n8n dev tools
echo "--> [4/6] Installing Node.js (LTS)..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update -q
apt-get install -y -q nodejs

# 6. USER CONFIGURATION
echo "--> [5/6] User Configuration"
echo "---------------------------------------------------------"
echo "We need a non-root user to manage the AI stack."
read -p "Enter username to create/update (e.g. admin): " target_user

if id "$target_user" &>/dev/null; then
    echo "✅ User '$target_user' exists."
else
    echo "Creating user '$target_user'..."
    adduser --gecos "" "$target_user"
fi

# Add to sudo and docker groups
usermod -aG sudo "$target_user"
usermod -aG docker "$target_user"

# 7. CLEANUP
echo "--> [6/6] Final cleanup..."
apt-get autoremove -y -q
apt-get clean

echo ""
echo "========================================================="
echo "SERVER PREP COMPLETE"
echo "========================================================="
echo "Docker: $(docker --version)"
echo "Python: $(python3 --version)"
echo "Node:   $(node --version)"
echo "User:   $target_user (Sudo + Docker access granted)"
echo "---------------------------------------------------------"
echo "⚠ ACTION REQUIRED: LOG OUT NOW and log back in as '$target_user'"
echo "   Then run the deployment script."
echo "========================================================="
