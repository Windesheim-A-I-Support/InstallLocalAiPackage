#!/bin/bash
set -e

# Pin Docker to a Specific Version
# Prevents automatic updates that might break Layer 2 networking
# Usage: bash 51_pin_docker_version.sh [version]
#
# Recommended versions for Layer 2 stability:
#   - 24.0.7 (last stable 24.x)
#   - 23.0.6 (known stable)
#   - 20.10.24 (very stable, older)

DOCKER_VERSION="${1:-24.0.7}"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== Pinning Docker Version ==="
echo "Target version: $DOCKER_VERSION"

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed. Install Docker first."
  exit 1
fi

# Show current version
CURRENT_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+' | head -1)
echo "Current version: $CURRENT_VERSION"

if [ "$CURRENT_VERSION" = "$DOCKER_VERSION" ]; then
  echo "✅ Already running desired version $DOCKER_VERSION"
else
  echo "⚠️  Current version ($CURRENT_VERSION) differs from target ($DOCKER_VERSION)"
  read -p "Do you want to install Docker $DOCKER_VERSION? (yes/no): " CONFIRM

  if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
  fi

  # Remove current Docker
  echo "Removing current Docker installation..."
  systemctl stop docker || true
  systemctl stop docker.socket || true
  apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true

  # Install specific version
  echo "Installing Docker $DOCKER_VERSION..."
  apt-get update

  # Find exact package version
  VERSION_STRING=$(apt-cache madison docker-ce | grep $DOCKER_VERSION | head -1 | awk '{print $3}')

  if [ -z "$VERSION_STRING" ]; then
    echo "❌ Docker version $DOCKER_VERSION not found in repositories"
    echo "Available versions:"
    apt-cache madison docker-ce | awk '{print $3}' | head -10
    exit 1
  fi

  echo "Installing Docker CE version: $VERSION_STRING"
  apt-get install -y \
    docker-ce=$VERSION_STRING \
    docker-ce-cli=$VERSION_STRING \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
fi

# Hold Docker packages to prevent auto-updates
echo "Holding Docker packages at version $DOCKER_VERSION..."
apt-mark hold docker-ce docker-ce-cli containerd.io

echo ""
echo "✅ Docker version pinned successfully!"
echo ""
echo "Version: $(docker --version)"
echo "Packages held at version $DOCKER_VERSION"
echo ""
echo "To allow updates again (not recommended for Layer 2):"
echo "  apt-mark unhold docker-ce docker-ce-cli containerd.io"
echo ""
echo "To verify package hold status:"
echo "  apt-mark showhold"
