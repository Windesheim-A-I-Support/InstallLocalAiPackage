#!/bin/bash
set -e

# ==============================================================================
# DOCKER INSTALLATION FOR PROXMOX LXC CONTAINERS
# ==============================================================================
# This script detects if the container is privileged or unprivileged and
# installs the appropriate Docker version with correct storage driver.
#
# Key differences:
# - UNPRIVILEGED: Needs Docker CE 24.x (NOT 25+), uses vfs storage driver
# - PRIVILEGED: Can use latest Docker, uses overlay2 storage driver
# ==============================================================================

# 1. CHECK FOR ROOT
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   STEP 2: DOCKER ENGINE & USER PERMISSIONS"
echo "========================================================="

# 2. DETECT CONTAINER TYPE (PRIVILEGED vs UNPRIVILEGED)
echo "--> [1/7] Detecting container type..."

# Check if we're in an unprivileged container
# In unprivileged containers, root (UID 0) inside the container is mapped to a high UID on the host
if [ -f /proc/self/uid_map ]; then
    # Read the UID mapping
    uid_map=$(cat /proc/self/uid_map)
    # Check if UID 0 is mapped to something other than 0 on the host
    if echo "$uid_map" | grep -q "^[[:space:]]*0[[:space:]]*[1-9]"; then
        CONTAINER_TYPE="unprivileged"
        echo "✅ Detected: UNPRIVILEGED container"
    else
        CONTAINER_TYPE="privileged"
        echo "✅ Detected: PRIVILEGED container"
    fi
else
    # If uid_map doesn't exist, assume privileged
    CONTAINER_TYPE="privileged"
    echo "✅ Detected: PRIVILEGED container (or bare metal)"
fi

# 3. CLEAN UP OLD VERSIONS
echo "--> [2/7] Removing conflicting packages..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    apt-get remove -y -q $pkg 2>/dev/null || true
done

# 4. SETUP DOCKER REPOSITORY
echo "--> [3/7] Setting up Docker repository..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -q

# 5. CONFIGURE DOCKER DAEMON (USE DOCKER DEFAULTS FOR STORAGE DRIVER)
echo "--> [4/7] Configuring Docker daemon..."
mkdir -p /etc/docker

# Let Docker choose the best available storage driver automatically
# For LXC containers, Docker will pick overlay2 or fuse-overlayfs depending on what's available
echo "✅ Using Docker's default storage driver (auto-detect)"
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# 6. INSTALL DOCKER (VERSION BASED ON CONTAINER TYPE)
echo "--> [5/7] Installing Docker..."

# CRITICAL: containerd.io 1.7.28-2+ breaks Docker in Proxmox LXC (CVE-2025-52881 patch)
# See: https://github.com/opencontainers/runc/issues/4968
# Solution: Use containerd.io 1.7.28-1 (last known good version) for BOTH privileged/unprivileged
CONTAINERD_SAFE="1.7.28-1"

echo "🔍 Searching for LXC-compatible Docker versions..."

# Find containerd.io 1.7.28-1 (last version before CVE-2025-52881 broke LXC)
CONTAINERD_VERSION=$(apt-cache madison containerd.io | grep "$CONTAINERD_SAFE" | head -1 | awk '{print $3}')

if [ -z "$CONTAINERD_VERSION" ]; then
    echo "⚠️  containerd.io $CONTAINERD_SAFE not found in repository"
    echo "    Trying to find any 1.7.x version before 1.7.28-2..."
    CONTAINERD_VERSION=$(apt-cache madison containerd.io | grep "1.7\." | grep -v "1.7.28-2" | head -1 | awk '{print $3}')
fi

if [ "$CONTAINER_TYPE" = "unprivileged" ]; then
    echo "📦 Installing Docker for UNPRIVILEGED container..."
    echo "   • Docker CE: Latest compatible"
    echo "   • containerd.io: $CONTAINERD_VERSION (LXC-safe)"
    echo "   • Storage driver: Auto-detect (overlay2/fuse-overlayfs)"

    if [ -n "$CONTAINERD_VERSION" ]; then
        apt-get install -y -q \
            docker-ce \
            docker-ce-cli \
            containerd.io="$CONTAINERD_VERSION" \
            docker-buildx-plugin \
            docker-compose-plugin

        # Lock containerd to prevent CVE-2025-52881 patch breaking LXC
        apt-mark hold containerd.io
        echo "🔒 Locked containerd.io to $CONTAINERD_VERSION"
    else
        echo "❌ ERROR: Could not find safe containerd.io version"
        echo "   Installing latest (may break Docker in LXC)"
        apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
else
    echo "📦 Installing Docker for PRIVILEGED container..."
    echo "   • Docker CE: Latest"
    echo "   • containerd.io: $CONTAINERD_VERSION (LXC-safe)"
    echo "   • Storage driver: Overlay2"

    if [ -n "$CONTAINERD_VERSION" ]; then
        apt-get install -y -q \
            docker-ce \
            docker-ce-cli \
            containerd.io="$CONTAINERD_VERSION" \
            docker-buildx-plugin \
            docker-compose-plugin

        # Lock containerd to prevent CVE-2025-52881 patch breaking LXC
        apt-mark hold containerd.io
        echo "🔒 Locked containerd.io to $CONTAINERD_VERSION"
    else
        echo "❌ ERROR: Could not find safe containerd.io version"
        echo "   Installing latest (may break Docker in LXC)"
        apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
fi

# 7. CONFIGURE USER PERMISSIONS
target_user="${1:-ai-admin}"

echo "---------------------------------------------------------"
echo "USER SETUP: $target_user"
echo "We should not run the AI stack as root."
echo "---------------------------------------------------------"

if id "$target_user" &>/dev/null; then
    echo "--> User '$target_user' already exists."
else
    echo "--> Creating user '$target_user'..."
    adduser --disabled-password --gecos "" "$target_user"
fi

echo "--> [4/5] Granting permissions..."
usermod -aG sudo "$target_user"
usermod -aG docker "$target_user"

echo "--> Creating NOPASSWD sudoers rule..."
echo "$target_user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$target_user
chmod 0440 /etc/sudoers.d/$target_user

# 8. RESTART DOCKER AND VERIFY
echo "--> [5/7] Restarting Docker daemon..."
systemctl daemon-reload
systemctl restart docker
sleep 2

# 9. COMPREHENSIVE TESTING
echo "--> [6/7] Running comprehensive Docker tests..."
echo ""

# Test 1: Basic hello-world
echo "🧪 Test 1: Docker hello-world..."
if docker run --rm hello-world > /dev/null 2>&1; then
    echo "✅ Test 1 PASSED: Basic Docker works"
else
    echo "❌ Test 1 FAILED: Docker hello-world failed"
    exit 1
fi

# Test 2: Test storage driver with Alpine
echo "🧪 Test 2: Testing storage driver with Alpine..."
if docker run --rm alpine:latest echo "Storage driver test successful" > /dev/null 2>&1; then
    echo "✅ Test 2 PASSED: Storage driver works"
else
    echo "❌ Test 2 FAILED: Storage driver test failed"
    exit 1
fi

# Test 3: Test docker compose
echo "🧪 Test 3: Testing docker compose..."
cat > /tmp/test-compose.yml <<'EOF'
version: '3'
services:
  test:
    image: alpine:latest
    command: echo "Docker Compose works"
EOF

if docker compose -f /tmp/test-compose.yml up --abort-on-container-exit > /dev/null 2>&1; then
    echo "✅ Test 3 PASSED: Docker Compose works"
    docker compose -f /tmp/test-compose.yml down > /dev/null 2>&1
else
    echo "❌ Test 3 FAILED: Docker Compose failed"
    rm -f /tmp/test-compose.yml
    exit 1
fi
rm -f /tmp/test-compose.yml

# Test 4: Test with the new user
echo "🧪 Test 4: Testing Docker with user '$target_user'..."
if su - "$target_user" -c "docker run --rm alpine:latest echo 'User permission test successful'" > /dev/null 2>&1; then
    echo "✅ Test 4 PASSED: User '$target_user' can run Docker"
else
    echo "❌ Test 4 FAILED: User '$target_user' cannot run Docker"
    echo "   Try logging out and back in, or run: newgrp docker"
    exit 1
fi

# Test 5: Test volume mounting (critical for AI stack)
echo "🧪 Test 5: Testing volume mounting..."
if docker run --rm -v /tmp:/data alpine:latest sh -c "echo test > /data/docker-test && cat /data/docker-test" > /dev/null 2>&1; then
    echo "✅ Test 5 PASSED: Volume mounting works"
    rm -f /tmp/docker-test
else
    echo "❌ Test 5 FAILED: Volume mounting failed"
    exit 1
fi

echo ""
echo "--> [7/7] All tests passed! ✨"

# 10. DISPLAY SUMMARY
docker_version=$(docker --version)
compose_version=$(docker compose version)
storage_driver=$(docker info 2>/dev/null | grep "Storage Driver" | awk '{print $3}')

echo ""
echo "========================================================="
echo "✅ STEP 2 COMPLETE"
echo "========================================================="
echo "Container Type: $CONTAINER_TYPE"
echo "Docker:         $docker_version"
echo "Compose:        $compose_version"
echo "Storage Driver: $storage_driver"
echo "User:           $target_user is now a Docker admin."
echo "---------------------------------------------------------"

if [ "$CONTAINER_TYPE" = "unprivileged" ]; then
    echo "⚠️  IMPORTANT NOTES FOR UNPRIVILEGED CONTAINERS:"
    echo "   • Using auto-detected storage driver (overlay2/fuse-overlayfs)"
    echo "   • Docker version locked to prevent upgrades"
    echo "   • Some features may be limited"
else
    echo "✅ PRIVILEGED CONTAINER:"
    echo "   • Using auto-detected storage driver (typically overlay2)"
    echo "   • Full Docker features available"
fi

echo "---------------------------------------------------------"
echo "⚠ CRITICAL FINAL STEP:"
echo "   You must LOG OUT of root and LOG IN as '$target_user'"
echo "   before running the AI deployment scripts."
echo "========================================================="
