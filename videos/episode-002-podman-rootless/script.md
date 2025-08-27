# Episode 002: Podman vs Docker: Security Revolution

**Duration:** 18-22 minutes  
**Difficulty:** Intermediate  
**Technologies:** Podman, Docker, User namespaces, Rootless containers, SELinux

## Episode Overview

Dive deep into the security implications of rootless containers and why Podman's
architecture represents a fundamental shift in container security. We'll explore
real-world attack scenarios, demonstrate privilege escalation differences, and
show why enterprises are adopting rootless-first strategies.

## Prerequisites

- [ ] Episode 1: Container Internals knowledge (namespaces, cgroups)
- [ ] Basic understanding of Linux user permissions and sudo
- [ ] Podman and Docker installed (Docker for comparison only)
- [ ] Linux system with user namespaces enabled

## Episode Outline

### Introduction (0:00 - 2:30)

- Welcome back to ContainerCodes
- Episode overview: The container security revolution
- Why rootless matters in 2025 (enterprise adoption stats)
- What we'll demonstrate today

### Section 1: The Docker Daemon Problem (2:30 - 7:00)

- Docker daemon architecture and security implications
- Demonstration: Docker daemon privilege escalation
- Real-world Docker security incidents
- Why "Docker group = root" is dangerous

### Section 2: Podman's Rootless Architecture (7:00 - 13:00)

- Daemonless architecture benefits
- User namespace mapping demonstration
- Rootless container filesystem isolation
- Network namespace handling without privileges
- SELinux integration and MCS labels

### Section 3: Security Comparison Live Demo (13:00 - 18:00)

- Side-by-side privilege escalation attempts
- Container breakout scenarios
- File system access differences
- Process visibility comparison
- Resource exhaustion protection

### Section 4: Production Considerations (18:00 - 21:00)

- When to choose Podman vs Docker
- Migration strategies from Docker to Podman
- Enterprise security compliance benefits
- Performance implications of rootless

### Wrap-up (21:00 - 22:00)

- Key security takeaways
- Preview: Episode 3 - Building without Docker (Buildah)
- Community challenge: Security audit your containers

## Demo Commands

### Section 1: Docker Daemon Risks

```bash
# Show docker daemon running as root
ps aux | grep dockerd
sudo ls -la /var/run/docker.sock

# Demonstrate privilege escalation via Docker
docker run -it --rm -v /:/host alpine chroot /host
# Now you have root access to the host!

# Show docker group membership implications
groups
docker run --rm -v /etc/shadow:/shadow alpine cat /shadow
```

### Section 2: Podman Rootless Security

```bash
# Show no daemon running
ps aux | grep podman  # Should show nothing

# User namespace mapping
podman unshare cat /proc/self/uid_map
podman unshare cat /proc/self/gid_map

# Rootless container demonstration
podman run -it --rm alpine id
# Shows root inside container, but mapped to user outside

# Try the same privilege escalation attack
podman run -it --rm -v /:/host alpine chroot /host
# This should fail or provide limited access
```

### Section 3: Security Comparison

```bash
# Container breakout attempts
# Docker (dangerous)
docker run --privileged --pid=host -it alpine nsenter -t 1 -m -u -n -i sh

# Podman (safer)
podman run --privileged --pid=host -it alpine nsenter -t 1 -m -u -n -i sh
# Limited by user namespace

# File system access comparison
# Docker
docker run -v /etc/passwd:/passwd alpine cat /passwd

# Podman
podman run -v /etc/passwd:/passwd alpine cat /passwd
# May be blocked or show mapped content

# Process visibility
docker run --pid=host alpine ps aux | head -10
podman run --pid=host alpine ps aux | head -10
```

## Key Takeaways

- [ ] Docker daemon runs as root, creating a large attack surface
- [ ] Podman's daemonless architecture eliminates daemon-based attacks
- [ ] User namespaces map container root to unprivileged host user
- [ ] Rootless containers provide defense-in-depth security
- [ ] Enterprise adoption of rootless is accelerating for compliance reasons
- [ ] Migration from Docker to Podman is straightforward for most workloads

## Resources and Links

- [Rootless Containers Security](https://rootlesscontaine.rs/)
- [CVE Database - Docker Vulnerabilities](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=docker)
- [Podman Security Guide](https://docs.podman.io/en/latest/markdown/podman-run.1.html#security-options)
- [User Namespaces Documentation](https://man7.org/linux/man-pages/man7/user_namespaces.7.html)
- [NIST Container Security Guide](https://csrc.nist.gov/publications/detail/sp/800-190/final)

## Viewer Questions

### Common Questions

**Q:** Can I run rootless containers in production?  
**A:** Absolutely! Many enterprises are moving to rootless-first strategies. Red
Hat OpenShift, for example, runs all workloads as rootless by default.

**Q:** What are the limitations of rootless containers?  
**A:** Main limitations include: no privileged ports (<1024), some volume mounts
restrictions, and certain debugging tools may not work the same way.

**Q:** How do I migrate from Docker to Podman?  
**A:** Podman is designed to be a drop-in replacement. Most docker commands work
with `alias docker=podman`. We'll show migration strategies in detail.

### Follow-up Topics

- Container image security scanning
- Kubernetes security policies
- Runtime security monitoring
- Supply chain security

## Technical Notes

### Environment Setup

```bash
# Ensure user namespaces are enabled
echo 1 | sudo tee /proc/sys/user/max_user_namespaces

# Install both Docker and Podman for comparison
# Fedora/RHEL
sudo dnf install podman docker

# Ubuntu
sudo apt install podman.io docker.io

# Start Docker service (for comparison only)
sudo systemctl start docker
sudo usermod -aG docker $USER
# Log out and back in for group changes

# Verify Podman rootless setup
podman system info | grep -i rootless
```

### Security Test Cases

```bash
# Test 1: Privilege escalation via volume mount
echo "Testing Docker privilege escalation..."
docker run --rm -v /etc/shadow:/shadow alpine cat /shadow > docker-shadow.txt 2>&1

echo "Testing Podman privilege escalation..."
podman run --rm -v /etc/shadow:/shadow alpine cat /shadow > podman-shadow.txt 2>&1

# Compare results
echo "Docker result:"
head -1 docker-shadow.txt
echo "Podman result:"
head -1 podman-shadow.txt

# Test 2: Process visibility
echo "Docker host process visibility:"
docker run --pid=host --rm alpine ps aux | wc -l

echo "Podman host process visibility:"
podman run --pid=host --rm alpine ps aux | wc -l

# Test 3: Network namespace escape attempts
echo "Testing network namespace isolation..."
# Implementation depends on specific test scenarios
```

### Cleanup

```bash
# Remove test containers
docker container prune -f
podman container prune -f

# Remove test files
rm -f docker-shadow.txt podman-shadow.txt

# Stop Docker service (optional)
sudo systemctl stop docker
```

### Troubleshooting

**Issue: User namespaces not available**  
**Solution:** Enable with `echo 1 | sudo tee /proc/sys/user/max_user_namespaces`

**Issue: Podman can't access volumes**  
**Solution:** Use `:Z` flag for SELinux contexts:
`podman run -v /host/path:/container/path:Z`

**Issue: Docker permission denied**  
**Solution:** Add user to docker group: `sudo usermod -aG docker $USER` (but
understand the security implications!)

### Production Migration Checklist

```bash
# 1. Test current Docker commands with Podman
alias docker=podman

# 2. Update CI/CD pipelines
# Replace 'docker build' with 'podman build'
# Replace 'docker run' with 'podman run'

# 3. Update volume mounts for SELinux
# Add :Z flag where needed

# 4. Test networking (rootless uses different network stack)

# 5. Update monitoring (no daemon to monitor)

# 6. Security scan with new tooling
podman run --rm -v /var/lib/containers:/var/lib/containers:ro \
    quay.io/projectquay/clair:latest clairscan
```
