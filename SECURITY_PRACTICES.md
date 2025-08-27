# ContainerCodes Security Best Practices

## Overview

This document outlines comprehensive security practices for container development, deployment, and management. These practices form the foundation of the ContainerCodes approach to container security and should be applied throughout the software development lifecycle.

## Core Security Principles

### 1. Defense in Depth
Never rely on a single security mechanism. Layer multiple security controls:
- Container isolation (namespaces, cgroups)
- Access controls (RBAC, user namespaces)
- Network security (network policies, firewalls)
- Runtime security (monitoring, anomaly detection)
- Image security (scanning, signing)

### 2. Principle of Least Privilege
Grant minimal permissions necessary for functionality:
- Drop all capabilities by default, add only what's needed
- Use non-root users inside containers
- Implement rootless container execution
- Apply restrictive seccomp and AppArmor profiles

### 3. Immutable Infrastructure
Treat containers as immutable and disposable:
- Never modify running containers
- Replace rather than patch containers
- Use read-only filesystems where possible
- Store state in external volumes or databases

### 4. Zero Trust Model
Never trust, always verify:
- Authenticate and authorize every request
- Encrypt all communications
- Monitor and audit all activities
- Assume breach and limit impact

## Container Image Security

### Base Image Selection
```bash
# ✅ Good: Use official, minimal base images
FROM python:3.11-alpine
FROM node:18-alpine
FROM golang:1.21-alpine

# ❌ Bad: Using outdated or unofficial images
FROM python:3.8
FROM someuser/custom-python
FROM ubuntu:18.04
```

### Image Hardening
```dockerfile
# Create non-root user
RUN adduser -D -s /bin/sh appuser

# Install only required packages
RUN apk add --no-cache \
    package1 \
    package2 \
    && rm -rf /var/cache/apk/*

# Use specific versions
RUN pip install --no-cache-dir \
    flask==2.3.3 \
    requests==2.31.0

# Switch to non-root user
USER appuser

# Use read-only filesystem
COPY --chown=appuser:appuser app.py /app/
```

### Vulnerability Scanning
```bash
# Scan images before deployment
trivy image myapp:latest
grype myapp:latest
snyk container test myapp:latest

# Integrate into CI/CD
if trivy image --severity HIGH,CRITICAL myapp:latest; then
    echo "Security scan passed"
else
    echo "Critical vulnerabilities found - blocking deployment"
    exit 1
fi
```

## Container Runtime Security

### Rootless Containers
```bash
# ✅ Preferred: Rootless execution
podman run --user 1000:1000 myapp

# ✅ Better: User namespace mapping
podman run --userns=keep-id myapp

# ❌ Avoid: Running as root
podman run --user root myapp
```

### Security Options
```bash
# Drop all capabilities, add only what's needed
podman run \
    --cap-drop ALL \
    --cap-add NET_BIND_SERVICE \
    --security-opt no-new-privileges \
    myapp

# Use read-only root filesystem
podman run \
    --read-only \
    --tmpfs /tmp:rw,noexec,nosuid \
    myapp

# Apply resource limits
podman run \
    --memory 512m \
    --cpus 1.0 \
    --pids-limit 100 \
    myapp
```

### Network Security
```bash
# Default: No network access
podman run --network none myapp

# Restricted: Custom network with policies
podman network create --driver bridge secure-net
podman run --network secure-net myapp

# Production: Use network policies in Kubernetes
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

## Development Environment Security

### Secure Development Containers
```bash
# Isolate untrusted code
podman run -it --rm \
    --security-opt no-new-privileges \
    --cap-drop ALL \
    --read-only \
    --tmpfs /workspace:rw,noexec,size=100m \
    --network none \
    --memory 256m \
    -v ./code:/code:ro \
    dev-environment
```

### Multi-Level Security
```bash
# High trust (internal code)
create_dev_env() {
    podman run -it \
        --memory 2g \
        --cpus 2.0 \
        --network bridge \
        -v ./trusted-project:/workspace \
        internal-dev-env
}

# Medium trust (experimental code)
create_experimental_env() {
    podman run -it \
        --memory 1g \
        --cpus 1.0 \
        --read-only \
        --tmpfs /tmp:rw,noexec,size=200m \
        --network bridge \
        -v ./experimental:/workspace:ro \
        experimental-dev-env
}

# Low trust (external code)
create_sandboxed_env() {
    podman run -it \
        --memory 256m \
        --cpus 0.5 \
        --read-only \
        --tmpfs /tmp:rw,noexec,size=50m \
        --network none \
        -v ./external:/code:ro \
        sandbox-env
}
```

## Supply Chain Security

### Dependency Management
```bash
# Pin exact versions
# requirements.txt
flask==2.3.3
requests==2.31.0
urllib3==2.0.4

# package.json
{
  "dependencies": {
    "express": "4.18.2",
    "axios": "1.4.0"
  }
}

# go.mod
require (
    github.com/gin-gonic/gin v1.9.1
    github.com/stretchr/testify v1.8.4
)
```

### Vulnerability Monitoring
```bash
# Automated dependency scanning
pip-audit  # Python
npm audit  # Node.js
go list -json -m all | nancy sleuth  # Go

# Container image scanning in CI/CD
name: Security Scan
on: [push, pull_request]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build image
        run: docker build -t myapp .
      - name: Scan image
        run: |
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy image --severity HIGH,CRITICAL myapp
```

### Software Bill of Materials (SBOM)
```bash
# Generate SBOM
syft packages dir:. -o spdx-json > sbom.json
cyclonedx-bom -o sbom-cyclonedx.json

# Verify SBOM against policies
opa eval -d policy.rego -i sbom.json "data.allow"
```

## Runtime Security Monitoring

### Behavioral Monitoring
```yaml
# Falco rule for suspicious container behavior
- rule: Unexpected Network Activity
  desc: Detect unexpected network connections from containers
  condition: >
    spawned_process and
    container and
    proc.name in (wget, curl, nc, nmap) and
    not proc.args contains "internal.company.com"
  output: >
    Suspicious network tool executed in container
    (user=%user.name command=%proc.cmdline container=%container.name)
  priority: WARNING
```

### Resource Monitoring
```bash
# Monitor container resource usage
podman stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Alert on resource anomalies
while true; do
    memory_usage=$(podman stats --no-stream --format "{{.MemPerc}}" myapp)
    if (( $(echo "$memory_usage > 80" | bc -l) )); then
        echo "ALERT: High memory usage: $memory_usage%"
        # Trigger incident response
    fi
    sleep 30
done
```

## Secrets Management

### Never Embed Secrets
```dockerfile
# ❌ Never do this
ENV API_KEY=secret123
COPY config_with_secrets.json /app/

# ✅ Use runtime secrets injection
# No secrets in image
COPY app.py /app/
```

### Secure Secrets Handling
```bash
# Use external secret management
podman run \
    --secret api-key,type=env,target=API_KEY \
    --secret db-password,type=env,target=DB_PASSWORD \
    myapp

# Kubernetes secrets
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  api-key: <base64-encoded-key>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: api-key
```

## Compliance and Governance

### Policy Enforcement
```yaml
# OPA Gatekeeper policy
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequirednonroot
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredNonRoot
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequirednonroot
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          container.securityContext.runAsUser == 0
          msg := "Containers must not run as root"
        }
```

### Audit Logging
```bash
# Enable comprehensive audit logging
podman run \
    --log-driver journald \
    --log-opt tag="myapp-{{.Name}}" \
    myapp

# Centralized log analysis
journalctl -u podman -o json | \
  jq -r 'select(.CONTAINER_TAG | test("myapp")) | 
         "\(.MESSAGE)"'
```

## Incident Response

### Container Forensics
```bash
# Capture container state for analysis
podman inspect suspicious_container > container_state.json
podman logs suspicious_container > container_logs.txt
podman exec suspicious_container ps aux > process_list.txt

# Export container filesystem for analysis
podman export suspicious_container > container_filesystem.tar

# Network analysis
podman exec suspicious_container netstat -tulpn > network_connections.txt
```

### Isolation and Containment
```bash
# Immediately isolate suspicious container
podman network disconnect --force bridge suspicious_container

# Capture memory dump (if supported)
podman exec suspicious_container cat /proc/*/maps > memory_maps.txt

# Create forensic snapshot
podman commit suspicious_container forensic_snapshot:$(date +%s)

# Safely terminate
podman stop suspicious_container
podman rm suspicious_container
```

## AI Code Security Practices

### Safe AI Code Testing
```bash
# Create isolated environment for AI-generated code
create_ai_test_env() {
    local code_file="$1"
    
    podman run -it --rm \
        --name ai-code-test \
        --security-opt no-new-privileges \
        --cap-drop ALL \
        --read-only \
        --tmpfs /workspace:rw,noexec,size=50m \
        --network none \
        --memory 128m \
        --cpus 0.25 \
        -v "$code_file:/code:ro" \
        python:3.11-alpine sh -c "
            cp /code /workspace/test.py
            cd /workspace
            echo 'Testing AI-generated code in isolation...'
            python test.py
            echo 'Test complete - no host access possible'
        "
}
```

### AI Code Review Checklist
- [ ] No hardcoded credentials or secrets
- [ ] No direct file system access outside working directory
- [ ] No network requests to external services
- [ ] No dynamic code execution (eval, exec)
- [ ] No subprocess calls without validation
- [ ] No access to environment variables
- [ ] Resource usage is bounded
- [ ] Error handling prevents information leakage

## Security Automation

### CI/CD Security Gates
```yaml
name: Security Pipeline
on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Static Code Analysis
        run: |
          bandit -r . -f json -o bandit-report.json
          semgrep --config=auto --json --output=semgrep-report.json .
      
      - name: Dependency Check
        run: |
          pip-audit --format=json --output=pip-audit.json
          safety check --json --output=safety-report.json
      
      - name: Build Container
        run: docker build -t test-image .
      
      - name: Container Security Scan
        run: |
          trivy image --format json --output trivy-report.json test-image
          
      - name: Security Gate
        run: |
          # Fail if critical vulnerabilities found
          if jq -e '.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")' trivy-report.json > /dev/null; then
            echo "Critical vulnerabilities found - blocking deployment"
            exit 1
          fi
          
          # Fail if high-risk patterns found
          if jq -e '.results[] | select(.check_id | contains("bandit.hardcoded_password"))' bandit-report.json > /dev/null; then
            echo "Security violations found - blocking deployment"
            exit 1
          fi
```

### Automated Response
```bash
# Automated threat response
monitor_and_respond() {
    while true; do
        # Check for suspicious activity
        if podman logs --since 1m myapp | grep -i "attack\|exploit\|malicious"; then
            echo "SECURITY ALERT: Suspicious activity detected"
            
            # Immediate response
            podman network disconnect bridge myapp
            podman pause myapp
            
            # Capture forensics
            podman logs myapp > /tmp/security-incident-$(date +%s).log
            
            # Notify security team
            curl -X POST -H 'Content-type: application/json' \
                --data '{"text":"Security incident detected in container myapp"}' \
                $SLACK_WEBHOOK_URL
        fi
        
        sleep 10
    done
}
```

## Continuous Improvement

### Security Metrics
Track and improve security posture:
- Time to patch vulnerabilities
- Number of security policy violations
- Mean time to detect security incidents
- Container security scan coverage
- Compliance audit success rate

### Regular Security Reviews
- Monthly vulnerability assessment
- Quarterly security architecture review
- Annual penetration testing
- Continuous security training for development teams

### Security Testing
```bash
# Chaos engineering for security
test_container_escape() {
    echo "Testing container escape attempts..."
    
    # Test 1: Privileged escalation
    if podman run --rm test-image whoami | grep -q root; then
        echo "FAIL: Container running as root"
    else
        echo "PASS: Container not running as root"
    fi
    
    # Test 2: Capability verification
    if podman run --rm test-image capsh --print | grep -q cap_sys_admin; then
        echo "FAIL: Dangerous capabilities present"
    else
        echo "PASS: Dangerous capabilities dropped"
    fi
    
    # Test 3: Network isolation
    if podman run --rm --network none test-image ping -c 1 8.8.8.8 2>/dev/null; then
        echo "FAIL: Network not properly isolated"
    else
        echo "PASS: Network properly isolated"
    fi
}
```

## Emergency Procedures

### Security Incident Response
1. **Immediate Containment**
   - Isolate affected containers
   - Preserve forensic evidence
   - Document all actions taken

2. **Assessment**
   - Determine scope of compromise
   - Identify attack vectors
   - Assess data exposure risk

3. **Eradication**
   - Remove malicious containers/images
   - Patch vulnerabilities
   - Update security controls

4. **Recovery**
   - Deploy clean containers
   - Restore from known-good backups
   - Implement additional monitoring

5. **Post-Incident**
   - Conduct root cause analysis
   - Update security procedures
   - Train team on lessons learned

### Contact Information
- Security Team: security@company.com
- Incident Response: ir@company.com
- Emergency Hotline: +1-555-SECURITY

---

*This document should be reviewed and updated regularly to reflect current threat landscape and best practices.*