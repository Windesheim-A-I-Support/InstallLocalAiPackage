#!/bin/bash
set -e # Exit on error

# 1. CHECK FOR ROOT
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

echo "========================================================="
echo "   OwPENING SSH ACCESS (ROOT + PASS + KEY)"
echo "   Context: VPN Protected Environment"
echo "========================================================="

# 2. INSTALL OPENSSH SERVER (If missing)
echo "--> [1/5] Ensuring OpenSSH Server is installed..."
apt-get update -q > /dev/null 2>&1
apt-get install -y -q openssh-server > /dev/null 2>&1

# 3. BACKUP CONFIGURATION
echo "--> [2/5] Backing up sshd_config..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak_$(date +%F_%T)

# 4. MODIFY SSH CONFIGURATION
# We use sed to find the settings (commented or not) and force them to 'yes'
echo "--> [3/5] modifying /etc/ssh/sshd_config..."

# A. Allow Root Login (Force 'yes')
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# B. Allow Password Authentication (Force 'yes')
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# C. Allow Public Key Authentication (Force 'yes')
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# D. Disable complex challenge modes that might confuse simple clients
sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

# E. Ensure empty passwords are NOT allowed (Basic sanity check)
sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# 5. ENSURE ROOT .SSH DIRECTORY EXISTS & ADD SSH KEY
# This ensures you can actually add keys later
echo "--> [4/5] Setting up SSH keys..."
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Add the Claude Code SSH key
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWvFcpfPYPzu6zxjLUlYDqmJYXRRbxexPBFR6NvSyR5 claude-code"

if ! grep -q "$SSH_KEY" /root/.ssh/authorized_keys 2>/dev/null; then
    echo "$SSH_KEY" >> /root/.ssh/authorized_keys
    echo "✅ Added claude-code SSH key to root authorized_keys"
else
    echo "✅ SSH key already present in authorized_keys"
fi

# 6. RESTART SERVICE
echo "--> [5/5] Restarting SSH Daemon..."
systemctl restart ssh || service ssh restart || echo "⚠️  Could not restart SSH (may be in LXC container)"

echo "========================================================="
echo "   ACCESS GRANTED"
echo "========================================================="
echo "1. Root Login: ENABLED"
echo "2. Password Auth: ENABLED"
echo "3. Key Auth: ENABLED"
echo "4. SSH Key Added: claude-code"
echo "---------------------------------------------------------"
echo "You can now SSH as root using your SSH key"
echo "To set/change password: Run 'passwd root'"
echo "========================================================="