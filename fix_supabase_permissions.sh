#!/bin/bash
set -e

# ==============================================================================
# FIX SUPABASE PERMISSIONS FOR UNPRIVILEGED LXC CONTAINERS
# Based on: https://stackoverflow.com/questions/72695311/
#
# This adds user: "root" to problematic Supabase services to fix:
# "failed to create shim task: OCI runtime create failed: runc create failed:
#  unable to start container process: error during container init:
#  open sysctl net.ipv4.ip_unprivileged_port_start file: reopen fd 8: permission denied"
# ==============================================================================

REPO_DIR="$HOME/local-ai-packaged"

if [ "$EUID" -eq 0 ]; then
  echo "❌ Error: Do NOT run this script as root."
  exit 1
fi

echo "========================================================="
echo "   FIXING SUPABASE PERMISSIONS"
echo "========================================================="

cd "$REPO_DIR"

if [ ! -f "supabase/docker/docker-compose.yml" ]; then
    echo "❌ Error: supabase/docker/docker-compose.yml not found"
    echo "   Run 05_deploy_stack.sh first to clone Supabase"
    exit 1
fi

# Backup the original file
cp supabase/docker/docker-compose.yml supabase/docker/docker-compose.yml.backup

echo "--> Patching Supabase docker-compose.yml..."

# Create Python script to patch the YAML
cat > /tmp/fix_supabase.py << 'PYTHON_SCRIPT'
import yaml
import sys

# Read the docker-compose file
with open('supabase/docker/docker-compose.yml', 'r') as f:
    compose = yaml.safe_load(f)

# Services that need user: "root" to avoid sysctl permission errors
services_to_fix = ['vector', 'imgproxy']

fixed_count = 0
for service in services_to_fix:
    if service in compose['services']:
        # Add user: "root" to the service
        compose['services'][service]['user'] = 'root'
        print(f"✅ Added user: root to {service}")
        fixed_count += 1
    else:
        print(f"⚠️  Service {service} not found")

if fixed_count > 0:
    # Write the modified compose file
    with open('supabase/docker/docker-compose.yml', 'w') as f:
        yaml.dump(compose, f, default_flow_style=False, sort_keys=False)
    print(f"\n✅ Fixed {fixed_count} services")
else:
    print("\n⚠️  No services were modified")
    sys.exit(1)
PYTHON_SCRIPT

# Check if PyYAML is installed
if ! python3 -c "import yaml" 2>/dev/null; then
    echo "Installing PyYAML..."
    python3 -m pip install --user PyYAML -q
fi

# Run the Python script
python3 /tmp/fix_supabase.py

# Clean up
rm /tmp/fix_supabase.py

echo ""
echo "========================================================="
echo "✅ SUPABASE PERMISSIONS FIXED"
echo "========================================================="
echo ""
echo "Backup saved to: supabase/docker/docker-compose.yml.backup"
echo ""
echo "Modified services:"
echo "  • vector - Added user: root"
echo "  • imgproxy - Added user: root"
echo ""
echo "Now you can run: bash 05_deploy_stack.sh cpu private"
echo "========================================================="
