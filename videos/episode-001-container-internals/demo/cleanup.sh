#!/bin/bash
set -euo pipefail

# Episode 1 Demo Cleanup Script
# Container Internals Deep Dive

echo "🧹 Cleaning up Container Internals Demo Environment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to safely run commands
safe_run() {
    if "$@" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Stop all running containers
echo -e "${BLUE}🛑 Stopping all containers...${NC}"
if safe_run podman ps -q; then
    running_containers=$(podman ps -q)
    if [ -n "$running_containers" ]; then
        echo "   Stopping containers: $running_containers"
        podman stop --all
    else
        echo "   No running containers found"
    fi
fi

# Remove all containers
echo -e "${BLUE}🗑️  Removing containers...${NC}"
if safe_run podman container ls -aq; then
    all_containers=$(podman container ls -aq)
    if [ -n "$all_containers" ]; then
        echo "   Removing containers..."
        podman container prune -f
        # Force remove any stubborn containers
        for container in $all_containers; do
            safe_run podman rm -f "$container"
        done
    else
        echo "   No containers to remove"
    fi
fi

# Clean up demo-specific containers by name
echo -e "${BLUE}🏷️  Cleaning up demo containers by name...${NC}"
demo_containers=("demo-container" "demo-ns" "resource-demo" "stress-test")
for container in "${demo_containers[@]}"; do
    if safe_run podman inspect "$container" --format '{{.State.Status}}'; then
        echo "   Removing $container..."
        safe_run podman rm -f "$container"
    fi
done

# Clean up pod networks (in case any pods were created)
echo -e "${BLUE}🌐 Cleaning up pod networks...${NC}"
if safe_run podman pod ls -q; then
    pods=$(podman pod ls -q)
    if [ -n "$pods" ]; then
        echo "   Removing pods..."
        podman pod rm -f --all
    fi
fi

# Optional: Remove images (commented out by default to preserve bandwidth)
# echo -e "${YELLOW}🐳 Remove demo images? (y/N)${NC}"
# read -r response
# if [[ "$response" =~ ^[Yy]$ ]]; then
#     echo -e "${BLUE}🗑️  Removing demo images...${NC}"
#     images=("hello-world" "alpine:latest" "nginx:alpine")
#     for image in "${images[@]}"; do
#         if safe_run podman image exists "$image"; then
#             echo "   Removing $image..."
#             safe_run podman rmi "$image"
#         fi
#     done
# fi

# Clean up dangling images and build cache
echo -e "${BLUE}🧹 Cleaning up dangling resources...${NC}"
safe_run podman image prune -f
safe_run podman system prune -f

# Clean up demo directory
if [ -d ~/container-internals-demo ]; then
    echo -e "${YELLOW}🗂️  Remove demo directory ~/container-internals-demo? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🗑️  Removing demo directory...${NC}"
        rm -rf ~/container-internals-demo
    else
        echo "   Keeping demo directory for reference"
        # Just clean up logs and temporary files
        if [ -d ~/container-internals-demo/logs ]; then
            rm -f ~/container-internals-demo/logs/*.log
        fi
        if [ -d ~/container-internals-demo/output ]; then
            rm -f ~/container-internals-demo/output/*
        fi
    fi
fi

# Kill any background monitoring processes
echo -e "${BLUE}🔍 Cleaning up background processes...${NC}"
# Kill any lingering strace processes
safe_run pkill -f "strace.*podman"
# Kill any monitoring scripts
safe_run pkill -f "monitor-resources.sh"

# Reset systemd user session if needed
echo -e "${BLUE}🔄 Resetting user session...${NC}"
if systemctl --user is-active podman.socket >/dev/null 2>&1; then
    echo "   Restarting podman user socket..."
    systemctl --user restart podman.socket
fi

# Verify cleanup
echo -e "${BLUE}✅ Verifying cleanup...${NC}"

# Check for remaining containers
remaining_containers=$(podman ps -aq 2>/dev/null | wc -l)
if [ "$remaining_containers" -eq 0 ]; then
    echo "   ✓ No containers remaining"
else
    echo -e "   ${YELLOW}⚠️  $remaining_containers containers still exist${NC}"
fi

# Check for remaining pods
remaining_pods=$(podman pod ls -q 2>/dev/null | wc -l)
if [ "$remaining_pods" -eq 0 ]; then
    echo "   ✓ No pods remaining"
else
    echo -e "   ${YELLOW}⚠️  $remaining_pods pods still exist${NC}"
fi

# Check system resources
echo -e "${BLUE}📊 System resource status:${NC}"
echo "   Memory usage: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')"
echo "   Disk usage: $(df -h . | awk 'NR==2{print $5}')"

# Show what images are still available
echo -e "${BLUE}🐳 Remaining container images:${NC}"
if safe_run podman images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"; then
    podman images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | head -10
else
    echo "   No images found"
fi

echo
echo -e "${GREEN}🎉 Cleanup complete!${NC}"
echo
echo "Summary:"
echo "  - All demo containers stopped and removed"
echo "  - Pod networks cleaned up" 
echo "  - Dangling images and cache cleaned"
echo "  - Background processes terminated"

# Provide instructions for complete cleanup if needed
echo
echo -e "${BLUE}💡 For complete cleanup (including all images):${NC}"
echo "   podman system reset"
echo "   rm -rf ~/.local/share/containers/"
echo
echo -e "${BLUE}📺 Ready for next episode!${NC}"