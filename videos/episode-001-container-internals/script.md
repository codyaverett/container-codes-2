# Episode 001: Container Internals Deep Dive

**Duration:** 18-20 minutes  
**Difficulty:** Intermediate  
**Technologies:** Linux namespaces, cgroups, container runtimes, Podman, strace

## Episode Overview

Ever wondered what actually happens when you run `podman run hello-world`? We're going beyond the surface to explore the fundamental Linux mechanisms that make containers possible. This episode traces every system call, examines kernel namespaces, and reveals how containers achieve isolation without virtualization.

## Prerequisites

- [ ] Linux system (or Linux VM) with root access
- [ ] Podman installed (`sudo dnf install podman` or equivalent)
- [ ] Basic understanding of Linux processes and file systems
- [ ] Familiarity with command line tools (ps, ls, mount)

## Episode Outline

### Introduction (0:00 - 2:00)
- Welcome to ContainerCodes
- Episode overview: "What happens when you run a container?"
- Why understanding internals matters for debugging and optimization
- Prerequisites check

### Section 1: The Container Runtime Journey (2:00 - 8:00)
- Live demonstration: tracing `podman run` with strace
- Breaking down the system calls
- OCI runtime handoff (Podman → crun/runc)
- Container lifecycle phases
- Process creation and namespace setup

### Section 2: Linux Namespaces in Action (8:00 - 14:00)
- Examining each namespace type with live demos
- PID namespace isolation demonstration
- Network namespace exploration
- Mount namespace and filesystem isolation
- User namespace security benefits
- UTS and IPC namespaces

### Section 3: Cgroups Resource Management (14:00 - 17:00)
- Cgroups v2 hierarchy exploration
- Memory, CPU, and I/O limits in action
- Monitoring resource usage
- Real-time resource control demonstration

### Wrap-up (17:00 - 20:00)
- Summary of key concepts: namespaces + cgroups = containers
- Common troubleshooting scenarios using this knowledge
- Next episode preview: Podman vs Docker security comparison
- Links to documentation and further reading

## Demo Commands

### Section 1: Runtime Tracing
```bash
# Trace system calls during container creation
sudo strace -f -e trace=clone,unshare,mount,chroot podman run --rm hello-world

# Examine the OCI runtime
podman info | grep -A5 "oci Runtime"

# Show container process lifecycle
podman run --rm -d nginx:alpine
podman ps
podman exec [container-id] ps aux
```

### Section 2: Namespace Exploration
```bash
# Create container and examine namespaces
container_id=$(podman run -d --name demo-container alpine sleep 300)
container_pid=$(podman inspect demo-container --format '{{.State.Pid}}')

# Show namespace differences
ls -la /proc/$container_pid/ns/
ls -la /proc/$$/ns/

# PID namespace demonstration
podman exec demo-container ps aux
ps aux | grep sleep

# Network namespace exploration
podman exec demo-container ip addr show
ip addr show

# Mount namespace examination
podman exec demo-container mount | head -10
mount | head -10
```

### Section 3: Cgroups Investigation
```bash
# Find container's cgroup path
systemd-cgls | grep demo-container

# Examine memory limits
cat /sys/fs/cgroup/system.slice/libpod-$container_id.scope/memory.max

# Monitor resource usage in real-time
podman stats demo-container

# Set resource limits and observe
podman run --rm --memory=100m --cpus=0.5 alpine stress --vm 1 --vm-bytes 150M --timeout 10s
```

## Key Takeaways

- [ ] Containers are Linux processes with enhanced isolation using namespaces and cgroups
- [ ] Podman delegates actual container creation to OCI-compliant runtimes (crun/runc)
- [ ] Six namespace types provide different aspects of isolation (PID, network, mount, user, UTS, IPC)
- [ ] Cgroups v2 provides hierarchical resource management and monitoring
- [ ] Understanding internals enables better debugging and optimization

## Resources and Links

- [Linux Namespaces Documentation](https://man7.org/linux/man-pages/man7/namespaces.7.html)
- [Cgroups v2 Documentation](https://docs.kernel.org/admin-guide/cgroup-v2.html)
- [OCI Runtime Specification](https://github.com/opencontainers/runtime-spec)
- [Podman Architecture](https://docs.podman.io/en/latest/markdown/podman-run.1.html)
- [Container Standards and Foundations](https://opencontainers.org/)

## Viewer Questions

### Common Questions
**Q:** Why use Podman instead of Docker for this demonstration?  
**A:** Podman's daemonless architecture makes it easier to trace system calls directly. Docker adds a daemon layer that complicates the tracing process.

**Q:** Do I need root privileges to create containers?  
**A:** With rootless containers (Podman's default), you don't need root for basic operations. However, examining some kernel interfaces requires elevated privileges.

**Q:** What's the performance impact of namespaces and cgroups?  
**A:** Minimal! Namespaces are kernel features with nearly zero overhead. Cgroups add small accounting overhead but enable precise resource control.

### Follow-up Topics
- Rootless container security deep dive (Episode 2)
- Container networking and CNI plugins
- Custom OCI runtime development
- Container filesystem layers and storage drivers

## Technical Notes

### Environment Setup
```bash
# Install required tools
sudo dnf install podman strace util-linux-core

# Enable podman socket (if needed for debugging)
systemctl --user start podman.socket

# Create demo directory
mkdir ~/container-internals-demo
cd ~/container-internals-demo

# Pre-pull images to avoid download delays
podman pull hello-world
podman pull alpine:latest
podman pull nginx:alpine
```

### Cleanup
```bash
# Stop and remove demo containers
podman stop --all
podman container prune -f

# Clean up images (optional)
podman image prune -f

# Remove demo directory
rm -rf ~/container-internals-demo
```

### Troubleshooting

**Issue: Permission denied when examining /proc/*/ns/**  
**Solution:** Use sudo or run as root user for kernel namespace inspection

**Issue: strace output too verbose**  
**Solution:** Use specific syscall filtering: `-e trace=clone,unshare,mount,pivot_root`

**Issue: Container exits immediately**  
**Solution:** Use `sleep` or interactive mode: `podman run -it alpine /bin/sh`

**Issue: Cgroup paths not found**  
**Solution:** Check if systemd is managing containers: `podman info | grep cgroup`

### Demo Script Testing
```bash
# Test all commands work as expected
./demo/test-commands.sh

# Verify cleanup is complete
./demo/verify-cleanup.sh

# Check resource usage during demos
./demo/monitor-resources.sh
```