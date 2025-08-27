# OCI (Open Container Initiative) Standards: Complete Guide

## What is OCI?

The Open Container Initiative (OCI) is an open governance structure for creating industry standards around container formats and runtimes. Launched in June 2015 by Docker and other industry leaders, OCI ensures container portability and interoperability across different platforms and tools.

## OCI Specifications Overview

### Three Core Specifications

1. **Runtime Specification (runtime-spec)** - Defines how to run a container
2. **Image Specification (image-spec)** - Defines how to package containers
3. **Distribution Specification (distribution-spec)** - Defines how to distribute containers

## OCI Runtime Specification

### Purpose
Defines the configuration, execution environment, and lifecycle of a container.

### Key Components

#### 1. Filesystem Bundle
A directory structure containing:
```
bundle/
├── config.json         # Container configuration
└── rootfs/            # Root filesystem
    ├── bin/
    ├── dev/
    ├── etc/
    ├── home/
    ├── lib/
    ├── proc/
    ├── sys/
    ├── tmp/
    └── usr/
```

#### 2. Runtime Configuration (config.json)

```json
{
  "ociVersion": "1.0.2",
  "process": {
    "terminal": false,
    "user": {
      "uid": 0,
      "gid": 0,
      "additionalGids": [1, 2]
    },
    "args": [
      "/bin/sh",
      "-c",
      "echo 'Hello from OCI container'"
    ],
    "env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
      "TERM=xterm"
    ],
    "cwd": "/",
    "capabilities": {
      "bounding": ["CAP_AUDIT_WRITE", "CAP_KILL", "CAP_NET_BIND_SERVICE"],
      "effective": ["CAP_AUDIT_WRITE", "CAP_KILL"],
      "inheritable": ["CAP_AUDIT_WRITE", "CAP_KILL"],
      "permitted": ["CAP_AUDIT_WRITE", "CAP_KILL"],
      "ambient": ["CAP_NET_BIND_SERVICE"]
    },
    "rlimits": [
      {
        "type": "RLIMIT_NOFILE",
        "hard": 1024,
        "soft": 1024
      }
    ],
    "noNewPrivileges": true
  },
  "root": {
    "path": "rootfs",
    "readonly": false
  },
  "hostname": "container-host",
  "mounts": [
    {
      "destination": "/proc",
      "type": "proc",
      "source": "proc",
      "options": ["nosuid", "noexec", "nodev"]
    },
    {
      "destination": "/dev",
      "type": "tmpfs",
      "source": "tmpfs",
      "options": ["nosuid", "strictatime", "mode=755", "size=65536k"]
    },
    {
      "destination": "/dev/pts",
      "type": "devpts",
      "source": "devpts",
      "options": ["nosuid", "noexec", "newinstance", "ptmxmode=0666", "mode=0620", "gid=5"]
    },
    {
      "destination": "/dev/shm",
      "type": "tmpfs",
      "source": "shm",
      "options": ["nosuid", "noexec", "nodev", "mode=1777", "size=65536k"]
    },
    {
      "destination": "/dev/mqueue",
      "type": "mqueue",
      "source": "mqueue",
      "options": ["nosuid", "noexec", "nodev"]
    },
    {
      "destination": "/sys",
      "type": "sysfs",
      "source": "sysfs",
      "options": ["nosuid", "noexec", "nodev", "ro"]
    }
  ],
  "linux": {
    "namespaces": [
      {"type": "pid"},
      {"type": "network"},
      {"type": "ipc"},
      {"type": "uts"},
      {"type": "mount"},
      {"type": "user"},
      {"type": "cgroup"}
    ],
    "uidMappings": [
      {
        "containerID": 0,
        "hostID": 1000,
        "size": 32000
      }
    ],
    "gidMappings": [
      {
        "containerID": 0,
        "hostID": 1000,
        "size": 32000
      }
    ],
    "devices": [
      {
        "path": "/dev/null",
        "type": "c",
        "major": 1,
        "minor": 3,
        "fileMode": 666,
        "uid": 0,
        "gid": 0
      }
    ],
    "cgroupsPath": "/my-container",
    "resources": {
      "memory": {
        "limit": 536870912,
        "reservation": 268435456,
        "swap": 536870912,
        "kernel": 0,
        "kernelTCP": 0,
        "swappiness": 0,
        "disableOOMKiller": false
      },
      "cpu": {
        "shares": 1024,
        "quota": 1000000,
        "period": 500000,
        "realtimeRuntime": 0,
        "realtimePeriod": 0,
        "cpus": "0-1",
        "mems": "0-1"
      },
      "pids": {
        "limit": 32
      },
      "blockIO": {
        "weight": 10,
        "leafWeight": 10,
        "weightDevice": [
          {
            "major": 8,
            "minor": 0,
            "weight": 500,
            "leafWeight": 300
          }
        ],
        "throttleReadBpsDevice": [
          {
            "major": 8,
            "minor": 0,
            "rate": 600
          }
        ]
      },
      "network": {
        "classID": 1048577,
        "priorities": [
          {
            "name": "eth0",
            "priority": 500
          }
        ]
      }
    },
    "seccomp": {
      "defaultAction": "SCMP_ACT_ERRNO",
      "architectures": [
        "SCMP_ARCH_X86_64",
        "SCMP_ARCH_X86",
        "SCMP_ARCH_X32"
      ],
      "syscalls": [
        {
          "names": [
            "accept",
            "accept4",
            "access",
            "alarm",
            "bind",
            "brk"
          ],
          "action": "SCMP_ACT_ALLOW"
        }
      ]
    },
    "rootfsPropagation": "rprivate",
    "maskedPaths": [
      "/proc/kcore",
      "/proc/latency_stats",
      "/proc/timer_list",
      "/proc/timer_stats",
      "/proc/sched_debug"
    ],
    "readonlyPaths": [
      "/proc/asound",
      "/proc/bus",
      "/proc/fs",
      "/proc/irq",
      "/proc/sys",
      "/proc/sysrq-trigger"
    ]
  },
  "hooks": {
    "prestart": [
      {
        "path": "/usr/bin/setup-network"
      }
    ],
    "poststart": [
      {
        "path": "/usr/bin/notify-start"
      }
    ],
    "poststop": [
      {
        "path": "/usr/bin/cleanup"
      }
    ]
  }
}
```

### Container Lifecycle

#### States
1. **Creating** - Container is being created
2. **Created** - Container created but not started
3. **Running** - Container is running
4. **Stopped** - Container has been stopped

#### Operations
```bash
# Create container
runc create <container-id>

# Start container
runc start <container-id>

# Kill container
runc kill <container-id> <signal>

# Delete container
runc delete <container-id>

# State query
runc state <container-id>
```

## OCI Image Specification

### Image Layout

#### Directory Structure
```
image/
├── blobs/
│   └── sha256/
│       ├── 4a7f3d...       # Config blob
│       ├── 8b3f5e...       # Layer blob
│       ├── 9c4d2a...       # Layer blob
│       └── 2e5f8a...       # Manifest blob
├── index.json              # Image index
└── oci-layout              # Layout version file
```

#### oci-layout
```json
{
  "imageLayoutVersion": "1.0.0"
}
```

#### index.json (Image Index)
```json
{
  "schemaVersion": 2,
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.manifest.v1+json",
      "digest": "sha256:2e5f8a...",
      "size": 7023,
      "platform": {
        "architecture": "amd64",
        "os": "linux",
        "os.version": "",
        "os.features": [],
        "variant": ""
      },
      "annotations": {
        "org.opencontainers.image.ref.name": "latest"
      }
    },
    {
      "mediaType": "application/vnd.oci.image.manifest.v1+json",
      "digest": "sha256:3f6d9b...",
      "size": 7023,
      "platform": {
        "architecture": "arm64",
        "os": "linux",
        "variant": "v8"
      }
    }
  ],
  "annotations": {
    "org.opencontainers.image.created": "2024-01-15T10:20:30Z"
  }
}
```

### Image Manifest
```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "digest": "sha256:4a7f3d...",
    "size": 7023
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "digest": "sha256:8b3f5e...",
      "size": 32654
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "digest": "sha256:9c4d2a...",
      "size": 16724
    },
    {
      "mediaType": "application/vnd.oci.image.layer.nondistributable.v1.tar+gzip",
      "digest": "sha256:5f8d3c...",
      "size": 73109
    }
  ],
  "annotations": {
    "org.opencontainers.image.title": "My Application",
    "org.opencontainers.image.version": "1.0.0"
  }
}
```

### Image Configuration
```json
{
  "created": "2024-01-15T10:20:30Z",
  "author": "developer@example.com",
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "User": "1000:1000",
    "ExposedPorts": {
      "8080/tcp": {}
    },
    "Env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
      "APP_VERSION=1.0.0"
    ],
    "Entrypoint": ["/app/start.sh"],
    "Cmd": ["--config", "/etc/app/config.json"],
    "Volumes": {
      "/data": {}
    },
    "WorkingDir": "/app",
    "Labels": {
      "version": "1.0.0",
      "description": "My application",
      "maintainer": "developer@example.com"
    },
    "StopSignal": "SIGTERM",
    "HealthCheck": {
      "Test": ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
      "Interval": 30000000000,
      "Timeout": 3000000000,
      "Retries": 3,
      "StartPeriod": 60000000000
    }
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:c6f988f...",
      "sha256:5f70bf..."
    ]
  },
  "history": [
    {
      "created": "2024-01-15T10:15:00Z",
      "created_by": "/bin/sh -c #(nop) ADD file:... in /",
      "empty_layer": false
    },
    {
      "created": "2024-01-15T10:20:00Z",
      "created_by": "/bin/sh -c apt-get update && apt-get install -y nginx",
      "empty_layer": false
    }
  ]
}
```

### Media Types

#### Descriptors
```
application/vnd.oci.descriptor.v1+json
```

#### Manifest Types
```
application/vnd.oci.image.index.v1+json          # Image Index
application/vnd.oci.image.manifest.v1+json       # Image Manifest
```

#### Config Types
```
application/vnd.oci.image.config.v1+json         # Image Configuration
```

#### Layer Types
```
application/vnd.oci.image.layer.v1.tar           # Uncompressed tar
application/vnd.oci.image.layer.v1.tar+gzip      # Gzip compressed
application/vnd.oci.image.layer.v1.tar+zstd      # Zstd compressed
application/vnd.oci.image.layer.nondistributable.v1.tar+gzip  # Non-distributable
```

## OCI Distribution Specification

### API Endpoints

#### Check API Version
```http
GET /v2/
```

Response:
```json
{
  "errors": []
}
```

#### List Repositories
```http
GET /v2/_catalog
```

Response:
```json
{
  "repositories": [
    "app/backend",
    "app/frontend",
    "lib/database"
  ]
}
```

#### List Tags
```http
GET /v2/<name>/tags/list
```

Response:
```json
{
  "name": "app/backend",
  "tags": [
    "latest",
    "v1.0.0",
    "v1.1.0"
  ]
}
```

#### Pull Manifest
```http
GET /v2/<name>/manifests/<reference>
Accept: application/vnd.oci.image.manifest.v1+json
```

#### Push Manifest
```http
PUT /v2/<name>/manifests/<reference>
Content-Type: application/vnd.oci.image.manifest.v1+json

{manifest content}
```

#### Check Blob Existence
```http
HEAD /v2/<name>/blobs/<digest>
```

#### Pull Blob
```http
GET /v2/<name>/blobs/<digest>
```

#### Push Blob (Monolithic)
```http
POST /v2/<name>/blobs/uploads/
Content-Type: application/octet-stream
Content-Length: <size>

{blob content}
```

#### Push Blob (Chunked)
```http
# Initiate upload
POST /v2/<name>/blobs/uploads/

# Upload chunk
PATCH /v2/<name>/blobs/uploads/<uuid>
Content-Type: application/octet-stream
Content-Range: <start>-<end>
Content-Length: <size>

{chunk content}

# Complete upload
PUT /v2/<name>/blobs/uploads/<uuid>?digest=<digest>
```

### Content Discovery

#### Referrers API
```http
GET /v2/<name>/referrers/<digest>
```

Response:
```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.index.v1+json",
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.manifest.v1+json",
      "digest": "sha256:a1b2c3...",
      "size": 1234,
      "artifactType": "application/vnd.example.signature.v1+json",
      "annotations": {
        "org.example.key": "value"
      }
    }
  ]
}
```

## Annotations

### Standard Annotations

```json
{
  "org.opencontainers.image.created": "2024-01-15T10:20:30Z",
  "org.opencontainers.image.authors": "Developer Name",
  "org.opencontainers.image.url": "https://example.com/app",
  "org.opencontainers.image.documentation": "https://docs.example.com",
  "org.opencontainers.image.source": "https://github.com/example/app",
  "org.opencontainers.image.version": "1.0.0",
  "org.opencontainers.image.revision": "abc123",
  "org.opencontainers.image.vendor": "Example Inc.",
  "org.opencontainers.image.licenses": "Apache-2.0",
  "org.opencontainers.image.ref.name": "latest",
  "org.opencontainers.image.title": "My Application",
  "org.opencontainers.image.description": "This is my application",
  "org.opencontainers.image.base.digest": "sha256:def456...",
  "org.opencontainers.image.base.name": "docker.io/library/alpine:latest"
}
```

## Practical Implementation Examples

### Creating OCI Image with Buildah

```bash
#!/bin/bash
# build-oci-image.sh

# Create container from scratch
container=$(buildah from scratch)

# Mount container filesystem
mnt=$(buildah mount $container)

# Install minimal system
dnf install --installroot $mnt --releasever 39 \
  --setopt install_weak_deps=false -y \
  bash coreutils

# Configure OCI annotations
buildah config \
  --annotation org.opencontainers.image.title="Minimal Container" \
  --annotation org.opencontainers.image.description="A minimal OCI container" \
  --annotation org.opencontainers.image.version="1.0.0" \
  --annotation org.opencontainers.image.created="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  $container

# Set OCI config
buildah config \
  --cmd /bin/bash \
  --env PATH=/usr/bin:/bin \
  $container

# Unmount
buildah umount $container

# Commit as OCI image
buildah commit --format oci $container oci:minimal:latest

# Save to OCI layout
buildah push oci:minimal:latest oci:/tmp/minimal-oci:latest
```

### Inspecting OCI Layout

```bash
# View structure
tree /tmp/minimal-oci/

# Read manifest
cat /tmp/minimal-oci/index.json | jq .

# Read image config
DIGEST=$(cat /tmp/minimal-oci/index.json | jq -r '.manifests[0].digest' | cut -d: -f2)
cat /tmp/minimal-oci/blobs/sha256/$DIGEST | jq .
```

### Converting Between Formats

```bash
# Docker to OCI
skopeo copy --format oci \
  docker://docker.io/nginx:latest \
  oci:nginx-oci:latest

# OCI to Docker
skopeo copy --format v2s2 \
  oci:nginx-oci:latest \
  docker://registry.example.com/nginx:latest
```

### Validating OCI Compliance

```bash
# Install oci-image-tool
go get -u github.com/opencontainers/image-tools/cmd/oci-image-tool

# Validate image
oci-image-tool validate --type imageLayout /tmp/minimal-oci

# Validate manifest
oci-image-tool validate --type manifest manifest.json

# Validate config
oci-image-tool validate --type config config.json
```

## OCI Runtime Compliance

### Testing Runtime Compliance

```bash
# Install runtime-tools
go get -u github.com/opencontainers/runtime-tools/cmd/oci-runtime-tool

# Generate runtime spec
oci-runtime-tool generate --output config.json

# Validate runtime spec
oci-runtime-tool validate config.json
```

### Creating Custom Runtime

```go
// minimal-runtime.go
package main

import (
    "encoding/json"
    "os"
    "os/exec"
    "syscall"
)

type Config struct {
    Process struct {
        Args []string `json:"args"`
        Env  []string `json:"env"`
        Cwd  string   `json:"cwd"`
    } `json:"process"`
    Root struct {
        Path string `json:"path"`
    } `json:"root"`
}

func main() {
    // Read config
    configFile, _ := os.Open("config.json")
    var config Config
    json.NewDecoder(configFile).Decode(&config)
    
    // Setup namespace
    syscall.Unshare(syscall.CLONE_NEWNS | syscall.CLONE_NEWPID)
    
    // Chroot
    syscall.Chroot(config.Root.Path)
    syscall.Chdir("/")
    
    // Execute process
    cmd := exec.Command(config.Process.Args[0], config.Process.Args[1:]...)
    cmd.Env = config.Process.Env
    cmd.Stdin = os.Stdin
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr
    cmd.Run()
}
```

## OCI Ecosystem Tools

### Compliant Runtimes
- **runc** - Reference implementation
- **crun** - Fast C-based runtime
- **runsc (gVisor)** - Security-focused runtime
- **kata-runtime** - VM-based runtime
- **youki** - Rust implementation

### Compliant Build Tools
- **Buildah** - Daemonless image builder
- **BuildKit** - Docker's advanced builder
- **Kaniko** - Container-based builder
- **img** - Standalone builder

### Compliant Registries
- **Docker Hub** - Docker's registry
- **Quay.io** - Red Hat's registry
- **Harbor** - Enterprise registry
- **Distribution** - OCI reference registry
- **Zot** - OCI-native registry

## Future of OCI

### OCI 1.1 Features (Released 2024)
- Artifact support beyond container images
- Improved multi-architecture support
- Enhanced referrers API
- Better content discovery

### Upcoming Developments
- WebAssembly (WASM) support
- Confidential computing standards
- Enhanced security specifications
- Improved supply chain security

## Best Practices

### 1. Use Standard Annotations
Always include standard OCI annotations for better tooling support.

### 2. Validate Compliance
Use validation tools to ensure OCI compliance.

### 3. Prefer OCI Format
Use OCI format for new projects for better portability.

### 4. Multi-Architecture Support
Build and distribute multi-architecture images.

### 5. Security First
Leverage OCI security features like signed images and attestations.

## Resources

- [OCI Specifications](https://github.com/opencontainers/runtime-spec)
- [Image Specification](https://github.com/opencontainers/image-spec)
- [Distribution Specification](https://github.com/opencontainers/distribution-spec)
- [Runtime Tools](https://github.com/opencontainers/runtime-tools)
- [Image Tools](https://github.com/opencontainers/image-tools)