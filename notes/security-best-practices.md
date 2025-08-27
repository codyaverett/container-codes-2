# Container Security Best Practices: Comprehensive Guide

## Security Principles Overview

### Defense in Depth
Implement multiple layers of security controls throughout the container lifecycle:
1. **Build-time security** - Secure base images, vulnerability scanning
2. **Runtime security** - Process isolation, resource limits
3. **Network security** - Segmentation, encryption
4. **Host security** - Kernel hardening, SELinux/AppArmor
5. **Supply chain security** - Image signing, attestations

## 1. Image Security

### Use Minimal Base Images

```dockerfile
# BAD - Full OS with unnecessary packages
FROM ubuntu:latest
RUN apt-get update && apt-get install -y python3

# GOOD - Minimal base
FROM python:3.11-alpine

# BETTER - Distroless
FROM gcr.io/distroless/python3

# BEST - Scratch for static binaries
FROM scratch
COPY myapp /myapp
ENTRYPOINT ["/myapp"]
```

### Multi-Stage Builds

```dockerfile
# Build stage with all tools
FROM golang:1.21 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Minimal runtime stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
USER nobody:nobody
CMD ["./main"]
```

### Image Scanning

```bash
# Scan with Trivy
trivy image myapp:latest

# Scan with Grype
grype myapp:latest

# Scan with Clair
clairctl analyze myapp:latest

# Podman built-in scanning
podman image scan myapp:latest
```

### Image Signing

```bash
# Generate keys
cosign generate-key-pair

# Sign image
cosign sign --key cosign.key registry.example.com/myapp:latest

# Verify signature
cosign verify --key cosign.pub registry.example.com/myapp:latest

# Sign with Skopeo
skopeo copy --sign-by mykey@example.com \
  docker://unsigned/image:tag \
  docker://registry/signed/image:tag
```

### Dockerfile Best Practices

```dockerfile
# Set non-root user
FROM alpine:latest
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

# Copy with proper ownership
COPY --chown=appuser:appgroup app /app

# Drop privileges
USER appuser

# Use COPY instead of ADD
COPY app.tar.gz /tmp/
RUN tar -xzf /tmp/app.tar.gz -C /app

# Pin package versions
RUN apk add --no-cache \
    nginx=1.24.0-r1 \
    openssl=3.1.4-r0

# Clear package manager cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/* # Debian/Ubuntu
RUN apk --no-cache add packages # Alpine
RUN yum clean all # RHEL/CentOS

# Use secrets safely
RUN --mount=type=secret,id=mysecret \
    cat /run/secrets/mysecret | some-command

# Health checks
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost/health || exit 1
```

## 2. Runtime Security

### Run as Non-Root User

```bash
# Podman (rootless by default)
podman run --user 1000:1000 myapp

# With username
podman run --user nobody:nogroup myapp

# In Dockerfile
USER 1000:1000
```

### Capability Management

```bash
# Drop all capabilities and add only required
podman run \
    --cap-drop=all \
    --cap-add=NET_BIND_SERVICE \
    myapp

# Common minimal capabilities
CAP_CHOWN           # Change file ownership
CAP_DAC_OVERRIDE    # Override file permissions
CAP_FOWNER          # Bypass permission checks
CAP_FSETID          # Set file capabilities
CAP_KILL            # Send signals
CAP_NET_BIND_SERVICE # Bind to ports < 1024
CAP_SETFCAP         # Set file capabilities
CAP_SETGID          # Manipulate process GIDs
CAP_SETUID          # Manipulate process UIDs
```

### Read-Only Root Filesystem

```bash
# Read-only root with writable /tmp
podman run \
    --read-only \
    --tmpfs /tmp:noexec,nosuid,nodev,size=100m \
    myapp

# In compose
services:
  app:
    image: myapp
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100M
```

### Security Options

```bash
# No new privileges
podman run --security-opt=no-new-privileges myapp

# AppArmor profile
podman run --security-opt apparmor=docker-default myapp

# SELinux context
podman run --security-opt label=type:container_runtime_t myapp

# Seccomp profile
podman run --security-opt seccomp=/path/to/profile.json myapp
```

## 3. Resource Limits

### Memory Limits

```bash
# Set memory limit
podman run -m 512m myapp

# Memory + swap limit
podman run -m 512m --memory-swap 1g myapp

# Memory reservation (soft limit)
podman run --memory-reservation 256m myapp

# OOM killer configuration
podman run --oom-kill-disable=false --oom-score-adj=500 myapp
```

### CPU Limits

```bash
# CPU quota (50% of one CPU)
podman run --cpus="0.5" myapp

# CPU shares (relative weight)
podman run --cpu-shares=512 myapp

# Pin to specific CPUs
podman run --cpuset-cpus="0,1" myapp
```

### Process Limits

```bash
# Limit number of processes
podman run --pids-limit=100 myapp

# Ulimits
podman run \
    --ulimit nofile=1024:2048 \
    --ulimit nproc=512:1024 \
    myapp
```

## 4. Network Security

### Network Isolation

```bash
# No network access
podman run --network=none myapp

# Custom network
podman network create --internal secure-net
podman run --network=secure-net myapp

# Network policies (Kubernetes)
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

### Port Management

```bash
# Bind to localhost only
podman run -p 127.0.0.1:8080:80 myapp

# Specific interface
podman run -p 10.0.0.1:8080:80 myapp

# Avoid exposing unnecessary ports
# BAD
EXPOSE 22 80 443 3306 5432

# GOOD
EXPOSE 8080
```

## 5. Secrets Management

### Using Podman Secrets

```bash
# Create secret
echo "mypassword" | podman secret create db-password -

# Use in container
podman run \
    --secret db-password \
    -e DB_PASSWORD_FILE=/run/secrets/db-password \
    myapp

# In application
password=$(cat /run/secrets/db-password)
```

### BuildKit Secrets

```dockerfile
# Dockerfile
FROM alpine
RUN --mount=type=secret,id=aws,target=/root/.aws/credentials \
    aws s3 cp s3://bucket/file /tmp/file
```

```bash
# Build with secret
DOCKER_BUILDKIT=1 podman build \
    --secret id=aws,src=$HOME/.aws/credentials \
    -t myapp .
```

### Environment Variables Best Practices

```bash
# BAD - Secrets in environment
podman run -e PASSWORD=secret123 myapp

# GOOD - Use secret files
podman run --secret password myapp

# BETTER - Use secret management system
podman run \
    -e VAULT_ADDR=https://vault.example.com \
    -e VAULT_TOKEN_FILE=/run/secrets/vault-token \
    myapp
```

## 6. Filesystem Security

### Volume Security

```bash
# SELinux labels
podman run -v /host/path:/container/path:Z myapp  # Private label
podman run -v /host/path:/container/path:z myapp  # Shared label

# Read-only volumes
podman run -v /host/path:/container/path:ro myapp

# noexec mount
podman run --mount type=bind,source=/host,target=/container,noexec myapp
```

### Temporary Filesystems

```bash
# Secure tmpfs
podman run \
    --mount type=tmpfs,destination=/tmp,tmpfs-size=100M,tmpfs-mode=1770 \
    myapp

# Multiple tmpfs mounts
podman run \
    --tmpfs /tmp:noexec,nosuid,nodev,size=100m \
    --tmpfs /run:noexec,nosuid,nodev,size=50m \
    myapp
```

## 7. Logging and Monitoring

### Secure Logging

```bash
# Log to syslog
podman run --log-driver=syslog \
    --log-opt syslog-address=tcp://logserver:514 \
    --log-opt tag="{{.Name}}" \
    myapp

# JSON file with rotation
podman run --log-driver=json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    myapp

# Avoid sensitive data in logs
# Application code
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# BAD
logger.info(f"User {username} logged in with password {password}")

# GOOD
logger.info(f"User {username} logged in")
```

### Security Monitoring

```bash
# Monitor container events
podman events --filter container=myapp

# Runtime security with Falco
sudo falco -r /etc/falco/falco_rules.yaml

# Audit container activity
auditctl -w /var/lib/containers -p war -k container-changes
```

## 8. Host Security

### Kernel Hardening

```bash
# Sysctl settings
cat > /etc/sysctl.d/99-container-security.conf << EOF
# Network hardening
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1

# File system protection
fs.protected_hardlinks = 1
fs.protected_symlinks = 1

# Process protection
kernel.yama.ptrace_scope = 1
kernel.dmesg_restrict = 1
EOF

sysctl -p /etc/sysctl.d/99-container-security.conf
```

### SELinux/AppArmor

#### SELinux Configuration
```bash
# Enable SELinux
setenforce 1

# Container context
podman run --security-opt label=type:container_runtime_t myapp

# Custom SELinux policy
cat > container_app.te << EOF
policy_module(container_app, 1.0.0)

type container_app_t;
type container_app_exec_t;

allow container_app_t self:capability { net_bind_service };
allow container_app_t container_app_exec_t:file execute;
EOF

checkmodule -M -m -o container_app.mod container_app.te
semodule_package -o container_app.pp -m container_app.mod
semodule -i container_app.pp
```

#### AppArmor Profile
```bash
# Create profile
cat > /etc/apparmor.d/container.myapp << 'EOF'
#include <tunables/global>

profile container-myapp flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>
  
  deny @{PROC}/* w,
  deny mount,
  deny /sys/[^f]*/** wklx,
  deny /sys/f[^s]*/** wklx,
  
  /usr/sbin/nginx ix,
  /var/log/nginx/* w,
  /run/nginx.pid w,
}
EOF

# Load profile
apparmor_parser -r /etc/apparmor.d/container.myapp

# Use profile
podman run --security-opt apparmor=container-myapp myapp
```

## 9. Supply Chain Security

### SBOM (Software Bill of Materials)

```bash
# Generate SBOM with Syft
syft myapp:latest -o spdx-json > sbom.json

# Scan SBOM
grype sbom:sbom.json

# Include in image
COPY sbom.json /usr/share/doc/sbom.json
```

### Attestations

```bash
# Create attestation
cosign attest --key cosign.key \
    --type spdx \
    --predicate sbom.json \
    registry.example.com/myapp:latest

# Verify attestation
cosign verify-attestation --key cosign.pub \
    --type spdx \
    registry.example.com/myapp:latest
```

## 10. CI/CD Security

### Secure Build Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - build
  - scan
  - sign
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  script:
    - buildah bud --layers -t ${CI_REGISTRY_IMAGE}:${CI_COMMIT_SHA} .
    - buildah push ${CI_REGISTRY_IMAGE}:${CI_COMMIT_SHA}

scan:
  stage: scan
  script:
    - trivy image --exit-code 1 --severity HIGH,CRITICAL \
        ${CI_REGISTRY_IMAGE}:${CI_COMMIT_SHA}

sign:
  stage: sign
  script:
    - cosign sign --key ${COSIGN_KEY} \
        ${CI_REGISTRY_IMAGE}:${CI_COMMIT_SHA}

deploy:
  stage: deploy
  script:
    - cosign verify --key ${COSIGN_PUB_KEY} \
        ${CI_REGISTRY_IMAGE}:${CI_COMMIT_SHA}
    - kubectl set image deployment/app \
        app=${CI_REGISTRY_IMAGE}:${CI_COMMIT_SHA}
```

## 11. Compliance and Policies

### OPA (Open Policy Agent) Policies

```rego
# policy.rego
package docker.security

deny[msg] {
    input[i].Cmd == "run"
    input[i].User == "root"
    msg := "Containers must not run as root"
}

deny[msg] {
    input[i].Cmd == "run"
    not input[i].SecurityOpt
    msg := "Security options must be specified"
}

deny[msg] {
    input[i].Cmd == "from"
    not contains(input[i].Value, ":")
    msg := "Images must specify a tag"
}
```

### Pod Security Standards (Kubernetes)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

## 12. Security Scanning Tools

### Comprehensive Security Stack

```bash
# Image scanning
trivy image myapp:latest
grype myapp:latest
snyk container test myapp:latest

# Runtime protection
falco -r /etc/falco/rules.yaml

# Compliance scanning
docker-bench-security
kube-bench

# Network scanning
nmap -sV -p- container-host
```

## Security Checklist

### Build Phase
- [ ] Use minimal base images
- [ ] Implement multi-stage builds
- [ ] Pin package versions
- [ ] Scan images for vulnerabilities
- [ ] Sign container images
- [ ] Generate and include SBOM
- [ ] Remove unnecessary packages
- [ ] Clear package manager caches

### Runtime Phase
- [ ] Run as non-root user
- [ ] Drop unnecessary capabilities
- [ ] Use read-only root filesystem
- [ ] Set resource limits
- [ ] Enable security options (no-new-privileges)
- [ ] Use SELinux/AppArmor profiles
- [ ] Implement network policies
- [ ] Use secrets management

### Infrastructure
- [ ] Keep host OS updated
- [ ] Enable kernel security features
- [ ] Implement audit logging
- [ ] Use container-specific OS (CoreOS, Flatcar)
- [ ] Regular security updates
- [ ] Implement RBAC
- [ ] Enable encryption at rest
- [ ] Use private registries

## Incident Response

### Container Forensics

```bash
# Capture container state
podman inspect compromised-container > container-state.json
podman diff compromised-container > filesystem-changes.txt

# Export container filesystem
podman export compromised-container > container-export.tar

# Collect logs
podman logs compromised-container > container-logs.txt

# Memory dump (if supported)
podman checkpoint compromised-container --leave-running \
    --export=/tmp/checkpoint.tar.gz
```

### Containment and Recovery

```bash
# Isolate container
podman pause compromised-container

# Disconnect from network
podman network disconnect bridge compromised-container

# Create forensic copy
podman commit compromised-container forensic-copy:incident-001

# Stop and remove
podman stop compromised-container
podman rm compromised-container
```

## Resources and References

- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Container Security Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf)
- [OWASP Container Security Top 10](https://owasp.org/www-project-docker-top-10/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Falco Rules](https://falco.org/docs/rules/)
- [Container Security Book](https://www.oreilly.com/library/view/container-security/9781492056690/)