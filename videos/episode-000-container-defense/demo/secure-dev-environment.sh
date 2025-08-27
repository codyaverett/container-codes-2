#!/bin/bash
set -euo pipefail

# Secure Container Development Environment Demo for Episode 0
# Demonstrates how to create isolated, secure development environments using containers

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🏗️  Secure Container Development Environment Demo${NC}"
echo "===================================================="

# Create demo directory
DEMO_DIR="$HOME/secure-dev-environment-demo"
mkdir -p "$DEMO_DIR"/{environments,configs,projects}
cd "$DEMO_DIR"

echo -e "${BLUE}📁 Working in: $DEMO_DIR${NC}"

# Function to create development environment configurations
create_dev_configs() {
    echo -e "${YELLOW}📝 Creating secure development environment configurations...${NC}"
    
    # Python development environment
    cat << 'EOF' > configs/python-dev.containerfile
FROM python:3.11-alpine

# Create non-root user
RUN adduser -D -s /bin/bash devuser

# Install development tools
RUN apk add --no-cache \
    git \
    vim \
    curl \
    bash \
    openssh-client \
    build-base \
    libffi-dev

# Install common Python development tools
RUN pip install --no-cache-dir \
    pip-tools \
    black \
    flake8 \
    pytest \
    mypy \
    bandit \
    safety

# Set up workspace
RUN mkdir -p /workspace && chown devuser:devuser /workspace
WORKDIR /workspace

# Switch to non-root user
USER devuser

# Set up shell
RUN echo 'export PS1="🐍[secure-py] \w $ "' >> ~/.bashrc

CMD ["/bin/bash"]
EOF

    # Node.js development environment
    cat << 'EOF' > configs/nodejs-dev.containerfile
FROM node:18-alpine

# Create non-root user
RUN adduser -D -s /bin/bash devuser

# Install development tools
RUN apk add --no-cache \
    git \
    vim \
    curl \
    bash \
    openssh-client \
    python3 \
    make \
    g++

# Install global Node.js development tools
RUN npm install -g \
    @typescript-eslint/eslint-plugin \
    prettier \
    typescript \
    nodemon \
    npm-check-updates \
    audit-ci

# Set up workspace
RUN mkdir -p /workspace && chown devuser:devuser /workspace
WORKDIR /workspace

# Switch to non-root user
USER devuser

# Set up shell
RUN echo 'export PS1="🟢[secure-js] \w $ "' >> ~/.bashrc

CMD ["/bin/bash"]
EOF

    # Go development environment
    cat << 'EOF' > configs/go-dev.containerfile
FROM golang:1.21-alpine

# Create non-root user
RUN adduser -D -s /bin/bash devuser

# Install development tools
RUN apk add --no-cache \
    git \
    vim \
    curl \
    bash \
    openssh-client \
    make \
    gcc \
    musl-dev

# Install Go development tools
RUN go install golang.org/x/tools/cmd/goimports@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest

# Set up workspace
RUN mkdir -p /workspace && chown devuser:devuser /workspace
WORKDIR /workspace

# Switch to non-root user
USER devuser

# Set up Go environment
ENV GOPATH=/home/devuser/go
ENV PATH=$PATH:$GOPATH/bin
RUN mkdir -p $GOPATH/src $GOPATH/bin $GOPATH/pkg

# Set up shell
RUN echo 'export PS1="🔵[secure-go] \w $ "' >> ~/.bashrc

CMD ["/bin/bash"]
EOF

    # Multi-language development environment
    cat << 'EOF' > configs/polyglot-dev.containerfile
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    bash \
    openssh-client \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Python
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget -O go.tar.gz https://golang.org/dl/go1.21.0.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH=$PATH:/root/.cargo/bin

# Create non-root user
RUN useradd -m -s /bin/bash devuser \
    && usermod -aG sudo devuser \
    && echo 'devuser:devpass' | chpasswd

# Set up workspace
RUN mkdir -p /workspace && chown devuser:devuser /workspace
WORKDIR /workspace

# Switch to non-root user
USER devuser

# Set up environment for non-root user
ENV PATH=$PATH:/home/devuser/.cargo/bin
ENV GOPATH=/home/devuser/go
ENV PATH=$PATH:$GOPATH/bin
RUN mkdir -p $GOPATH/src $GOPATH/bin $GOPATH/pkg

# Install user-level tools
RUN python3 -m pip install --user black flake8 pytest mypy bandit safety && \
    npm install -g eslint prettier typescript && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Set up shell
RUN echo 'export PS1="🌈[secure-polyglot] \w $ "' >> ~/.bashrc

CMD ["/bin/bash"]
EOF

    echo -e "${GREEN}✅ Development environment configurations created${NC}"
}

# Function to build secure development environments
build_dev_environments() {
    echo -e "\n${BLUE}🔨 Building secure development environments...${NC}"
    
    environments=("python-dev" "nodejs-dev" "go-dev" "polyglot-dev")
    
    for env in "${environments[@]}"; do
        echo -e "${YELLOW}Building $env environment...${NC}"
        
        podman build \
            -t "secure-$env:latest" \
            -f "configs/$env.containerfile" \
            configs/ --quiet
        
        echo -e "${GREEN}✅ $env environment built${NC}"
    done
}

# Function to demonstrate isolated project workspaces
create_isolated_workspaces() {
    echo -e "\n${BLUE}📂 Creating isolated project workspaces...${NC}"
    
    # Create different trust-level projects
    mkdir -p projects/{trusted,experimental,external}
    
    # Trusted internal project
    mkdir -p projects/trusted/internal-api
    cat << 'EOF' > projects/trusted/internal-api/main.py
#!/usr/bin/env python3
"""
Trusted internal API - high confidence in security
"""
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'environment': 'trusted',
        'security_level': 'high'
    })

@app.route('/info')
def info():
    return jsonify({
        'app': 'internal-api',
        'version': '1.0.0',
        'python_version': os.sys.version
    })

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=False)
EOF

    # Experimental project with new dependencies
    mkdir -p projects/experimental/ai-experiment
    cat << 'EOF' > projects/experimental/ai-experiment/requirements.txt
# Experimental AI/ML dependencies - need security review
tensorflow==2.13.0
torch==2.0.1
transformers==4.21.0
pandas==2.0.3
numpy==1.24.3
scikit-learn==1.3.0
matplotlib==3.7.1
jupyter==1.0.0
ipython==8.14.0
EOF

    cat << 'EOF' > projects/experimental/ai-experiment/experiment.py
#!/usr/bin/env python3
"""
Experimental AI code - needs security review
"""
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier

def simple_ml_experiment():
    """Simple ML experiment for testing"""
    # Generate synthetic data
    np.random.seed(42)
    X = np.random.randn(1000, 4)
    y = (X[:, 0] + X[:, 1] > 0).astype(int)
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Train model
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # Evaluate
    accuracy = model.score(X_test, y_test)
    print(f"Model accuracy: {accuracy:.3f}")
    
    return model, accuracy

if __name__ == "__main__":
    print("🤖 Running AI experiment in isolated environment")
    model, acc = simple_ml_experiment()
    print(f"✅ Experiment complete. Accuracy: {acc:.3f}")
EOF

    # External/untrusted project
    mkdir -p projects/external/github-clone
    cat << 'EOF' > projects/external/github-clone/suspicious_script.py
#!/usr/bin/env python3
"""
Code downloaded from external source - UNTRUSTED
This simulates code that might have security issues
"""
import os
import subprocess
import urllib.request
import json

def analyze_environment():
    """Analyze the environment - might be doing more than expected"""
    info = {
        'os_name': os.name,
        'platform': os.uname() if hasattr(os, 'uname') else 'unknown',
        'env_vars': dict(os.environ),
        'current_dir': os.getcwd(),
        'home_dir': os.path.expanduser('~'),
    }
    
    # Try to access potentially sensitive files
    sensitive_paths = [
        '~/.ssh/id_rsa',
        '~/.aws/credentials',
        '/etc/passwd',
        '~/.bashrc',
        '~/.gitconfig'
    ]
    
    file_info = {}
    for path in sensitive_paths:
        expanded = os.path.expanduser(path)
        try:
            if os.path.exists(expanded):
                file_info[path] = {
                    'exists': True,
                    'size': os.path.getsize(expanded),
                    'permissions': oct(os.stat(expanded).st_mode)[-3:]
                }
        except (OSError, PermissionError):
            file_info[path] = {'exists': False, 'access_denied': True}
    
    info['files'] = file_info
    return info

def make_network_requests():
    """Make network requests - could be exfiltrating data"""
    urls = [
        'http://httpbin.org/ip',
        'http://httpbin.org/user-agent',
        'http://example.com'
    ]
    
    results = []
    for url in urls:
        try:
            print(f"Making request to: {url}")
            response = urllib.request.urlopen(url, timeout=5)
            content = response.read().decode('utf-8')
            results.append({
                'url': url,
                'status': 'success',
                'content_length': len(content)
            })
        except Exception as e:
            results.append({
                'url': url,
                'status': 'failed',
                'error': str(e)
            })
    
    return results

def main():
    print("🔍 Analyzing environment...")
    env_info = analyze_environment()
    
    print("🌐 Making network requests...")
    network_results = make_network_requests()
    
    # Save results (could be preparation for exfiltration)
    results = {
        'environment': env_info,
        'network': network_results
    }
    
    with open('/tmp/analysis_results.json', 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    print("📊 Analysis complete. Results saved to /tmp/analysis_results.json")
    print(f"Found {len(env_info.get('files', {}))} file paths checked")
    print(f"Made {len(network_results)} network requests")

if __name__ == "__main__":
    main()
EOF

    echo -e "${GREEN}✅ Isolated project workspaces created${NC}"
}

# Function to demonstrate different security levels
demonstrate_security_levels() {
    echo -e "\n${BLUE}🔒 Demonstrating Different Security Levels${NC}"
    
    # High Security: Trusted internal project
    echo -e "\n${GREEN}🟢 HIGH SECURITY: Trusted Internal Project${NC}"
    echo "Running trusted code with relaxed restrictions..."
    
    podman run -it --rm \
        --name trusted-workspace \
        --security-opt no-new-privileges \
        --cap-drop ALL \
        --cap-add SETUID \
        --cap-add SETGID \
        --memory 1g \
        --cpus 1.0 \
        --network bridge \
        -v "$(pwd)/projects/trusted:/workspace/trusted:Z" \
        -w /workspace/trusted/internal-api \
        secure-python-dev:latest \
        bash -c "
            echo '🟢 Trusted environment - relaxed restrictions'
            echo 'Available resources:'
            echo '  Memory: 1GB'
            echo '  CPU: 1 core'
            echo '  Network: Full bridge network access'
            echo '  Filesystem: Read-write to trusted projects'
            echo
            echo 'Running trusted application:'
            python main.py &
            APP_PID=\$!
            sleep 2
            curl -s http://localhost:5000/health | python -m json.tool || echo 'App not accessible (expected in demo)'
            kill \$APP_PID 2>/dev/null || true
            echo '✅ Trusted application tested'
        "
    
    # Medium Security: Experimental project
    echo -e "\n${YELLOW}🟡 MEDIUM SECURITY: Experimental Project${NC}"
    echo "Running experimental code with moderate restrictions..."
    
    podman run -it --rm \
        --name experimental-workspace \
        --security-opt no-new-privileges \
        --cap-drop ALL \
        --read-only \
        --tmpfs /tmp:rw,noexec,nosuid,size=200m \
        --tmpfs /workspace/temp:rw,noexec,nosuid,size=100m \
        --memory 512m \
        --cpus 0.5 \
        --network bridge \
        -v "$(pwd)/projects/experimental:/workspace/experimental:ro,Z" \
        -w /workspace/experimental/ai-experiment \
        secure-python-dev:latest \
        bash -c "
            echo '🟡 Experimental environment - moderate restrictions'
            echo 'Available resources:'
            echo '  Memory: 512MB'
            echo '  CPU: 0.5 cores'
            echo '  Network: Bridge network (monitored)'
            echo '  Filesystem: Read-only source, temp directories only'
            echo
            echo 'Installing dependencies to temp location:'
            export PIP_TARGET=/workspace/temp/packages
            export PYTHONPATH=/workspace/temp/packages
            mkdir -p /workspace/temp/packages
            pip install --target /workspace/temp/packages numpy pandas scikit-learn
            echo
            echo 'Running experimental code:'
            cp experiment.py /workspace/temp/
            cd /workspace/temp
            python experiment.py
            echo '✅ Experimental code tested safely'
        "
    
    # Low Security: External/untrusted code
    echo -e "\n${RED}🔴 LOW SECURITY: External/Untrusted Code${NC}"
    echo "Running untrusted code with maximum restrictions..."
    
    podman run -it --rm \
        --name untrusted-workspace \
        --security-opt no-new-privileges \
        --cap-drop ALL \
        --read-only \
        --tmpfs /tmp:rw,noexec,nosuid,size=50m \
        --memory 128m \
        --cpus 0.25 \
        --network none \
        -v "$(pwd)/projects/external:/workspace/external:ro,Z" \
        -w /workspace/external/github-clone \
        secure-python-dev:latest \
        bash -c "
            echo '🔴 Untrusted environment - maximum restrictions'
            echo 'Available resources:'
            echo '  Memory: 128MB'
            echo '  CPU: 0.25 cores'
            echo '  Network: NONE (completely isolated)'
            echo '  Filesystem: Read-only source, minimal temp space'
            echo
            echo 'Environment info:'
            whoami
            id
            mount | grep -E '(proc|sys|tmp)' | head -5
            echo
            echo 'Running suspicious code (safely isolated):'
            cp suspicious_script.py /tmp/
            cd /tmp
            python suspicious_script.py
            echo
            echo '📋 Results saved to:'
            ls -la /tmp/*.json 2>/dev/null || echo 'No results files found'
            echo '✅ Untrusted code contained successfully'
        "
}

# Function to demonstrate development workflow security
demonstrate_secure_workflow() {
    echo -e "\n${BLUE}🔄 Secure Development Workflow Demo${NC}"
    
    # Create a workflow script
    cat << 'EOF' > secure_dev_workflow.sh
#!/bin/bash
# Secure development workflow demonstration

set -euo pipefail

PROJECT_TYPE="$1"
SECURITY_LEVEL="$2"

echo "🔒 Secure Development Workflow"
echo "=============================="
echo "Project Type: $PROJECT_TYPE"
echo "Security Level: $SECURITY_LEVEL"
echo

# Set security parameters based on level
case "$SECURITY_LEVEL" in
    "high")
        MEMORY="1g"
        CPUS="1.0"
        NETWORK="bridge"
        MOUNT_MODE="rw"
        echo "🟢 High trust environment"
        ;;
    "medium")
        MEMORY="512m"
        CPUS="0.5"  
        NETWORK="bridge"
        MOUNT_MODE="ro"
        echo "🟡 Medium trust environment"
        ;;
    "low")
        MEMORY="256m"
        CPUS="0.25"
        NETWORK="none"
        MOUNT_MODE="ro"
        echo "🔴 Low trust environment"
        ;;
    *)
        echo "❌ Invalid security level: $SECURITY_LEVEL"
        exit 1
        ;;
esac

# Select appropriate development image
case "$PROJECT_TYPE" in
    "python")
        IMAGE="secure-python-dev:latest"
        ;;
    "nodejs")
        IMAGE="secure-nodejs-dev:latest"
        ;;
    "go")
        IMAGE="secure-go-dev:latest"
        ;;
    *)
        IMAGE="secure-polyglot-dev:latest"
        ;;
esac

echo "📦 Using image: $IMAGE"
echo "🔧 Security settings:"
echo "  Memory: $MEMORY"
echo "  CPU: $CPUS"
echo "  Network: $NETWORK"
echo "  Mount mode: $MOUNT_MODE"
echo

# Run development environment
echo "🚀 Launching secure development environment..."
podman run -it --rm \
    --name "secure-dev-$PROJECT_TYPE" \
    --security-opt no-new-privileges \
    --cap-drop ALL \
    --memory "$MEMORY" \
    --cpus "$CPUS" \
    --network "$NETWORK" \
    -v "/workspace/projects/$SECURITY_LEVEL:/workspace:$MOUNT_MODE" \
    "$IMAGE" \
    bash -c "
        echo 'Welcome to secure development environment!'
        echo 'Security level: $SECURITY_LEVEL'
        echo 'Project type: $PROJECT_TYPE'
        echo
        echo 'Available commands:'
        echo '  ls /workspace - view project files'
        echo '  cd /workspace - navigate to workspace'
        echo '  exit - leave environment'
        echo
        bash
    "

echo "✅ Development session ended"
EOF

    # Demonstrate the workflow
    echo "Demonstrating secure development workflows..."
    
    # Show how different projects get different security levels
    echo -e "\n${YELLOW}Workflow Examples:${NC}"
    
    podman run -it --rm \
        --name workflow-demo \
        --security-opt no-new-privileges \
        --cap-drop ALL \
        --read-only \
        --tmpfs /tmp:rw,size=50m \
        --network none \
        -v "$(pwd)/projects:/workspace/projects:ro" \
        -v "$(pwd)/secure_dev_workflow.sh:/app/workflow.sh:ro" \
        secure-python-dev:latest \
        bash -c "
            echo '📋 Available workflow configurations:'
            echo
            echo '🟢 High Security (Trusted):'
            echo '  bash /app/workflow.sh python high'
            echo '  Full resources, network access, read-write mounts'
            echo
            echo '🟡 Medium Security (Experimental):'
            echo '  bash /app/workflow.sh python medium'
            echo '  Limited resources, read-only mounts, network monitoring'
            echo
            echo '🔴 Low Security (Untrusted):'
            echo '  bash /app/workflow.sh python low'
            echo '  Minimal resources, no network, read-only everything'
            echo
            echo '🌈 Multi-language support:'
            echo '  bash /app/workflow.sh nodejs medium'
            echo '  bash /app/workflow.sh go high'
            echo '  bash /app/workflow.sh polyglot low'
            echo
            echo 'Choose security level based on code trust and project requirements!'
        "
}

# Function to demonstrate emergency containment
demonstrate_emergency_containment() {
    echo -e "\n${BLUE}🚨 Emergency Containment Demo${NC}"
    
    # Create a script that simulates malicious behavior
    cat << 'EOF' > malicious_simulation.py
#!/usr/bin/env python3
"""
Simulation of malicious behavior for containment demo
"""
import os
import time
import subprocess

def simulate_malicious_activity():
    """Simulate various malicious activities"""
    print("🚨 SIMULATING MALICIOUS BEHAVIOR (safely contained)")
    
    # Attempt 1: Try to access sensitive files
    print("\n1. Attempting to access sensitive files...")
    sensitive_files = ['/etc/passwd', '/etc/shadow', '/root/.ssh/id_rsa']
    for file in sensitive_files:
        try:
            with open(file, 'r') as f:
                content = f.read()[:100]
            print(f"   ⚠️  Accessed {file}: {len(content)} chars")
        except PermissionError:
            print(f"   🔒 Access denied to {file}")
        except FileNotFoundError:
            print(f"   ❌ File not found: {file}")
    
    # Attempt 2: Try to make network connections
    print("\n2. Attempting network connections...")
    try:
        import urllib.request
        response = urllib.request.urlopen('http://httpbin.org/ip', timeout=5)
        print("   🌐 Network access successful - could exfiltrate data!")
    except Exception as e:
        print(f"   🔒 Network blocked: {e}")
    
    # Attempt 3: Try to consume resources
    print("\n3. Attempting resource exhaustion...")
    try:
        # Try to allocate large amounts of memory
        big_list = []
        for i in range(1000):
            big_list.append('x' * 1024 * 1024)  # 1MB per iteration
            if i % 100 == 0:
                print(f"   📈 Allocated {i} MB...")
        print("   ⚠️  Resource exhaustion successful!")
    except MemoryError:
        print("   🔒 Memory limits prevented exhaustion")
    except Exception as e:
        print(f"   🔒 Resource limits active: {e}")
    
    # Attempt 4: Try to execute system commands
    print("\n4. Attempting system command execution...")
    commands = ['whoami', 'id', 'ps aux', 'mount', 'cat /proc/version']
    for cmd in commands:
        try:
            result = subprocess.run(cmd.split(), capture_output=True, text=True, timeout=2)
            if result.returncode == 0:
                print(f"   ⚠️  Executed: {cmd}")
            else:
                print(f"   🔒 Command failed: {cmd}")
        except Exception as e:
            print(f"   🔒 Command blocked: {cmd} - {e}")
    
    print("\n✅ Malicious simulation complete - all contained!")

if __name__ == "__main__":
    simulate_malicious_activity()
EOF

    # Run the containment demonstration
    echo "Demonstrating emergency containment of malicious code..."
    
    echo -e "\n${YELLOW}Running malicious simulation in maximum security container...${NC}"
    
    podman run -it --rm \
        --name malicious-containment-demo \
        --security-opt no-new-privileges \
        --security-opt seccomp=default \
        --cap-drop ALL \
        --read-only \
        --tmpfs /tmp:rw,noexec,nosuid,size=10m \
        --memory 64m \
        --cpus 0.1 \
        --network none \
        --pids-limit 50 \
        --ulimit nofile=100:100 \
        -v "$(pwd)/malicious_simulation.py:/app/malicious.py:ro" \
        python:3.11-alpine \
        sh -c "
            echo '🔒 Maximum security containment active:'
            echo '  - Memory limit: 64MB'
            echo '  - CPU limit: 0.1 cores'
            echo '  - No network access'
            echo '  - Read-only filesystem'
            echo '  - No new privileges'
            echo '  - Limited process count'
            echo '  - Limited file descriptors'
            echo
            echo 'Container environment:'
            whoami
            id
            echo
            echo 'Running malicious code:'
            python /app/malicious.py
            echo
            echo '🛡️  All malicious attempts safely contained!'
        "
    
    echo -e "${GREEN}✅ Emergency containment demonstration complete${NC}"
}

# Main execution
main() {
    echo -e "${PURPLE}🚀 Starting Secure Development Environment Demo${NC}"
    
    # Create development environment configurations
    create_dev_configs
    
    # Build secure development environments
    build_dev_environments
    
    # Create isolated project workspaces
    create_isolated_workspaces
    
    # Demonstrate different security levels
    demonstrate_security_levels
    
    # Show secure development workflow
    demonstrate_secure_workflow
    
    # Demonstrate emergency containment
    demonstrate_emergency_containment
    
    echo -e "\n${GREEN}🎉 Secure Development Environment Demo Complete!${NC}"
    echo -e "${BLUE}Key Takeaways:${NC}"
    echo "1. 🏗️  Use containerized development environments for isolation"
    echo "2. 🔒 Apply different security levels based on code trust"
    echo "3. 🚫 Restrict resources, network, and filesystem access appropriately"
    echo "4. 🔄 Implement secure workflows for different project types"
    echo "5. 🚨 Have emergency containment procedures ready"
    echo "6. 👤 Always use non-root users in development containers"
    echo "7. 📋 Monitor and audit development environment usage"
    
    echo -e "\n${YELLOW}Development environments created:${NC}"
    podman images | grep "secure-.*-dev"
    
    echo -e "\n${CYAN}Project workspaces:${NC}"
    find projects/ -type f -name "*.py" | head -10
    
    # Cleanup option
    echo -e "\n${BLUE}🧹 Cleanup${NC}"
    read -p "Remove demo directory and development images? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd ..
        # Remove development images
        podman rmi secure-python-dev:latest secure-nodejs-dev:latest secure-go-dev:latest secure-polyglot-dev:latest --force 2>/dev/null || true
        # Remove directory
        rm -rf "$DEMO_DIR"
        echo "✅ Demo cleanup complete"
    else
        echo "Demo files kept in: $DEMO_DIR"
        echo "Remove images manually with: podman rmi secure-*-dev:latest --force"
        echo
        echo "To use the environments:"
        echo "  podman run -it --rm secure-python-dev:latest"
        echo "  podman run -it --rm secure-nodejs-dev:latest"
        echo "  podman run -it --rm secure-go-dev:latest"
        echo "  podman run -it --rm secure-polyglot-dev:latest"
    fi
}

# Check requirements
check_requirements() {
    echo -e "${BLUE}🔍 Checking requirements...${NC}"
    
    if ! command -v podman &> /dev/null; then
        echo -e "${RED}❌ Podman not found. Please install podman first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Requirements check passed${NC}"
}

# Run the demo
check_requirements
main "$@"