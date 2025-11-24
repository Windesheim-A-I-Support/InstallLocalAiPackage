#!/bin/bash
set -e # Stop if any error occurs

# 1. CHECK FOR ROOT
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   STEP 1: SYSTEM DEPENDENCIES & BASICS"
echo "========================================================="

# 2. UPDATE REPOSITORIES
echo "--> [1/3] Updating package lists..."
apt-get update -q

# 3. INSTALL MINIMAL REQUIRED PACKAGES
# For Debian 12 LXC container running Docker and Python scripts
echo "--> [2/3] Installing required packages..."
apt-get install -y -q \
    curl \
    ca-certificates \
    gnupg \
    git \
    python3

# Verify Python 3 is available (Debian 12 ships with Python 3.11)
python3 --version

# 4. CLEANUP
echo "--> [3/3] Cleaning up..."
apt-get autoremove -y -q
apt-get clean

echo "========================================================="
echo "✅ STEP 1 COMPLETE: System is ready for Docker."
echo "========================================================="
