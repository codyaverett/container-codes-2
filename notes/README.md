# Container Technologies Deep Dive Notes

This directory contains comprehensive technical notes and insights for the
ContainerCodes YouTube channel, focusing on the inner workings of container
technologies.

## Structure

### 🔧 Container Fundamentals

Learn how containers work under the hood:

- **[Namespaces](container-fundamentals/namespaces/)** - Linux namespaces and
  isolation mechanisms
- **[Cgroups](container-fundamentals/cgroups/)** - Control groups and resource
  management
- **[Overlay Filesystems](container-fundamentals/overlay-filesystems/)** -
  Container filesystem layers and storage drivers
- **[Container Runtime](container-fundamentals/container-runtime/)** - runc,
  crun, and runtime internals

### 🐳 Podman

Rootless, daemonless container engine:

- **[Rootless Containers](podman/rootless-containers/)** - Running containers
  without root privileges
- **[Pods vs Containers](podman/pods-vs-containers/)** - Kubernetes-style pod
  management
- **[Systemd Integration](podman/systemd-integration/)** - systemd services and
  Quadlet
- **[Networking](podman/networking/)** - CNI plugins and container networking

### 🏗️ Buildah

Container image building without Docker:

- **[Dockerfile vs Buildah](buildah/dockerfile-vs-buildah/)** - Migration and
  comparison guides
- **[Multi-stage Builds](buildah/multi-stage-builds/)** - Advanced build
  patterns and optimization
- **[Scripted Builds](buildah/scripted-builds/)** - Programmatic container
  creation

### 🔄 Skopeo

Container image management and transport:

- **[Registry Operations](skopeo/registry-operations/)** - Push, pull, and copy
  operations
- **[Image Inspection](skopeo/image-inspection/)** - Analyzing container images
  without pulling
- **[Air-gapped Workflows](skopeo/air-gapped-workflows/)** - Offline container
  operations

### 🏭 Infrastructure

Production-ready container deployments:

- **[Development](infrastructure/development/)** - Dev environment setup
  patterns
- **[Testing](infrastructure/testing/)** - Container-based testing strategies
- **[Production](infrastructure/production/)** - Production deployment patterns

## Contributing

Each section should include:

- Technical explanations with code examples
- Common pitfalls and troubleshooting
- Performance considerations
- Security best practices
- Links to official documentation

## Navigation

- [Examples](../examples/) - Practical demonstrations and code samples
- [Videos](../videos/) - YouTube episode content and scripts
- [Main README](../README.md) - Repository overview
