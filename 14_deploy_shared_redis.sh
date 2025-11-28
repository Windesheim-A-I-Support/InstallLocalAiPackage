#!/bin/bash
set -e

# Shared Redis cache
# For Open WebUI caching and session management

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== Redis Shared Service Deployment ==="

# Install Redis
apt update
apt install -y redis-server

# Generate password
REDIS_PASS=$(openssl rand -base64 32)

# Configure Redis
cat >> /etc/redis/redis.conf << EOF

# Security
requirepass $REDIS_PASS

# Network
bind 0.0.0.0
protected-mode yes

# Performance
maxmemory 512mb
maxmemory-policy allkeys-lru
EOF

systemctl restart redis-server
systemctl enable redis-server

echo "✅ Redis deployed at port 6379"
echo ""
echo "Password: $REDIS_PASS"
echo ""
echo "Connection string:"
echo "  redis://:$REDIS_PASS@$(hostname -I | awk '{print $1}'):6379/0"
echo ""
echo "Save to file:"
echo "$REDIS_PASS" > /root/.redis_password
chmod 600 /root/.redis_password
echo "Password saved to /root/.redis_password"
