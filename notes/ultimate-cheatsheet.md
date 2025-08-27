# Ultimate Container Tools Cheatsheet

## Quick Reference Card

### Essential Commands Comparison

| Task | Podman | Docker | Buildah | Skopeo |
|------|--------|--------|---------|--------|
| Run container | `podman run` | `docker run` | N/A | N/A |
| Build image | `podman build` | `docker build` | `buildah bud` | N/A |
| Pull image | `podman pull` | `docker pull` | `buildah from` | `skopeo copy` |
| Push image | `podman push` | `docker push` | `buildah push` | `skopeo copy` |
| List images | `podman images` | `docker images` | `buildah images` | N/A |
| Inspect image | `podman inspect` | `docker inspect` | `buildah inspect` | `skopeo inspect` |
| Remove image | `podman rmi` | `docker rmi` | `buildah rmi` | `skopeo delete` |

## PODMAN CHEATSHEET

### Container Operations
```bash
# Run
podman run -d --name web -p 8080:80 nginx
podman run -it --rm alpine /bin/sh
podman run -d --restart=always --name db postgres

# Manage
podman ps                    # List running
podman ps -a                 # List all
podman stop web              # Stop
podman start web             # Start
podman restart web           # Restart
podman rm web                # Remove
podman rm -f $(podman ps -aq)  # Remove all

# Execute & Attach
podman exec -it web /bin/bash
podman attach web
podman logs -f web           # Follow logs
podman top web               # Show processes
podman stats                 # Resource usage

# Checkpoint/Restore
podman checkpoint web
podman restore web
```

### Image Management
```bash
# Pull & Push
podman pull docker.io/nginx:latest
podman push myimage:latest registry.io/user/image:tag

# Build
podman build -t myapp:latest .
podman build -f Containerfile -t myapp:latest .

# List & Remove
podman images
podman rmi nginx:latest
podman rmi $(podman images -q)  # Remove all

# Tag & Save/Load
podman tag nginx:latest myregistry/nginx:v1
podman save -o nginx.tar nginx:latest
podman load -i nginx.tar
```

### Volumes & Networks
```bash
# Volumes
podman volume create myvol
podman volume ls
podman volume inspect myvol
podman volume rm myvol
podman run -v myvol:/data:Z nginx
podman run -v /host/path:/container/path:z nginx

# Networks
podman network create mynet
podman network ls
podman network inspect mynet
podman network rm mynet
podman run --network mynet nginx
```

### Pods (Kubernetes-like)
```bash
# Pod Management
podman pod create --name mypod -p 8080:80
podman pod start mypod
podman pod stop mypod
podman pod rm mypod
podman pod ps

# Add containers to pod
podman run -d --pod mypod nginx
podman run -d --pod mypod redis

# Generate/Play Kubernetes YAML
podman generate kube mypod > pod.yaml
podman play kube pod.yaml
```

### Rootless Operations
```bash
# Check mappings
podman unshare cat /proc/self/uid_map
podman info --format '{{.Host.IDMappings}}'

# System commands
podman system prune -a       # Clean everything
podman system df            # Disk usage
podman system reset         # Factory reset
```

### Systemd Integration
```bash
# Generate service
podman generate systemd --name web --files --new
systemctl --user daemon-reload
systemctl --user enable --now container-web.service

# Auto-update
podman run -d --name web --label io.containers.autoupdate=registry nginx
systemctl --user enable --now podman-auto-update.timer
```

## BUILDAH CHEATSHEET

### Container Creation
```bash
# From image
container=$(buildah from fedora:latest)
buildah from --name mycontainer alpine:latest

# From scratch
container=$(buildah from scratch)

# List & Remove
buildah containers
buildah rm $container
buildah rm --all
```

### Building Images
```bash
# From Dockerfile
buildah bud -t myapp:latest .
buildah bud -f Containerfile -t myapp:latest .
buildah bud --layers -t myapp:latest .         # With cache
buildah bud --squash -t myapp:latest .         # Squashed
buildah bud --no-cache -t myapp:latest .       # No cache

# Multi-platform
buildah bud --platform linux/amd64,linux/arm64 -t myapp:latest .

# With build args
buildah bud --build-arg VERSION=1.0 -t myapp:latest .
```

### Container Configuration
```bash
# Set config
buildah config --entrypoint '["nginx"]' $container
buildah config --cmd '["--help"]' $container
buildah config --workingdir /app $container
buildah config --user nginx:nginx $container
buildah config --env KEY=value $container
buildah config --port 80 $container
buildah config --volume /data $container
buildah config --label version=1.0 $container

# Add content
buildah copy $container /local/file /container/path
buildah add $container https://example.com/file /path

# Run commands
buildah run $container -- apt update
buildah run $container -- yum install nginx
```

### Filesystem Operations
```bash
# Mount/Unmount
mnt=$(buildah mount $container)
echo "content" > $mnt/file.txt
buildah unmount $container

# Commit
buildah commit $container myimage:latest
buildah commit --squash $container myimage:latest
buildah commit --format docker $container myimage:latest
```

### Advanced Building
```bash
#!/bin/bash
# Script-based build
container=$(buildah from alpine:latest)
buildah run $container -- apk add nginx
buildah copy $container nginx.conf /etc/nginx/
buildah config --port 80 $container
buildah config --cmd "nginx -g 'daemon off;'" $container
buildah commit $container mynginx:latest
buildah rm $container
```

## SKOPEO CHEATSHEET

### Inspection
```bash
# Inspect image
skopeo inspect docker://docker.io/nginx:latest
skopeo inspect --raw docker://nginx:latest      # Raw manifest
skopeo inspect --config docker://nginx:latest   # Config only
skopeo inspect --format "{{.Size}}" docker://nginx:latest

# List tags
skopeo list-tags docker://docker.io/library/nginx
```

### Copying Images
```bash
# Registry to registry
skopeo copy docker://source/image:tag docker://dest/image:tag

# To/from archive
skopeo copy docker://nginx:latest oci-archive:nginx.tar
skopeo copy oci-archive:nginx.tar docker://registry/nginx:latest

# To/from directory
skopeo copy docker://nginx:latest dir:/tmp/nginx
skopeo copy dir:/tmp/nginx docker://registry/nginx:latest

# Docker daemon integration
skopeo copy docker-daemon:myimage:latest docker://registry/image:tag

# With options
skopeo copy --all docker://source docker://dest  # All architectures
skopeo copy --format v2s2 oci:image docker://registry/image  # Format conversion
```

### Sync Operations
```bash
# Registry to registry
skopeo sync --src docker --dest docker source.io/repo dest.io

# To directory (backup)
skopeo sync --src docker --dest dir registry.io/namespace /backup

# From directory (restore)
skopeo sync --src dir --dest docker /backup registry.io
```

### Authentication
```bash
# Login
skopeo login registry.example.com
skopeo login --username user --password pass registry.io

# Use auth file
skopeo copy --authfile auth.json docker://private/image docker://dest/image

# Delete image
skopeo delete docker://registry.example.com/image:tag
```

## CONTAINER FUNDAMENTALS CHEATSHEET

### Namespaces
```bash
# Create namespaces
unshare --pid --fork --mount-proc /bin/bash    # PID namespace
unshare --net /bin/bash                         # Network namespace
unshare --mount /bin/bash                       # Mount namespace
unshare --uts /bin/bash                         # UTS namespace
unshare --ipc /bin/bash                         # IPC namespace
unshare --user --map-root-user /bin/bash        # User namespace

# View namespaces
ls -la /proc/$$/ns/
lsns                                             # List all namespaces
```

### Cgroups v2
```bash
# Create cgroup
mkdir /sys/fs/cgroup/myapp

# Set limits
echo "50000 100000" > /sys/fs/cgroup/myapp/cpu.max  # 50% CPU
echo "104857600" > /sys/fs/cgroup/myapp/memory.max  # 100MB RAM
echo "8:0 rbps=1048576" > /sys/fs/cgroup/myapp/io.max  # 1MB/s read

# Add process
echo $$ > /sys/fs/cgroup/myapp/cgroup.procs

# Monitor
cat /sys/fs/cgroup/myapp/memory.current
cat /sys/fs/cgroup/myapp/cpu.stat
```

### Network Setup
```bash
# Create veth pair
ip link add veth0 type veth peer name veth1

# Create network namespace
ip netns add container

# Move interface to namespace
ip link set veth1 netns container

# Configure
ip addr add 10.0.0.1/24 dev veth0
ip link set veth0 up
ip netns exec container ip addr add 10.0.0.2/24 dev veth1
ip netns exec container ip link set veth1 up

# Enable NAT
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -j MASQUERADE
```

### OverlayFS
```bash
# Setup overlay
mkdir lower upper work merged
mount -t overlay overlay \
  -o lowerdir=lower,upperdir=upper,workdir=work \
  merged

# Check mounts
findmnt -t overlay
```

## SECURITY CHEATSHEET

### Capabilities
```bash
# Common capabilities
--cap-drop=all                    # Drop all
--cap-add=NET_BIND_SERVICE       # Bind ports < 1024
--cap-add=SYS_TIME               # Set system time
--cap-add=SYS_ADMIN              # Various admin operations

# View capabilities
capsh --print                     # Current process
getpcaps $$                       # Specific process
```

### SELinux
```bash
# Container contexts
:z    # Shared label (multiple containers)
:Z    # Private label (single container)

# Commands
getenforce                        # Check status
setenforce 1                      # Enable
ls -Z /var/lib/containers/        # View labels
```

### Seccomp
```bash
# Use default profile
--security-opt seccomp=/path/to/profile.json

# Unconfined (dangerous!)
--security-opt seccomp=unconfined
```

### User Namespaces
```bash
# Check mappings
cat /etc/subuid
cat /etc/subgid

# Add mappings
echo "user:100000:65536" >> /etc/subuid
echo "user:100000:65536" >> /etc/subgid

# Run rootless
podman run --userns=keep-id alpine id
```

## RESOURCE LIMITS CHEATSHEET

### CPU
```bash
--cpus="1.5"                      # 1.5 CPUs
--cpu-shares=512                  # Relative weight (default 1024)
--cpu-quota=50000                 # Microseconds per period
--cpu-period=100000               # Period in microseconds
--cpuset-cpus="0,1"              # Specific CPU cores
```

### Memory
```bash
--memory=1g                       # Memory limit
--memory-swap=2g                  # Memory + swap limit
--memory-reservation=750m         # Soft limit
--kernel-memory=50m              # Kernel memory
--oom-kill-disable               # Disable OOM killer
```

### I/O
```bash
--blkio-weight=500               # Weight (10-1000)
--device-read-bps=/dev/sda:1mb   # Read rate
--device-write-bps=/dev/sda:500kb # Write rate
--device-read-iops=/dev/sda:100  # Read IOPS
--device-write-iops=/dev/sda:50  # Write IOPS
```

## TROUBLESHOOTING CHEATSHEET

### Debug Commands
```bash
# Inspect
podman inspect container_name
podman inspect --format '{{.State.Pid}}' container_name

# Logs
podman logs --tail=50 -f container_name
journalctl -u container-web.service

# Events
podman events --filter container=web
podman events --since 1h

# System
podman system df                 # Disk usage
podman system prune -a           # Cleanup
podman info                      # System info
```

### Debugging Tools
```bash
# Enter namespace
nsenter -t $(podman inspect -f '{{.State.Pid}}' container) -a

# Network debug container
podman run -it --network container:web nicolaka/netshoot

# Trace syscalls
strace -p $(podman inspect -f '{{.State.Pid}}' container)

# Process tree
pstree -p $(podman inspect -f '{{.State.Pid}}' container)
```

### Common Fixes
```bash
# Permission denied (rootless)
podman unshare chown -R $UID:$GID /path

# Storage issues
podman system reset              # Nuclear option
rm -rf ~/.local/share/containers # Rootless reset

# Network issues
podman network reload container_name
iptables -t nat -L              # Check NAT rules

# Can't remove image (used by container)
podman rm -f $(podman ps -aq)
podman rmi image_name
```

## QUICK RECIPES

### Multi-stage Build
```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Runtime stage
FROM alpine:latest
COPY --from=builder /app/myapp /usr/local/bin/
CMD ["myapp"]
```

### Rootless Setup
```bash
# One-time setup
sudo usermod --add-subuids 100000-165535 $USER
sudo usermod --add-subgids 100000-165535 $USER
podman system migrate
```

### Registry Mirror
```bash
# /etc/containers/registries.conf
[[registry]]
location = "docker.io"
[[registry.mirror]]
location = "mirror.example.com"
```

### Cleanup Script
```bash
#!/bin/bash
podman stop $(podman ps -q)
podman rm $(podman ps -aq)
podman rmi $(podman images -q)
podman volume prune -f
podman network prune -f
podman system prune -a -f
```

## ENVIRONMENT VARIABLES

### Common Variables
```bash
CONTAINER_HOST              # Remote podman socket
REGISTRY_AUTH_FILE         # Auth file location
STORAGE_DRIVER            # Storage driver override
BUILDAH_ISOLATION         # Isolation type
BUILDAH_FORMAT           # Image format
SKOPEO_TMPDIR           # Temp directory
```

### Runtime Variables
```bash
container_uuid           # Container UUID
HOSTNAME                # Container hostname
HOME                   # Home directory
PATH                  # Executable path
TERM                 # Terminal type
```

## USEFUL ALIASES

```bash
# Add to ~/.bashrc or ~/.zshrc
alias d='podman'
alias di='podman images'
alias dps='podman ps'
alias dpsa='podman ps -a'
alias dr='podman run --rm -it'
alias dx='podman exec -it'
alias dl='podman logs -f'
alias dstop='podman stop $(podman ps -q)'
alias dclean='podman system prune -a -f'

# Buildah aliases
alias b='buildah'
alias bfrom='buildah from'
alias brun='buildah run'
alias bcommit='buildah commit'

# Skopeo aliases  
alias si='skopeo inspect'
alias sc='skopeo copy'
alias ss='skopeo sync'
```