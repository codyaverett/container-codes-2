# Podman: Complete Guide and Reference

## What is Podman?

Podman (Pod Manager) is a daemonless, open-source container engine for developing, managing, and running containers on Linux systems. It's designed as a drop-in replacement for Docker with enhanced security through rootless operation.

## Key Characteristics

### 1. Daemonless Architecture
- **No central daemon**: Each container runs as a child process
- **Direct kernel interaction**: Uses fork/exec model
- **Benefits**:
  - No single point of failure
  - Reduced attack surface
  - Up to 50% faster container startup (2025 benchmarks)
  - No daemon restart required for updates

### 2. Rootless Containers
- **User namespace isolation**: Containers run without root privileges
- **Security by default**: Regular users can run containers safely
- **UID/GID mapping**: Automatic user namespace creation via `/etc/subuid` and `/etc/subgid`
- **Storage location**: `$HOME/.local/share/containers/storage` (rootless mode)

### 3. Docker Compatibility
- **CLI compatibility**: Same commands as Docker (`podman run` = `docker run`)
- **Dockerfile support**: Build containers using existing Dockerfiles
- **Docker Hub integration**: Pull images from any OCI-compliant registry
- **Compose support**: Works with docker-compose files via podman-compose

## Architecture Deep Dive

### Process Model
```
User → podman CLI → conmon (container monitor) → OCI runtime (runc/crun) → Container
```

### Storage Layers
- **Graph Driver**: overlay, vfs, btrfs, zfs
- **Image Store**: Layered filesystem for image storage
- **Container Store**: Read-write layers for running containers

### Networking (Rootless)
- **pasta** (default since v5.0): Performance-optimized network stack
- **slirp4netns** (legacy): User-mode networking
- **Port forwarding**: Automatic iptables rules for exposed ports

## Installation

### Fedora/RHEL/CentOS
```bash
sudo dnf install podman
```

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install podman
```

### macOS
```bash
brew install podman
podman machine init
podman machine start
```

### Windows (WSL2)
```bash
# Inside WSL2
sudo apt-get install podman
```

## Essential Commands Cheatsheet

### Container Management
```bash
# Run a container
podman run -d --name webserver -p 8080:80 nginx:latest

# Run interactively
podman run -it --rm alpine:latest /bin/sh

# List containers
podman ps        # Running only
podman ps -a     # All containers

# Stop/Start/Restart
podman stop container_name
podman start container_name
podman restart container_name

# Remove container
podman rm container_name
podman rm -f container_name  # Force remove running

# Execute command in running container
podman exec -it container_name /bin/bash

# View logs
podman logs container_name
podman logs -f container_name  # Follow logs

# Inspect container
podman inspect container_name
```

### Image Management
```bash
# Pull image
podman pull docker.io/library/nginx:latest

# List images
podman images

# Remove image
podman rmi image_name

# Build image
podman build -t myapp:latest .

# Tag image
podman tag source_image:tag target_image:tag

# Push image
podman push myimage:latest registry.example.com/myimage:latest

# Save/Load images
podman save -o backup.tar nginx:latest
podman load -i backup.tar
```

### Volume Management
```bash
# Create volume
podman volume create myvolume

# List volumes
podman volume ls

# Inspect volume
podman volume inspect myvolume

# Remove volume
podman volume rm myvolume

# Use volume in container
podman run -v myvolume:/data:Z nginx:latest
```

### Network Management
```bash
# List networks
podman network ls

# Create network
podman network create mynetwork

# Connect container to network
podman network connect mynetwork container_name

# Disconnect from network
podman network disconnect mynetwork container_name

# Remove network
podman network rm mynetwork
```

## Pod Management (Kubernetes-like)

```bash
# Create pod
podman pod create --name mypod -p 8080:80

# Add container to pod
podman run -d --pod mypod nginx:latest

# List pods
podman pod ps

# Stop/Start pod
podman pod stop mypod
podman pod start mypod

# Remove pod (and all containers)
podman pod rm -f mypod

# Generate Kubernetes YAML
podman generate kube mypod > pod.yaml

# Play Kubernetes YAML
podman play kube pod.yaml
```

## Rootless Configuration

### Setup User Namespaces
```bash
# Check current mappings
cat /etc/subuid
cat /etc/subgid

# Add user mappings (as root)
echo "username:100000:65536" >> /etc/subuid
echo "username:100000:65536" >> /etc/subgid

# Enable lingering (systemd user services)
loginctl enable-linger username
```

### Configuration Files
```bash
# User config location
~/.config/containers/

# Important files
~/.config/containers/storage.conf     # Storage configuration
~/.config/containers/containers.conf  # Runtime settings
~/.config/containers/registries.conf  # Registry configuration
```

## Systemd Integration

### Generate systemd service
```bash
# Create container
podman run -d --name myapp nginx:latest

# Generate service file
podman generate systemd --name myapp --files --new

# Install as user service
mkdir -p ~/.config/systemd/user/
cp container-myapp.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now container-myapp.service
```

### Auto-update containers
```bash
# Label container for auto-updates
podman run -d --name myapp \
  --label io.containers.autoupdate=registry \
  nginx:latest

# Enable auto-update timer
systemctl --user enable --now podman-auto-update.timer
```

## Security Features

### SELinux Integration
```bash
# Volume with SELinux context
podman run -v /host/path:/container/path:Z nginx  # Private label
podman run -v /host/path:/container/path:z nginx  # Shared label
```

### Capabilities Management
```bash
# Drop all capabilities and add specific ones
podman run --cap-drop=all --cap-add=NET_BIND_SERVICE nginx

# Run with no new privileges
podman run --security-opt=no-new-privileges nginx
```

### User Namespace Mapping
```bash
# Run with specific UID/GID mapping
podman run --uidmap=0:100000:5000 --gidmap=0:100000:5000 nginx

# Keep UID (rootless)
podman run --userns=keep-id alpine id
```

## Advanced Features

### Checkpoint/Restore (CRIU)
```bash
# Checkpoint running container
podman container checkpoint myapp

# Restore container
podman container restore myapp

# Migrate container
podman container checkpoint myapp --export=/tmp/checkpoint.tar.gz
podman container restore --import=/tmp/checkpoint.tar.gz
```

### Healthchecks
```bash
# Run with healthcheck
podman run -d --name healthy \
  --health-cmd='curl -f http://localhost || exit 1' \
  --health-interval=30s \
  --health-retries=3 \
  --health-start-period=60s \
  nginx
```

### Secrets Management
```bash
# Create secret
echo "mypassword" | podman secret create mysecret -

# Use secret in container
podman run --secret mysecret alpine cat /run/secrets/mysecret
```

## Performance Tuning

### Resource Limits
```bash
# CPU limits
podman run --cpus="1.5" --cpu-shares=512 nginx

# Memory limits
podman run -m 512m --memory-swap 1g nginx

# I/O limits
podman run --device-read-bps /dev/sda:1mb nginx
```

### Storage Options
```bash
# Use tmpfs for temporary data
podman run --mount type=tmpfs,destination=/tmp nginx

# Override storage driver
podman --storage-driver overlay run nginx
```

## Troubleshooting

### Common Issues and Solutions

```bash
# Permission denied errors (rootless)
podman unshare cat /proc/self/uid_map  # Check UID mappings

# Network issues
podman network reload container_name   # Reload network config

# Storage issues
podman system prune -a                  # Clean up everything
podman system df                        # Check disk usage

# Reset storage (rootless)
podman system reset

# Debug mode
podman --log-level=debug run nginx

# Events monitoring
podman events --filter container=myapp
```

## Best Practices

### 1. Image Security
- Always use specific tags, not `latest`
- Scan images regularly: `podman image scan`
- Use minimal base images (alpine, distroless)

### 2. Resource Management
- Set resource limits for all containers
- Use health checks for critical services
- Implement proper logging strategies

### 3. Networking
- Use custom networks instead of default
- Implement network policies for pod communication
- Use secrets for sensitive data

### 4. Storage
- Use volumes for persistent data
- Regular cleanup: `podman system prune`
- Monitor disk usage: `podman system df`

## Podman vs Docker Comparison

| Feature | Podman | Docker |
|---------|--------|--------|
| Architecture | Daemonless | Daemon-based |
| Root requirement | No (rootless) | Yes (daemon runs as root) |
| Systemd integration | Native | Limited |
| Kubernetes compatibility | Pod concept built-in | Requires additional tools |
| Security | User namespaces by default | Optional |
| Resource overhead | Lower | Higher (daemon overhead) |
| Auto-updates | Built-in with systemd | Requires Watchtower |

## Migration from Docker

### Command Alias
```bash
# Add to ~/.bashrc or ~/.zshrc
alias docker='podman'
```

### Docker-compose compatibility
```bash
# Install podman-compose
pip3 install podman-compose

# Use like docker-compose
podman-compose up -d
```

### Socket compatibility
```bash
# Enable podman socket for Docker API compatibility
systemctl --user enable --now podman.socket

# Set Docker host
export DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock
```

## Future Roadmap (2025)

- Enhanced WASM container support
- Improved GPU passthrough
- Native confidential container support
- Advanced multi-architecture builds
- Enhanced Kubernetes YAML compatibility

## Additional Resources

- [Official Documentation](https://docs.podman.io/)
- [GitHub Repository](https://github.com/containers/podman)
- [Red Hat Developer Portal](https://developers.redhat.com/topics/containers)
- [Podman Desktop](https://podman-desktop.io/)