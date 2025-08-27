# ContainerCodes YouTube Channel Repository

Welcome to the **ContainerCodes** repository! This is the central hub for all
content related to our YouTube channel focusing on container technologies,
deep-dive technical insights, and practical implementations with Podman,
Buildah, Skopeo, and container infrastructure.

## 🎯 Channel Mission

We explore how containers work under the hood and share interesting insights on
how containers can be used for development, testing, and production deployments.
Containers can do it all while separating concerns.

## 📁 Repository Structure

### 📚 [Notes](notes/)

Comprehensive technical documentation and deep-dive explanations:

- **Container Fundamentals** - Namespaces, cgroups, overlay filesystems,
  runtimes
- **Podman** - Rootless containers, pods, systemd integration, networking
- **Buildah** - Container building without Docker, scripted builds
- **Skopeo** - Image management, registry operations, air-gapped workflows
- **Infrastructure** - Development, testing, and production deployment patterns

### 🎬 [Videos](videos/)

YouTube episode scripts, demo code, and supporting materials:

- Episode scripts and outlines
- Demonstration code and configurations
- Reference links and further reading
- Viewer Q&A responses

### 💻 [Examples](examples/)

Practical demonstrations and complete working examples:

- **Development Workflows** - Dev environment setups
- **Testing Strategies** - Container-based testing approaches
- **Production Deployments** - Real-world deployment patterns

### 🛠️ [Templates](templates/)

Consistent formatting templates for content creation:

- Episode script template
- Technical notes template
- Example documentation template

## 🚀 Getting Started

### For Viewers

1. Browse **[Notes](notes/)** for in-depth technical explanations
2. Check **[Examples](examples/)** for hands-on code you can run
3. Visit **[Videos](videos/)** for episode-specific content

### For Contributors

1. Use **[Templates](templates/)** for consistent formatting
2. Follow the structure outlined in existing content
3. Test all code examples before submitting
4. Include proper documentation and cleanup instructions

## 🔧 Development Environment

This repository includes a containerized development environment:

```bash
# Build and start the development environment
make up

# Run tests
make test

# Stop services
make down
```

### Available Commands

- `make build` - Build container images
- `make up` - Start services with compose
- `make down` - Stop and remove services
- `make test` - Run test suite
- `make lint` - Run code linting
- `make fmt` - Format code
- `make clean` - Clean up containers and images

## 🎓 Learning Path

### Beginner Track

1. [Container Fundamentals](notes/container-fundamentals/) - Start here to
   understand the basics
2. [Development Workflows](examples/development-workflows/) - Practical
   development setups
3. Episode 001: Container Internals Deep Dive

### Intermediate Track

1. [Podman Deep Dive](notes/podman/) - Advanced container management
2. [Testing Strategies](examples/testing-strategies/) - Container testing
   approaches
3. [Buildah Workflows](notes/buildah/) - Custom container building

### Advanced Track

1. [Production Deployments](examples/production-deployments/) - Real-world
   patterns
2. [Infrastructure](notes/infrastructure/) - Production-ready setups
3. [Skopeo Operations](notes/skopeo/) - Image management at scale

## 🌟 Key Technologies Covered

- **[Podman](https://podman.io/)** - Daemonless, rootless container engine
- **[Buildah](https://buildah.io/)** - Container building without Docker daemon
- **[Skopeo](https://github.com/containers/skopeo)** - Container image
  operations
- **Container Runtimes** - runc, crun, and OCI standards
- **Linux Containers** - Namespaces, cgroups, and kernel features
- **Container Orchestration** - Kubernetes, systemd, and deployment patterns

## 📺 YouTube Channel

Visit our [YouTube channel](https://youtube.com/@ContainerCodes) for video
content covering:

- Container internals and how they work
- Practical development workflows
- Production deployment strategies
- Security best practices
- Performance optimization
- Troubleshooting common issues

## 🤝 Contributing

We welcome contributions! Please:

1. Follow the existing structure and templates
2. Test all code examples thoroughly
3. Include proper documentation
4. Keep security best practices in mind
5. Focus on practical, real-world applications

See individual section READMEs for specific contribution guidelines.

## 📄 License

This repository contains educational content and examples. Please respect
copyright for any third-party materials referenced.

## 🔗 Links

- [YouTube Channel](https://youtube.com/@ContainerCodes)
- [Podman Documentation](https://docs.podman.io/)
- [Buildah Documentation](https://buildah.io/)
- [Skopeo Documentation](https://github.com/containers/skopeo)
- [OCI Specifications](https://opencontainers.org/)

## 📞 Contact

For questions, suggestions, or collaboration opportunities, please:

- Open an issue in this repository
- Comment on our YouTube videos
- Reach out through our channel's community tab

---

_Happy containerizing! 🐳_
