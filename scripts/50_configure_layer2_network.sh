#!/bin/bash
set -e

# Configure Layer 2 Bridge Network for Open WebUI
# Allows Open WebUI to get IP from DHCP on the physical network
# Avoids Docker networking issues with older Docker versions
# Usage: bash 50_configure_layer2_network.sh <interface_name>

INTERFACE="${1:-ens18}"

# Debian 12 compatibility checks
if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

# Check if running on Debian 12
if ! grep -q "Debian GNU/Linux 12" /etc/os-release 2>/dev/null; then
  echo "⚠️  Warning: This script is optimized for Debian 12"
  echo "Current OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
fi

if [ -z "$INTERFACE" ]; then
  echo "❌ Usage: bash 50_configure_layer2_network.sh <interface_name>"
  echo "Example: bash 50_configure_layer2_network.sh ens18"
  exit 1
fi

echo "=== Configuring Layer 2 Bridge Network ==="
echo "Physical interface: $INTERFACE"

# Check if interface exists
if ! ip link show $INTERFACE >/dev/null 2>&1; then
  echo "❌ Interface $INTERFACE not found"
  echo "Available interfaces:"
  ip link show | grep -E "^[0-9]+" | awk '{print $2}' | tr -d ':'
  exit 1
fi

# Install bridge-utils if not present
if ! command -v brctl >/dev/null 2>&1; then
  echo "Installing bridge-utils..."
  apt-get update
  apt-get install -y bridge-utils
fi

# Create bridge interface
echo "Creating bridge interface br0..."
ip link add br0 type bridge
ip link set br0 up
ip link set $INTERFACE master br0

# Get current IP configuration
CURRENT_IP=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | head -1)
CURRENT_GW=$(ip route | grep default | grep $INTERFACE | awk '{print $3}')

if [ -z "$CURRENT_IP" ] || [ -z "$CURRENT_GW" ]; then
  echo "❌ Could not detect current IP configuration automatically"
  echo "Please provide them manually:"
  read -p "Current IP (e.g., 10.0.5.24/24): " CURRENT_IP
  read -p "Gateway (e.g., 10.0.5.1): " CURRENT_GATEWAY
else
  CURRENT_GATEWAY=$CURRENT_GW
fi

echo "Detected configuration:"
echo "  Current IP: $CURRENT_IP"
echo "  Gateway: $CURRENT_GATEWAY"
echo "  Interface: $INTERFACE"

# Assign IP to bridge instead of physical interface
ip addr flush dev $INTERFACE
ip addr add $CURRENT_IP dev br0

# Update default route
ip route del default
ip route add default via $CURRENT_GATEWAY dev br0

echo "✅ Layer 2 bridge network created"
echo ""
echo "Bridge Details:"
echo "  Name: br0"
echo "  Type: bridge"
echo "  IP: $CURRENT_IP"
echo "  Gateway: $CURRENT_GATEWAY"
echo "  Master: $INTERFACE"
echo ""
echo "Deploy Open WebUI instances using:"
echo "  bash 15_deploy_openwebui_instance.sh webui1 10.0.5.200"
echo "  bash 15_deploy_openwebui_instance.sh webui2 10.0.5.201"
echo ""
echo "IP Range Recommendations:"
echo "  10.0.5.200-209: Open WebUI instances"
echo "  10.0.5.210-254: Other dynamic deployments"
echo ""
echo "⚠️  Note: Bridge allows containers to get IPs from the physical network."
echo "   Use dedicated IPs for all services that need to talk to each other."
