#!/bin/bash
set -e

# 1. CHECK FOR ROOT
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   STEP 2: DOCKER ENGINE & USER PERMISSIONS"
echo "========================================================="

# 2. CLEAN UP OLD VERSIONS (Just in case)
echo "--> [1/5] Removing conflicting packages..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
    apt-get remove -y $pkg || true
done

# 3. SETUP DOCKER REPOSITORY (Official Method)
echo "--> [2/5] Setting up Docker Repository..."
install -m 0755 -d /etc/apt/keyrings
# Download GPG Key
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Repo to Apt Sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -q

# 4. INSTALL DOCKER ENGINE
echo "--> [3/5] Installing Docker Engine & Compose..."
apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. CONFIGURE USER PERMISSIONS (Crucial)
echo "---------------------------------------------------------"
echo "USER SETUP"
echo "We should not run the AI stack as root."
echo "---------------------------------------------------------"
read -p "Enter the username you want to use (e.g. 'admin' or 'aiuser'): " target_user

# Create user if it doesn't exist
if id "$target_user" &>/dev/null; then
    echo "--> User '$target_user' already exists."
else
    echo "--> Creating user '$target_user'..."
    adduser --gecos "" "$target_user"
fi

# Add to 'sudo' (admin rights) and 'docker' (container rights) groups
echo "--> [4/5] Granting permissions..."
usermod -aG sudo "$target_user"
usermod -aG docker "$target_user"

# 6. VERIFY
echo "--> [5/5] Verifying installation..."
docker_version=$(docker --version)
compose_version=$(docker compose version)

echo "========================================================="
echo "✅ STEP 2 COMPLETE"
echo "========================================================="
echo "Docker:  $docker_version"
echo "Compose: $compose_version"
echo "User:    $target_user is now a Docker admin."
echo "---------------------------------------------------------"
echo "⚠ CRITICAL FINAL STEP:"
echo "   You must LOG OUT of root and LOG IN as '$target_user'"
echo "   before running the AI deployment scripts."
echo "========================================================="
