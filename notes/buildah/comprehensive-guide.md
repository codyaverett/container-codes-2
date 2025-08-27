# Buildah: Complete Guide for OCI Image Building

## What is Buildah?

Buildah is a command-line tool that facilitates building Open Container Initiative (OCI) compliant container images. It allows you to build images from Dockerfiles, from scratch, or using shell commands - all without requiring a Docker daemon or root privileges.

## Key Characteristics

### 1. Daemonless Operation
- **No daemon required**: Direct kernel interaction
- **Security advantage**: Eliminates daemon socket security risks
- **Resource efficiency**: No background process consuming resources
- **CI/CD friendly**: Perfect for ephemeral build environments

### 2. Multiple Build Methods
- **Dockerfile/Containerfile**: Traditional declarative builds
- **From scratch**: Minimal images with only required components
- **Shell commands**: Interactive, imperative builds
- **Script-based**: Bash scripts for complex build logic

### 3. OCI Compliance
- **Standards-based**: Follows OCI Image Specification
- **Universal compatibility**: Works with any OCI-compliant registry
- **Format flexibility**: Can output Docker or OCI format images

### 4. Rootless Builds
- **User namespaces**: Build without root privileges
- **Enhanced security**: No elevated permissions required
- **Shared systems**: Safe for multi-user environments
- **CI/CD integration**: Works in restricted environments

## Architecture

### Build Process Flow
```
User → buildah CLI → Container Storage → Image Layers → OCI Image
                    ↓
                 Build Context
                    ↓
              Temporary Container
```

### Storage Backend
- Uses same storage as Podman and CRI-O
- Root: `/var/lib/containers/storage`
- Rootless: `$HOME/.local/share/containers/storage`

## Installation

### Fedora/RHEL/CentOS
```bash
sudo dnf install buildah
```

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install buildah
```

### macOS
```bash
brew install buildah
```

### From Source
```bash
git clone https://github.com/containers/buildah.git
cd buildah
make
sudo make install
```

## Core Commands Reference

### Container Management

```bash
# Create new container from image
buildah from fedora:latest
# Returns: fedora-working-container

# Create from scratch (empty container)
buildah from scratch
# Returns: working-container

# List containers
buildah containers

# Remove container
buildah rm container-name

# Remove all containers
buildah rm -all
```

### Image Building

```bash
# Build from Dockerfile
buildah bud -t myapp:latest .

# Build with specific file
buildah bud -f Containerfile -t myapp:latest .

# Build for multiple platforms
buildah bud --platform linux/amd64,linux/arm64 -t myapp:latest .

# Build with build args
buildah bud --build-arg VERSION=1.0 -t myapp:latest .

# Build without cache
buildah bud --no-cache -t myapp:latest .
```

### Working with Containers

```bash
# Mount container filesystem
buildah mount container-name
# Returns: /var/lib/containers/storage/overlay/.../merged

# Unmount container
buildah umount container-name

# Run command in container
buildah run container-name -- ls -la /

# Copy files into container
buildah copy container-name /local/file /container/path

# Add content from URL
buildah add container-name https://example.com/file /dest/path
```

### Configuration

```bash
# Set working directory
buildah config --workingdir /app container-name

# Set environment variables
buildah config --env KEY=value container-name

# Set entrypoint
buildah config --entrypoint '["nginx", "-g", "daemon off;"]' container-name

# Set command
buildah config --cmd '/bin/bash' container-name

# Set user
buildah config --user nginx:nginx container-name

# Add port
buildah config --port 8080 container-name

# Add volume
buildah config --volume /data container-name

# Add label
buildah config --label version=1.0 container-name
```

### Committing Images

```bash
# Commit container to image
buildah commit container-name myimage:latest

# Commit with options
buildah commit --squash container-name myimage:latest

# Commit with format
buildah commit --format docker container-name myimage:latest

# Commit with compression
buildah commit --disable-compression=false container-name myimage:latest
```

## Build Methods Deep Dive

### Method 1: Using Dockerfiles

```dockerfile
# Dockerfile example
FROM alpine:latest
RUN apk add --no-cache nginx
COPY nginx.conf /etc/nginx/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

```bash
# Build from Dockerfile
buildah bud -t mynginx:latest .

# Build with Docker format (for Docker compatibility)
buildah bud --format docker -t mynginx:latest .
```

### Method 2: From Scratch

```bash
# Create empty container
container=$(buildah from scratch)

# Mount container filesystem
mountpoint=$(buildah mount $container)

# Install minimal system
dnf install --installroot $mountpoint --releasever 39 \
  --setopt install_weak_deps=false -y \
  coreutils bash

# Unmount
buildah umount $container

# Configure container
buildah config --cmd /bin/bash $container

# Commit image
buildah commit $container minimal-fedora:latest
```

### Method 3: Shell Script Builds

```bash
#!/bin/bash
# build-script.sh

# Start from base image
container=$(buildah from alpine:latest)

# Install packages
buildah run $container -- apk add --no-cache \
  python3 \
  py3-pip \
  gcc \
  musl-dev

# Copy application
buildah copy $container ./app /app

# Install Python dependencies
buildah run $container -- pip3 install -r /app/requirements.txt

# Configure runtime
buildah config --workingdir /app $container
buildah config --port 5000 $container
buildah config --entrypoint '["python3"]' $container
buildah config --cmd '["app.py"]' $container

# Commit image
buildah commit --squash $container myapp:latest

# Cleanup
buildah rm $container
```

### Method 4: Interactive Building

```bash
# Start with base
container=$(buildah from ubuntu:latest)

# Mount for direct filesystem access
mnt=$(buildah mount $container)

# Direct filesystem manipulation
echo "Hello from Buildah" > $mnt/hello.txt
mkdir -p $mnt/app
cp -r ./source/* $mnt/app/

# Install software using host tools
dnf install --installroot $mnt -y nginx

# Unmount when done
buildah umount $container

# Commit
buildah commit $container custom-ubuntu:latest
```

## Advanced Features

### Multi-Stage Builds

```dockerfile
# Multi-stage Dockerfile
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=builder /app/myapp /usr/local/bin/
CMD ["myapp"]
```

```bash
buildah bud -t myapp:latest .
```

### Cross-Platform Builds

```bash
# Build for multiple architectures
buildah bud \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --manifest myapp:latest \
  .

# Push multi-arch manifest
buildah manifest push --all myapp:latest docker://registry.example.com/myapp:latest
```

### Using Build Volumes

```bash
# Mount volume during build
buildah bud \
  --volume /host/cache:/cache:ro \
  -t myapp:latest \
  .
```

### Secrets Management

```bash
# Create secret
echo "mysecret" > mysecret.txt

# Use secret in build
buildah bud \
  --secret id=mysecret,src=mysecret.txt \
  -t myapp:latest \
  .
```

In Dockerfile:
```dockerfile
RUN --mount=type=secret,id=mysecret \
  cat /run/secrets/mysecret
```

## Image Management

### Push to Registry

```bash
# Push to Docker Hub
buildah push myimage:latest docker://docker.io/username/myimage:latest

# Push to private registry
buildah push myimage:latest docker://registry.example.com/myimage:latest

# Push to local directory
buildah push myimage:latest dir:/path/to/directory

# Push as OCI layout
buildah push myimage:latest oci:/path/to/oci:latest
```

### Pull Images

```bash
# Pull from registry
buildah pull docker://docker.io/library/nginx:latest

# Pull from private registry
buildah pull docker://registry.example.com/myimage:latest
```

### Image Inspection

```bash
# Inspect image
buildah inspect myimage:latest

# Inspect specific field
buildah inspect --format '{{.OCIv1.Config.Env}}' myimage:latest

# List images
buildah images
```

## Rootless Configuration

### Setup

```bash
# Check subuid/subgid mappings
cat /etc/subuid
cat /etc/subgid

# Configure storage for rootless
mkdir -p ~/.config/containers
cat > ~/.config/containers/storage.conf <<EOF
[storage]
driver = "overlay"
[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF
```

### Rootless Build Example

```bash
# As non-root user
buildah bud -t myapp:latest .

# Check images in user storage
buildah images

# Push to registry (requires auth)
buildah login registry.example.com
buildah push myapp:latest docker://registry.example.com/myapp:latest
```

## Integration with CI/CD

### GitLab CI Example

```yaml
build-image:
  stage: build
  image: quay.io/buildah/stable:latest
  script:
    - buildah bud --format docker -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - buildah push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  only:
    - main
```

### GitHub Actions Example

```yaml
name: Build Container
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build Image
        run: |
          buildah bud -t myapp:latest .
          buildah push myapp:latest docker://ghcr.io/${{ github.repository }}:latest
```

### Jenkins Pipeline Example

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'buildah bud -t myapp:${BUILD_NUMBER} .'
                sh 'buildah push myapp:${BUILD_NUMBER} docker://registry.example.com/myapp:${BUILD_NUMBER}'
            }
        }
    }
}
```

## Performance Optimization

### Layer Caching

```bash
# Use cache from previous builds
buildah bud --layers -t myapp:latest .

# Specify cache location
buildah bud --layers --cache-from registry.example.com/myapp:cache -t myapp:latest .
```

### Squashing Layers

```bash
# Squash all layers into one
buildah bud --squash -t myapp:latest .

# Squash when committing
buildah commit --squash container-name myimage:latest
```

### Parallel Builds

```bash
# Build multiple images in parallel
buildah bud -t app1:latest ./app1 &
buildah bud -t app2:latest ./app2 &
buildah bud -t app3:latest ./app3 &
wait
```

## Troubleshooting

### Common Issues

```bash
# Permission denied in rootless mode
# Solution: Check subuid/subgid mappings
buildah unshare cat /proc/self/uid_map

# Storage issues
# Solution: Clean up storage
buildah rm --all
buildah rmi --all
buildah prune

# Network issues during build
# Solution: Use host network
buildah bud --network host -t myapp:latest .

# Debug build process
buildah bud --log-level debug -t myapp:latest .
```

### Debugging Builds

```bash
# Keep intermediate containers for debugging
buildah bud --rm=false -t myapp:latest .

# Interactive debugging
container=$(buildah from alpine:latest)
buildah run $container -- /bin/sh
# Debug interactively...
buildah rm $container
```

## Security Best Practices

### 1. Minimal Images
```bash
# Start from scratch when possible
container=$(buildah from scratch)
# Add only necessary components
```

### 2. Non-Root Users
```bash
buildah config --user 1001:1001 container-name
```

### 3. Read-Only Filesystem
```bash
buildah config --label io.containers.readonly=true container-name
```

### 4. Security Scanning
```bash
# Scan built image
buildah push myimage:latest oci:/tmp/myimage
trivy image --input /tmp/myimage
```

## Buildah vs Docker Build Comparison

| Feature | Buildah | Docker Build |
|---------|---------|--------------|
| Daemon requirement | No | Yes |
| Root requirement | No (rootless) | Yes (daemon) |
| Build methods | Multiple | Dockerfile only |
| Direct filesystem access | Yes | No |
| Scripting capability | Excellent | Limited |
| OCI native | Yes | Converted |
| Security | Superior | Standard |
| CI/CD integration | Excellent | Good |

## Practical Examples

### Example 1: Minimal Web Server

```bash
#!/bin/bash
# Build minimal nginx container

container=$(buildah from scratch)
mnt=$(buildah mount $container)

# Install minimal nginx
dnf install --installroot $mnt --releasever 39 \
  --setopt install_weak_deps=false -y \
  nginx

# Clean up
dnf clean all --installroot $mnt
rm -rf $mnt/var/cache

# Configure
buildah config --port 80 $container
buildah config --cmd "nginx -g 'daemon off;'" $container

# Commit
buildah umount $container
buildah commit $container minimal-nginx:latest
```

### Example 2: Python Application

```bash
#!/bin/bash
# Build Python app container

container=$(buildah from python:3.11-slim)

# Copy application
buildah copy $container ./app /app

# Install dependencies
buildah run $container -- pip install --no-cache-dir -r /app/requirements.txt

# Configure
buildah config --workingdir /app $container
buildah config --env PYTHONUNBUFFERED=1 $container
buildah config --cmd "python main.py" $container

# Commit
buildah commit --squash $container python-app:latest
```

## Latest Features (2025)

- **v1.41.0** (July 2025): Enhanced multi-platform support
- **v1.40.0** (April 2025): Improved caching mechanisms
- **v1.39.0** (February 2025): Better secrets handling
- **WASM support**: Experimental WebAssembly container builds
- **Improved performance**: Faster layer caching and parallel processing

## Resources

- [Official Documentation](https://github.com/containers/buildah/tree/main/docs)
- [Buildah.io](https://buildah.io/)
- [Tutorial](https://github.com/containers/buildah/tree/main/docs/tutorials)
- [Examples](https://github.com/containers/buildah/tree/main/examples)