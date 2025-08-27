# Skopeo: Complete Guide for Container Image Operations

## What is Skopeo?

Skopeo (Greek for "remote viewing") is a command-line utility for performing various operations on container images and container registries without requiring a daemon or root privileges. It's designed to work with OCI-compliant images and various storage mechanisms.

## Key Characteristics

### 1. Daemonless Architecture
- **No daemon required**: Direct registry communication
- **Lightweight**: Minimal resource footprint
- **Standalone**: Works independently of container runtimes
- **Fast operations**: No overhead from daemon communication

### 2. Multi-Format Support
- **OCI images**: Native support for OCI specification
- **Docker images**: Full compatibility with Docker registries
- **Multiple transports**: Various storage and transport mechanisms
- **Format conversion**: Convert between image formats

### 3. Registry Operations
- **Direct transfers**: Registry-to-registry copying
- **Inspection**: View image metadata without downloading
- **Synchronization**: Efficient bulk image management
- **Authentication**: Support for various auth mechanisms

### 4. Air-Gapped Support
- **Offline operations**: Export/import for disconnected environments
- **Archive formats**: Support for tar archives
- **Directory storage**: OCI layout directory support

## Architecture

### Transport Mechanisms
```
Registry ←→ Skopeo ←→ Registry
   ↓          ↓          ↑
Archive    Directory   Docker Daemon
```

### Supported Transports
- `docker://` - Docker Registry API V2
- `oci:` - OCI layout directory
- `oci-archive:` - OCI layout tar archive
- `docker-archive:` - Docker save format
- `docker-daemon:` - Docker daemon storage
- `dir:` - Plain directory structure
- `containers-storage:` - Local container storage

## Installation

### Fedora/RHEL/CentOS
```bash
sudo dnf install skopeo
```

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install skopeo
```

### macOS
```bash
brew install skopeo
```

### From Source
```bash
git clone https://github.com/containers/skopeo.git
cd skopeo
make
sudo make install
```

## Core Commands Reference

### Image Inspection

```bash
# Inspect image on registry (without downloading)
skopeo inspect docker://docker.io/nginx:latest

# Get raw manifest
skopeo inspect --raw docker://docker.io/nginx:latest

# Get image configuration
skopeo inspect --config docker://docker.io/nginx:latest

# Format output
skopeo inspect --format "Size: {{.Size}}" docker://docker.io/nginx:latest

# Inspect with custom TLS
skopeo inspect --tls-verify=false docker://registry.example.com/myimage:latest
```

### Image Copying

```bash
# Copy between registries
skopeo copy docker://source.registry.com/image:tag docker://dest.registry.com/image:tag

# Copy to local directory (OCI layout)
skopeo copy docker://docker.io/nginx:latest oci:nginx-oci:latest

# Copy to tar archive
skopeo copy docker://docker.io/nginx:latest oci-archive:nginx.tar:latest

# Copy from Docker daemon
skopeo copy docker-daemon:myimage:latest docker://registry.example.com/myimage:latest

# Copy preserving digests
skopeo copy --preserve-digests docker://source/image:tag docker://dest/image:tag

# Copy all architectures
skopeo copy --all docker://source/image:tag docker://dest/image:tag
```

### Image Synchronization

```bash
# Sync entire repository
skopeo sync --src docker --dest docker source.registry.com/repo dest.registry.com

# Sync to directory for offline use
skopeo sync --src docker --dest dir registry.example.com/namespace /backup/images

# Sync from directory to registry
skopeo sync --src dir --dest docker /backup/images registry.example.com

# Sync with filtering
skopeo sync --src docker --dest docker \
  --src-username user --src-password pass \
  source.registry.com/namespace dest.registry.com
```

### Image Deletion

```bash
# Delete image from registry
skopeo delete docker://registry.example.com/myimage:tag

# Delete with custom auth
skopeo delete --creds username:password docker://registry.example.com/image:tag

# Delete with auth file
skopeo delete --authfile ~/auth.json docker://registry.example.com/image:tag
```

### Authentication

```bash
# Login to registry
skopeo login registry.example.com
Username: myuser
Password: 

# Login with credentials
skopeo login --username myuser --password mypass registry.example.com

# Login with auth file
skopeo login --authfile ~/auth.json registry.example.com

# Logout
skopeo logout registry.example.com

# Use auth for operations
skopeo copy --authfile ~/auth.json \
  docker://private.registry.com/image:tag \
  docker://dest.registry.com/image:tag
```

## Advanced Operations

### Multi-Architecture Images

```bash
# List all architectures
skopeo inspect --raw docker://docker.io/golang:latest | jq '.manifests'

# Copy specific architecture
skopeo copy --override-arch arm64 --override-os linux \
  docker://source/image:tag docker://dest/image:tag

# Copy all architectures
skopeo copy --all docker://source/image:tag docker://dest/image:tag

# Create multi-arch manifest list
skopeo copy --multi-arch all docker://source/image:tag docker://dest/image:tag
```

### Format Conversion

```bash
# Convert Docker to OCI format
skopeo copy --format oci \
  docker://docker.io/nginx:latest \
  oci:nginx-oci:latest

# Convert OCI to Docker format
skopeo copy --format v2s2 \
  oci:myimage:latest \
  docker://registry.example.com/myimage:latest

# Convert Docker archive to OCI
skopeo copy \
  docker-archive:image.tar \
  oci:image-oci:latest
```

### Working with Signatures

```bash
# Copy with signature verification
skopeo copy --src-creds user:pass \
  --policy policy.json \
  --sign-by key@example.com \
  docker://source/image:tag \
  docker://dest/image:tag

# Standalone signing
skopeo standalone-sign manifest.json docker://registry/image:tag key.gpg

# Verify signatures
skopeo standalone-verify manifest.json docker://registry/image:tag key.pub
```

## Practical Use Cases

### 1. Registry Migration

```bash
#!/bin/bash
# Migrate all images from one registry to another

SOURCE_REGISTRY="old.registry.com"
DEST_REGISTRY="new.registry.com"
NAMESPACE="myproject"

# Get all repositories
REPOS=$(skopeo list-tags docker://${SOURCE_REGISTRY}/${NAMESPACE})

for REPO in $REPOS; do
  skopeo sync --src docker --dest docker \
    ${SOURCE_REGISTRY}/${NAMESPACE}/${REPO} \
    ${DEST_REGISTRY}/${NAMESPACE}
done
```

### 2. Air-Gapped Deployment

```bash
# Step 1: Export images to archive (connected environment)
skopeo copy docker://docker.io/nginx:latest oci-archive:nginx.tar:latest
skopeo copy docker://docker.io/redis:latest oci-archive:redis.tar:latest

# Step 2: Transfer archives to air-gapped environment

# Step 3: Import to local registry (air-gapped environment)
skopeo copy oci-archive:nginx.tar:latest docker://local.registry/nginx:latest
skopeo copy oci-archive:redis.tar:latest docker://local.registry/redis:latest
```

### 3. CI/CD Integration

```yaml
# GitLab CI example
stages:
  - build
  - promote

build:
  stage: build
  script:
    - buildah bud -t ${CI_REGISTRY_IMAGE}:${CI_COMMIT_SHA} .
    - buildah push ${CI_REGISTRY_IMAGE}:${CI_COMMIT_SHA}

promote-to-prod:
  stage: promote
  only:
    - main
  script:
    - skopeo copy \
        docker://${CI_REGISTRY_IMAGE}:${CI_COMMIT_SHA} \
        docker://prod.registry.com/app:latest
```

### 4. Image Backup Script

```bash
#!/bin/bash
# Backup critical images to local directory

IMAGES=(
  "docker.io/nginx:latest"
  "docker.io/postgres:14"
  "docker.io/redis:7"
)

BACKUP_DIR="/backup/container-images/$(date +%Y%m%d)"
mkdir -p ${BACKUP_DIR}

for IMAGE in "${IMAGES[@]}"; do
  IMAGE_NAME=$(echo ${IMAGE} | tr '/:' '_')
  skopeo copy docker://${IMAGE} dir:${BACKUP_DIR}/${IMAGE_NAME}
  echo "Backed up ${IMAGE} to ${BACKUP_DIR}/${IMAGE_NAME}"
done
```

### 5. Registry Cleanup

```bash
#!/bin/bash
# Delete old image tags from registry

REGISTRY="registry.example.com"
REPO="myapp"
KEEP_LAST=5

# Get all tags sorted by date
TAGS=$(skopeo list-tags docker://${REGISTRY}/${REPO} | jq -r '.Tags[]' | sort -r)

# Keep only the last N tags
COUNT=0
for TAG in ${TAGS}; do
  COUNT=$((COUNT + 1))
  if [ ${COUNT} -gt ${KEEP_LAST} ]; then
    echo "Deleting ${REGISTRY}/${REPO}:${TAG}"
    skopeo delete docker://${REGISTRY}/${REPO}:${TAG}
  fi
done
```

## Working with Different Storage Types

### Docker Archive

```bash
# Create Docker archive
skopeo copy docker://nginx:latest docker-archive:nginx.tar:nginx:latest

# Load from Docker archive
skopeo copy docker-archive:nginx.tar:nginx:latest docker://registry/nginx:latest

# Inspect archive
skopeo inspect docker-archive:nginx.tar
```

### OCI Layout Directory

```bash
# Create OCI layout
skopeo copy docker://nginx:latest oci:nginx-oci:latest

# Structure
ls nginx-oci/
# blobs  index.json  oci-layout

# Copy from OCI layout
skopeo copy oci:nginx-oci:latest docker://registry/nginx:latest
```

### Directory Transport

```bash
# Copy to plain directory
skopeo copy docker://nginx:latest dir:nginx-dir

# Structure
ls nginx-dir/
# manifest.json  <layer-sha256-files>...

# Copy from directory
skopeo copy dir:nginx-dir docker://registry/nginx:latest
```

### Containers Storage

```bash
# Copy to containers-storage (Podman/Buildah)
skopeo copy docker://nginx:latest containers-storage:nginx:latest

# List images in containers-storage
podman images

# Copy from containers-storage
skopeo copy containers-storage:nginx:latest docker://registry/nginx:latest
```

## Performance Optimization

### Parallel Operations

```bash
# Sync with parallel downloads
skopeo sync --src docker --dest dir \
  --src-parallel-downloads 10 \
  registry.example.com/namespace /backup

# Multiple concurrent copies
for IMAGE in image1 image2 image3; do
  skopeo copy docker://source/${IMAGE} docker://dest/${IMAGE} &
done
wait
```

### Compression Options

```bash
# Copy with specific compression
skopeo copy --compress-format gzip \
  docker://source/image:tag \
  docker://dest/image:tag

# Copy with compression level
skopeo copy --compress-level 9 \
  docker://source/image:tag \
  docker://dest/image:tag
```

### Bandwidth Management

```bash
# Limit download rate
skopeo copy --src-daemon-host http://slow-registry.com \
  docker://slow-registry.com/image:tag \
  docker://fast-registry.com/image:tag
```

## Security Best Practices

### 1. TLS Verification

```bash
# Always verify TLS in production
skopeo copy --dest-tls-verify=true \
  docker://source/image:tag \
  docker://dest/image:tag

# Use custom CA certificate
skopeo copy --dest-cert-dir=/path/to/certs \
  docker://source/image:tag \
  docker://dest/image:tag
```

### 2. Credential Management

```bash
# Use auth files instead of inline credentials
skopeo login --authfile ~/auth.json registry.example.com

# Use environment variables
export REGISTRY_AUTH_FILE=~/auth.json
skopeo copy docker://private/image docker://dest/image
```

### 3. Image Verification

```bash
# Verify image signatures
skopeo copy --src-creds user:pass \
  --policy policy.json \
  docker://signed/image:tag \
  docker://dest/image:tag
```

### 4. Minimal Permissions

```bash
# Run as non-root user
useradd -m skopeo-user
su - skopeo-user
skopeo copy docker://public/image oci:local-image
```

## Troubleshooting

### Common Issues

```bash
# Debug mode
skopeo --debug copy docker://source/image docker://dest/image

# Verbose output
skopeo --verbose inspect docker://registry/image

# Override timeout
skopeo --command-timeout 60s copy docker://slow/image docker://dest/image

# Retry on failure
skopeo --retry-times 3 copy docker://flaky/image docker://dest/image
```

### Registry-Specific Issues

```bash
# Docker Hub rate limiting
skopeo copy --src-creds dockerhub-user:token \
  docker://docker.io/image \
  docker://private/image

# Private registry with self-signed cert
skopeo copy --src-tls-verify=false \
  docker://private.registry/image \
  docker://dest/image

# ECR authentication
aws ecr get-login-password | skopeo login --username AWS --password-stdin \
  123456789.dkr.ecr.region.amazonaws.com
```

## Integration Examples

### Kubernetes CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: image-sync
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: skopeo
            image: quay.io/skopeo/stable:latest
            command:
            - skopeo
            - sync
            - --src=docker
            - --dest=docker
            - source.registry/namespace
            - dest.registry/namespace
          restartPolicy: OnFailure
```

### Ansible Playbook

```yaml
- name: Sync container images
  hosts: localhost
  tasks:
    - name: Copy image to local registry
      shell: |
        skopeo copy \
          docker://docker.io/{{ item }} \
          docker://local.registry/{{ item }}
      loop:
        - nginx:latest
        - redis:latest
        - postgres:14
```

## Comparison with Other Tools

| Feature | Skopeo | Docker | Podman | Crane |
|---------|---------|---------|---------|--------|
| Daemonless | ✓ | ✗ | ✓ | ✓ |
| Registry inspection | ✓ | Limited | ✗ | ✓ |
| Format conversion | ✓ | ✗ | ✗ | Limited |
| Direct registry copy | ✓ | ✗ | ✗ | ✓ |
| Multi-arch support | ✓ | ✓ | ✓ | ✓ |
| Air-gap support | ✓ | ✓ | ✓ | ✓ |

## Best Practices Summary

1. **Always verify TLS** in production environments
2. **Use auth files** instead of inline credentials
3. **Implement retry logic** for network operations
4. **Regular sync** for disaster recovery
5. **Monitor registry space** when copying large images
6. **Use compression** for slow networks
7. **Verify signatures** for secure supply chain

## Latest Features (2025)

- Enhanced OCI 1.1 specification support
- Improved performance for large image transfers
- Better integration with cloud provider registries
- Native support for WASM/WASI images
- Enhanced multi-architecture manifest handling

## Resources

- [Official GitHub Repository](https://github.com/containers/skopeo)
- [Man Page](https://github.com/containers/skopeo/blob/main/docs/skopeo.1.md)
- [Red Hat Documentation](https://www.redhat.com/en/topics/containers/what-is-skopeo)
- [Container Tools Ecosystem](https://github.com/containers)