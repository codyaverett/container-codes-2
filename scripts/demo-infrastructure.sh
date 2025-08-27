#!/bin/bash
set -euo pipefail

# ContainerCodes Demo Infrastructure Management Script
# Provides reusable infrastructure for all episode demonstrations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DEMO_BASE_DIR="$HOME/containercodes-demos"
EPISODE_PREFIX="episode"
COMMON_IMAGES=("alpine:latest" "nginx:alpine" "hello-world" "registry.access.redhat.com/ubi8/ubi-minimal")

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${PURPLE}🎬 $1${NC}"
}

# Function to check system requirements
check_requirements() {
    log_header "Checking System Requirements"
    
    local missing_tools=()
    
    # Check for required tools
    local required_tools=("podman" "strace" "curl" "git")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install missing tools and re-run this script"
        return 1
    fi
    
    # Check Linux vs other OS
    if [[ "$(uname)" != "Linux" ]]; then
        log_warning "This script is designed for Linux. Some features may not work on $(uname)."
        log_info "Consider running in a Linux VM or container"
    fi
    
    # Check user namespaces (for rootless containers)
    if [ -f /proc/sys/user/max_user_namespaces ]; then
        local max_ns=$(cat /proc/sys/user/max_user_namespaces)
        if [ "$max_ns" -eq 0 ]; then
            log_warning "User namespaces are disabled. Some rootless demos may not work."
            log_info "Enable with: echo 1 | sudo tee /proc/sys/user/max_user_namespaces"
        fi
    fi
    
    log_success "System requirements check completed"
}

# Function to create demo directory structure
create_demo_structure() {
    local episode_num="$1"
    local episode_name="$2"
    
    log_header "Creating Demo Structure for Episode $episode_num"
    
    local episode_dir="$DEMO_BASE_DIR/${EPISODE_PREFIX}-$(printf "%03d" "$episode_num")-$episode_name"
    
    mkdir -p "$episode_dir"/{scripts,logs,output,temp,config}
    
    # Create standard scripts
    cat > "$episode_dir/scripts/setup.sh" << 'EOF'
#!/bin/bash
# Episode-specific setup script
set -euo pipefail

echo "Setting up episode demonstration environment..."

# Pull required images
images=("alpine:latest" "nginx:alpine")
for image in "${images[@]}"; do
    echo "Pulling $image..."
    podman pull "$image"
done

echo "Episode setup complete!"
EOF

    cat > "$episode_dir/scripts/cleanup.sh" << 'EOF'
#!/bin/bash
# Episode-specific cleanup script
set -euo pipefail

echo "Cleaning up episode demonstration..."

# Stop all containers
podman stop --all 2>/dev/null || true

# Remove containers
podman container prune -f

# Clean up temporary files
rm -rf ../temp/*
rm -rf ../logs/*
rm -rf ../output/*

echo "Episode cleanup complete!"
EOF

    chmod +x "$episode_dir/scripts"/*.sh
    
    # Create README for episode
    cat > "$episode_dir/README.md" << EOF
# Episode $episode_num: $episode_name Demo Environment

## Directory Structure
- \`scripts/\` - Setup and cleanup scripts
- \`logs/\` - Command output and system logs
- \`output/\` - Generated files and results
- \`temp/\` - Temporary files (auto-cleaned)
- \`config/\` - Configuration files

## Quick Start
\`\`\`bash
# Setup demo environment
./scripts/setup.sh

# Run your demonstrations here

# Clean up when done
./scripts/cleanup.sh
\`\`\`

## Episode Resources
- Script: [../../videos/${EPISODE_PREFIX}-$(printf "%03d" "$episode_num")-$episode_name/script.md]
- References: [../../videos/${EPISODE_PREFIX}-$(printf "%03d" "$episode_num")-$episode_name/references.md]
EOF

    log_success "Created demo structure: $episode_dir"
    echo "$episode_dir"
}

# Function to pull common container images
pull_common_images() {
    log_header "Pulling Common Container Images"
    
    for image in "${COMMON_IMAGES[@]}"; do
        log_info "Pulling $image..."
        if podman pull "$image"; then
            log_success "✓ $image"
        else
            log_warning "Failed to pull $image (continuing...)"
        fi
    done
}

# Function to create monitoring tools
create_monitoring_tools() {
    local target_dir="$1"
    
    log_header "Creating Monitoring Tools"
    
    # Resource monitoring script
    cat > "$target_dir/scripts/monitor-resources.sh" << 'EOF'
#!/bin/bash
# Real-time resource monitoring for containers

if [ $# -eq 0 ]; then
    echo "Usage: $0 <container-name-or-id> [duration-seconds]"
    echo "Example: $0 my-container 30"
    exit 1
fi

container="$1"
duration="${2:-60}"  # Default 60 seconds

echo "Monitoring container: $container for $duration seconds"
echo "Timestamp,CPU%,Memory,Net I/O,Block I/O,PIDs" > "../output/resource-monitor-$container.csv"

end_time=$((SECONDS + duration))
while [ $SECONDS -lt $end_time ]; do
    timestamp=$(date '+%H:%M:%S')
    stats=$(podman stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.NetIO}},{{.BlockIO}},{{.PIDs}}" "$container" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$timestamp,$stats" >> "../output/resource-monitor-$container.csv"
        echo "$timestamp: $stats"
    else
        echo "$timestamp: Container not found or stopped"
        break
    fi
    sleep 2
done

echo "Monitoring complete. Results saved to ../output/resource-monitor-$container.csv"
EOF

    # Network analysis script
    cat > "$target_dir/scripts/analyze-network.sh" << 'EOF'
#!/bin/bash
# Network analysis for containers

if [ $# -ne 1 ]; then
    echo "Usage: $0 <container-name-or-id>"
    exit 1
fi

container="$1"

echo "=== Container Network Analysis ==="
echo "Container: $container"
echo

# Get container PID
pid=$(podman inspect "$container" --format '{{.State.Pid}}' 2>/dev/null)
if [ -z "$pid" ] || [ "$pid" = "0" ]; then
    echo "Container not found or not running"
    exit 1
fi

echo "Container PID: $pid"
echo

# Network namespace info
echo "=== Network Namespace ==="
echo "Container network namespace:"
ls -la /proc/$pid/ns/net
echo "Host network namespace:"
ls -la /proc/$$/ns/net
echo

# Network interfaces
echo "=== Network Interfaces ==="
echo "Container interfaces:"
podman exec "$container" ip addr show 2>/dev/null || echo "Failed to get container interfaces"
echo
echo "Host interfaces (summary):"
ip addr show | grep -E '^[0-9]+:|inet ' | head -10
echo

# Routing table
echo "=== Routing Information ==="
echo "Container routes:"
podman exec "$container" ip route show 2>/dev/null || echo "Failed to get container routes"
echo
echo "Host default route:"
ip route show default
echo

# Port bindings
echo "=== Port Bindings ==="
podman port "$container" 2>/dev/null || echo "No port bindings found"
EOF

    # Process analysis script
    cat > "$target_dir/scripts/analyze-processes.sh" << 'EOF'
#!/bin/bash
# Process analysis for containers

if [ $# -ne 1 ]; then
    echo "Usage: $0 <container-name-or-id>"
    exit 1
fi

container="$1"

echo "=== Container Process Analysis ==="
echo "Container: $container"
echo

# Get container PID
pid=$(podman inspect "$container" --format '{{.State.Pid}}' 2>/dev/null)
if [ -z "$pid" ] || [ "$pid" = "0" ]; then
    echo "Container not found or not running"
    exit 1
fi

echo "Container main PID: $pid"
echo

# Process tree
echo "=== Process Tree ==="
if command -v pstree >/dev/null 2>&1; then
    pstree -p "$pid" 2>/dev/null || echo "Failed to generate process tree"
else
    echo "pstree not available, showing ps output:"
    ps --pid "$pid" -o pid,ppid,cmd
fi
echo

# Container processes view
echo "=== Processes Inside Container ==="
podman exec "$container" ps aux 2>/dev/null || echo "Failed to get container processes"
echo

# Host processes (filtered)
echo "=== Related Host Processes ==="
ps aux | grep -E "(podman|conmon|$container)" | grep -v grep
EOF

    # Make all scripts executable
    chmod +x "$target_dir/scripts"/*.sh
    
    log_success "Created monitoring tools in $target_dir/scripts/"
}

# Function to setup episode-specific environment
setup_episode() {
    local episode_num="$1"
    local episode_name="$2"
    
    # Create demo structure
    local demo_dir=$(create_demo_structure "$episode_num" "$episode_name")
    
    # Create monitoring tools
    create_monitoring_tools "$demo_dir"
    
    # Pull common images
    pull_common_images
    
    # Episode-specific setup
    case "$episode_num" in
        1)
            log_info "Setting up Episode 1: Container Internals"
            # Copy Episode 1 specific demo files
            if [ -d "$PROJECT_ROOT/videos/episode-001-container-internals/demo" ]; then
                cp -r "$PROJECT_ROOT/videos/episode-001-container-internals/demo"/* "$demo_dir/"
            fi
            ;;
        2)
            log_info "Setting up Episode 2: Podman vs Docker Security"
            # Create security test scripts
            cat > "$demo_dir/scripts/security-test.sh" << 'EOF'
#!/bin/bash
# Security comparison tests for Episode 2

echo "=== Container Security Comparison Tests ==="
echo

# Test 1: Volume mount access
echo "Test 1: Attempting to access /etc/shadow via volume mount"
echo "Docker test:"
if command -v docker >/dev/null 2>&1; then
    timeout 10s docker run --rm -v /etc/shadow:/shadow alpine cat /shadow 2>&1 | head -1
else
    echo "Docker not available"
fi

echo "Podman test:"
timeout 10s podman run --rm -v /etc/shadow:/shadow alpine cat /shadow 2>&1 | head -1
echo

# Test 2: Process visibility with --pid=host
echo "Test 2: Host process visibility"
echo "Docker processes visible:"
if command -v docker >/dev/null 2>&1; then
    docker run --rm --pid=host alpine ps aux 2>/dev/null | wc -l
else
    echo "Docker not available"
fi

echo "Podman processes visible:"
podman run --rm --pid=host alpine ps aux 2>/dev/null | wc -l
echo

# Test 3: User namespace mapping
echo "Test 3: User namespace mapping (Podman only)"
echo "Container root mapped to host user:"
podman unshare cat /proc/self/uid_map
EOF
            chmod +x "$demo_dir/scripts/security-test.sh"
            ;;
    esac
    
    log_success "Episode $episode_num environment ready at: $demo_dir"
}

# Function to clean up all demos
cleanup_all() {
    log_header "Cleaning Up All Demo Environments"
    
    # Stop all containers
    podman stop --all 2>/dev/null || true
    podman container prune -f 2>/dev/null || true
    
    # Remove demo directories
    if [ -d "$DEMO_BASE_DIR" ]; then
        log_warning "This will remove all demo directories under $DEMO_BASE_DIR"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$DEMO_BASE_DIR"
            log_success "All demo environments cleaned up"
        else
            log_info "Cleanup cancelled"
        fi
    else
        log_info "No demo directories found to clean up"
    fi
}

# Function to list available episodes
list_episodes() {
    log_header "Available Episodes"
    
    if [ -d "$DEMO_BASE_DIR" ]; then
        for episode_dir in "$DEMO_BASE_DIR"/${EPISODE_PREFIX}-*; do
            if [ -d "$episode_dir" ]; then
                episode_name=$(basename "$episode_dir")
                echo "  📁 $episode_name"
            fi
        done
    else
        log_info "No demo environments found. Use 'setup' command to create one."
    fi
}

# Main function
main() {
    case "${1:-help}" in
        "check"|"requirements")
            check_requirements
            ;;
        "setup")
            if [ $# -ne 3 ]; then
                echo "Usage: $0 setup <episode-number> <episode-name>"
                echo "Example: $0 setup 1 container-internals"
                exit 1
            fi
            check_requirements
            setup_episode "$2" "$3"
            ;;
        "cleanup"|"clean")
            cleanup_all
            ;;
        "list")
            list_episodes
            ;;
        "pull"|"images")
            pull_common_images
            ;;
        "help"|*)
            echo "ContainerCodes Demo Infrastructure Management"
            echo
            echo "Usage: $0 <command> [arguments]"
            echo
            echo "Commands:"
            echo "  check         - Check system requirements"
            echo "  setup <num> <name> - Setup episode demo environment"
            echo "  list          - List available demo environments"  
            echo "  pull          - Pull common container images"
            echo "  cleanup       - Clean up all demo environments"
            echo "  help          - Show this help message"
            echo
            echo "Examples:"
            echo "  $0 check"
            echo "  $0 setup 1 container-internals"
            echo "  $0 setup 2 podman-security"
            echo "  $0 list"
            echo "  $0 cleanup"
            ;;
    esac
}

# Run main function with all arguments
main "$@"