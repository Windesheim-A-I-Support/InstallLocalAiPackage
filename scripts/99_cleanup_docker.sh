#!/bin/bash
set -e

# Docker Cleanup Utility
# Removes unused Docker resources to free up disk space
# Usage: bash 99_cleanup_docker.sh [--aggressive]

if [ "$EUID" -ne 0 ]; then
  echo "❌ Run as root"
  exit 1
fi

echo "=== Docker Cleanup Utility ==="
echo ""

# Show current disk usage
echo "Current disk usage:"
df -h / | tail -1
echo ""
echo "Docker usage:"
du -sh /var/lib/docker/* 2>/dev/null | sort -h | tail -10
echo ""

# Basic cleanup
echo "=== Running basic cleanup ==="
echo "Removing stopped containers..."
docker container prune -f

echo "Removing dangling images..."
docker image prune -f

echo "Removing unused networks..."
docker network prune -f

echo "Removing build cache..."
docker buildx prune -f

# Aggressive cleanup
if [ "$1" = "--aggressive" ]; then
  echo ""
  echo "=== Running AGGRESSIVE cleanup ==="
  echo "⚠️  This will remove ALL unused images, not just dangling ones!"
  echo "Proceeding in 5 seconds... (Ctrl+C to cancel)"
  sleep 5

  echo "Removing all unused images..."
  docker image prune -a -f

  echo "Removing unused volumes..."
  docker volume prune -f

  echo "System-wide cleanup..."
  docker system prune -a -f --volumes
fi

echo ""
echo "=== Cleanup complete ==="
echo ""
echo "New disk usage:"
df -h / | tail -1
echo ""
echo "Docker usage:"
du -sh /var/lib/docker/* 2>/dev/null | sort -h | tail -10
echo ""

echo "✅ Cleanup completed"
echo ""
if [ "$1" != "--aggressive" ]; then
  echo "💡 For more aggressive cleanup, run:"
  echo "   bash 99_cleanup_docker.sh --aggressive"
  echo ""
  echo "⚠️  Aggressive mode removes ALL unused images and volumes!"
fi
