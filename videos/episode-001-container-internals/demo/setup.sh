#!/bin/bash
set -euo pipefail

# Episode 1 Demo Setup Script
# Container Internals Deep Dive

echo "🚀 Setting up Container Internals Demo Environment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running on Linux
if [[ "$(uname)" != "Linux" ]]; then
    echo -e "${RED}❌ This demo requires Linux. Please run on a Linux system or VM.${NC}"
    exit 1
fi

# Check if podman is installed
if ! command -v podman &> /dev/null; then
    echo -e "${RED}❌ Podman not found. Please install podman first.${NC}"
    echo "   Fedora/RHEL: sudo dnf install podman"
    echo "   Ubuntu: sudo apt install podman"
    exit 1
fi

# Check if strace is installed
if ! command -v strace &> /dev/null; then
    echo -e "${YELLOW}⚠️  strace not found. Installing...${NC}"
    if command -v dnf &> /dev/null; then
        sudo dnf install -y strace
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y strace
    else
        echo -e "${RED}❌ Cannot install strace automatically. Please install manually.${NC}"
        exit 1
    fi
fi

# Create demo directory structure
echo -e "${BLUE}📁 Creating demo directory structure...${NC}"
mkdir -p ~/container-internals-demo/{logs,scripts,output}
cd ~/container-internals-demo

# Pre-pull required container images
echo -e "${BLUE}🐳 Pre-pulling container images...${NC}"
images=("hello-world" "alpine:latest" "nginx:alpine")
for image in "${images[@]}"; do
    echo "   Pulling $image..."
    podman pull "$image" || {
        echo -e "${RED}❌ Failed to pull $image${NC}"
        exit 1
    }
done

# Create helper scripts
echo -e "${BLUE}📝 Creating helper scripts...${NC}"

# Namespace inspection script
cat > scripts/inspect-namespaces.sh << 'EOF'
#!/bin/bash
# Namespace inspection helper

if [ $# -ne 1 ]; then
    echo "Usage: $0 <container-name-or-id>"
    exit 1
fi

container=$1
pid=$(podman inspect "$container" --format '{{.State.Pid}}' 2>/dev/null)

if [ -z "$pid" ] || [ "$pid" = "0" ]; then
    echo "Container not found or not running: $container"
    exit 1
fi

echo "Container: $container (PID: $pid)"
echo "Host PID: $$"
echo
echo "=== NAMESPACE COMPARISON ==="
echo
echo "Container namespaces:"
ls -la /proc/$pid/ns/
echo
echo "Host namespaces:"
ls -la /proc/$$/ns/
echo
echo "=== NAMESPACE DETAILS ==="
for ns in /proc/$pid/ns/*; do
    ns_name=$(basename "$ns")
    container_ns=$(readlink "$ns")
    host_ns=$(readlink "/proc/$$/ns/$ns_name")
    
    if [ "$container_ns" = "$host_ns" ]; then
        status="SHARED"
    else
        status="ISOLATED"
    fi
    
    printf "%-12s: %s [%s]\n" "$ns_name" "$container_ns" "$status"
done
EOF

# Cgroup inspection script
cat > scripts/inspect-cgroups.sh << 'EOF'
#!/bin/bash
# Cgroup inspection helper

if [ $# -ne 1 ]; then
    echo "Usage: $0 <container-name-or-id>"
    exit 1
fi

container=$1
pid=$(podman inspect "$container" --format '{{.State.Pid}}' 2>/dev/null)

if [ -z "$pid" ] || [ "$pid" = "0" ]; then
    echo "Container not found or not running: $container"
    exit 1
fi

echo "Container: $container (PID: $pid)"
echo
echo "=== CGROUP INFORMATION ==="

# Find cgroup path
cgroup_path=$(cat /proc/$pid/cgroup | cut -d: -f3)
echo "Cgroup path: $cgroup_path"

# Check if cgroup path exists in v2 hierarchy
v2_path="/sys/fs/cgroup$cgroup_path"
if [ -d "$v2_path" ]; then
    echo "Cgroup v2 path: $v2_path"
    echo
    
    echo "Memory limits:"
    [ -f "$v2_path/memory.max" ] && echo "  memory.max: $(cat $v2_path/memory.max)"
    [ -f "$v2_path/memory.current" ] && echo "  memory.current: $(cat $v2_path/memory.current)"
    
    echo "CPU limits:"
    [ -f "$v2_path/cpu.max" ] && echo "  cpu.max: $(cat $v2_path/cpu.max)"
    [ -f "$v2_path/cpu.weight" ] && echo "  cpu.weight: $(cat $v2_path/cpu.weight)"
    
    echo "Process info:"
    [ -f "$v2_path/cgroup.procs" ] && echo "  processes: $(wc -l < $v2_path/cgroup.procs)"
else
    echo "Cgroup v2 path not found, checking v1..."
    # Add cgroup v1 fallback if needed
fi
EOF

# Resource monitoring script
cat > scripts/monitor-resources.sh << 'EOF'
#!/bin/bash
# Real-time resource monitoring

if [ $# -ne 1 ]; then
    echo "Usage: $0 <container-name-or-id>"
    exit 1
fi

container=$1

echo "Starting resource monitoring for container: $container"
echo "Press Ctrl+C to stop"
echo
echo "Timestamp,CPU%,Memory,Net I/O,Block I/O"

# Use podman stats with custom format
podman stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.NetIO}},{{.BlockIO}}" "$container" 2>/dev/null | while read line; do
    timestamp=$(date '+%H:%M:%S')
    echo "$timestamp,$line"
done
EOF

# Make scripts executable
chmod +x scripts/*.sh

# Create sample applications for demonstrations
echo -e "${BLUE}🔧 Creating sample applications...${NC}"

# Simple CPU stress application
cat > scripts/cpu-stress.py << 'EOF'
#!/usr/bin/env python3
import time
import threading

def cpu_stress():
    while True:
        pass

print("Starting CPU stress test...")
threads = []
for i in range(2):  # Create 2 threads
    t = threading.Thread(target=cpu_stress)
    t.daemon = True
    t.start()
    threads.append(t)

try:
    time.sleep(30)  # Run for 30 seconds
except KeyboardInterrupt:
    print("\nStopping CPU stress test...")
EOF

# Memory allocation test
cat > scripts/memory-test.py << 'EOF'
#!/usr/bin/env python3
import time

print("Starting memory allocation test...")
data = []

try:
    for i in range(100):
        # Allocate 1MB chunks
        chunk = 'x' * (1024 * 1024)
        data.append(chunk)
        print(f"Allocated {i+1} MB")
        time.sleep(0.5)
except MemoryError:
    print("Memory limit reached!")
except KeyboardInterrupt:
    print("\nStopping memory test...")

print(f"Total allocated: {len(data)} MB")
time.sleep(10)  # Keep data in memory
EOF

chmod +x scripts/*.py

# Create demonstration scenarios
echo -e "${BLUE}📋 Creating demonstration scenarios...${NC}"

cat > demo-scenarios.md << 'EOF'
# Episode 1 Demonstration Scenarios

## Scenario 1: System Call Tracing
```bash
# Terminal 1: Run strace on podman
sudo strace -f -o logs/podman-trace.log -e trace=clone,unshare,mount,pivot_root podman run --rm hello-world

# Analyze the trace
grep -E "(clone|unshare|mount|pivot_root)" logs/podman-trace.log | head -20
```

## Scenario 2: Namespace Exploration
```bash
# Start a long-running container
podman run -d --name demo-ns alpine sleep 300

# Inspect namespaces
./scripts/inspect-namespaces.sh demo-ns

# Compare process views
echo "=== Container process view ==="
podman exec demo-ns ps aux

echo "=== Host process view ==="
ps aux | grep -E "(sleep|alpine)"
```

## Scenario 3: Network Namespace Demo
```bash
# Check network interfaces in container vs host
echo "=== Container network ==="
podman exec demo-ns ip addr show

echo "=== Host network ==="
ip addr show | grep -A5 -B1 "^[0-9]:"
```

## Scenario 4: Cgroup Resource Management
```bash
# Start container with resource limits
podman run -d --name resource-demo --memory=100m --cpus=0.5 alpine sleep 300

# Inspect cgroups
./scripts/inspect-cgroups.sh resource-demo

# Monitor resources
./scripts/monitor-resources.sh resource-demo &
monitor_pid=$!

# Generate some load
podman exec resource-demo python3 -c "
import time
data = []
for i in range(50):
    data.append('x' * (1024 * 1024))
    time.sleep(0.1)
"

# Stop monitoring
kill $monitor_pid
```

## Scenario 5: Process Tree Visualization
```bash
# Show process hierarchy
pstree -p $(podman inspect demo-ns --format '{{.State.Pid}}')

# Show in systemd
systemd-cgls | grep -A10 demo-ns
```

## Cleanup Commands
```bash
podman stop --all
podman container prune -f
```
EOF

# Set up log directory with proper permissions
echo -e "${BLUE}📝 Setting up logging...${NC}"
sudo mkdir -p logs
sudo chown $USER:$USER logs

# Create a quick test to verify setup
echo -e "${BLUE}🧪 Testing setup...${NC}"
if podman run --rm hello-world > logs/setup-test.log 2>&1; then
    echo -e "${GREEN}✅ Basic container test successful!${NC}"
else
    echo -e "${RED}❌ Basic container test failed. Check logs/setup-test.log${NC}"
    exit 1
fi

# Final status
echo
echo -e "${GREEN}🎉 Demo environment setup complete!${NC}"
echo
echo "Setup location: ~/container-internals-demo"
echo "Available scripts:"
echo "  - scripts/inspect-namespaces.sh <container>"
echo "  - scripts/inspect-cgroups.sh <container>"
echo "  - scripts/monitor-resources.sh <container>"
echo
echo "To start demonstrations:"
echo "  cd ~/container-internals-demo"
echo "  cat demo-scenarios.md"
echo
echo -e "${BLUE}📺 Ready for Episode 1 recording!${NC}"