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
echo "--> [1/4] Updating package lists..."
apt-get update -q && apt-get upgrade -y -q

# 3. INSTALL CORE UTILITIES
# sudo: Needed for user privileges later
# curl/wget/gnupg: Needed to download keys for Docker/Node
# git: Needed to clone the repo
# htop/net-tools: Needed for monitoring the server
echo "--> [2/4] Installing core utilities..."
apt-get install -y -q \
    sudo \
    curl \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    git \
    htop \
    net-tools \
    unzip \
    build-essential \
    software-properties-common

# 4. INSTALL PYTHON ENVIRONMENT
# The AI scripts use Python. Debian 12 requires venv for pip.
echo "--> [3/4] Installing Python 3 and Virtual Environment tools..."
apt-get install -y -q \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev

# 5. CLEANUP
echo "--> [4/4] Cleaning up..."
apt-get autoremove -y -q
apt-get clean

echo "========================================================="
echo "✅ STEP 1 COMPLETE: System is ready for Docker."
echo "========================================================="
