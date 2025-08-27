# Episode 001 References: Container Internals Deep Dive

## Essential Documentation

### Linux Namespaces
- **[Linux Namespaces Manual](https://man7.org/linux/man-pages/man7/namespaces.7.html)** - Complete technical reference for all namespace types
- **[Namespace API](https://man7.org/linux/man-pages/man2/unshare.2.html)** - System call documentation for namespace creation
- **[Mount Namespaces](https://man7.org/linux/man-pages/man7/mount_namespaces.7.html)** - Detailed mount namespace behavior

### Control Groups (Cgroups)
- **[Cgroups v2 Documentation](https://docs.kernel.org/admin-guide/cgroup-v2.html)** - Official kernel documentation
- **[Cgroups v1 vs v2](https://systemd.io/CGROUP_DELEGATION/)** - Systemd's perspective on cgroup delegation
- **[Resource Controllers](https://docs.kernel.org/admin-guide/cgroup-v2.html#controllers)** - Memory, CPU, IO, and other controllers

### Container Standards
- **[OCI Runtime Specification](https://github.com/opencontainers/runtime-spec)** - Open Container Initiative runtime standard
- **[OCI Image Specification](https://github.com/opencontainers/image-spec)** - Container image format specification
- **[Container Standards](https://opencontainers.org/about/overview/)** - Overview of OCI standards

## Tool-Specific Documentation

### Podman
- **[Podman Documentation](https://docs.podman.io/)** - Official Podman documentation
- **[Podman Architecture](https://docs.podman.io/en/latest/markdown/podman.1.html)** - How Podman works internally
- **[Rootless Containers](https://docs.podman.io/en/latest/markdown/podman-run.1.html#rootless-containers)** - Podman's rootless implementation

### Container Runtimes
- **[runc Documentation](https://github.com/opencontainers/runc)** - Reference OCI runtime implementation
- **[crun Documentation](https://github.com/containers/crun)** - Fast C-based OCI runtime
- **[Runtime Comparison](https://www.redhat.com/en/blog/introduction-crun)** - Performance comparison between runtimes

## Technical Deep Dives

### System Programming
- **[Linux Programming Interface](http://man7.org/tlpi/)** - Comprehensive guide to Linux system programming
- **[Understanding the Linux Kernel](https://www.oreilly.com/library/view/understanding-the-linux/0596005652/)** - Kernel internals book
- **[strace Tutorial](https://strace.io/strace.1.html)** - Complete strace manual

### Container Internals
- **[Containers from Scratch](https://ericchiang.github.io/post/containers-from-scratch/)** - Build a container runtime in Go
- **[Linux Containers in 500 Lines](https://blog.lizzie.io/linux-containers-in-500-loc.html)** - Minimal container implementation
- **[Anatomy of a Container](https://www.cyphar.com/blog/post/20160627-containers-101)** - Detailed technical breakdown

## Security Resources

### Container Security
- **[Container Security Guide](https://cheatsheetseries.owasp.org/cheatsheets/Container_Security_Cheat_Sheet.html)** - OWASP container security best practices
- **[User Namespaces](https://lwn.net/Articles/532593/)** - Security implications of user namespaces
- **[Rootless Container Security](https://rootlesscontaine.rs/)** - Comprehensive rootless container security

### Linux Security
- **[SELinux and Containers](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/using-selinux-with-container-runtimes_using-selinux)** - SELinux integration
- **[AppArmor Profiles](https://wiki.ubuntu.com/AppArmor/Documentation)** - Application confinement
- **[Seccomp Profiles](https://docs.docker.com/engine/security/seccomp/)** - System call filtering

## Practical Tutorials

### Hands-on Learning
- **[Linux Namespaces Tutorial Series](https://www.toptal.com/linux/separation-anxiety-isolating-your-system-with-linux-namespaces)** - Step-by-step namespace exploration
- **[Cgroups Tutorial](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/resource_management_guide/ch01)** - Red Hat cgroups guide
- **[Container Debugging](https://iximiuz.com/en/posts/container-debugging-is-broken/)** - Advanced debugging techniques

### Development Resources
- **[OCI Runtime Implementation](https://github.com/containers/youki)** - Rust-based OCI runtime for learning
- **[Minimal Container Runtime](https://github.com/p8952/bocker)** - Docker-like functionality in Bash
- **[Container Tools](https://github.com/containers/)** - Source code for Podman, Buildah, Skopeo

## Performance and Monitoring

### Performance Analysis
- **[Container Performance](https://www.brendangregg.com/blog/2017-05-15/container-performance-analysis-dockercon-2017.html)** - Brendan Gregg's container performance guide
- **[Linux Performance Tools](https://www.brendangregg.com/linuxperf.html)** - Complete Linux performance toolkit
- **[BPF and Containers](https://www.iovisor.org/technology/ebpf)** - eBPF for container observability

### Monitoring Tools
- **[cAdvisor](https://github.com/google/cadvisor)** - Container resource monitoring
- **[Prometheus Node Exporter](https://github.com/prometheus/node_exporter)** - System metrics collection
- **[systemd Journal](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html)** - Container logging with systemd

## Historical Context

### Container Evolution
- **[History of Containers](https://blog.aquasec.com/a-brief-history-of-containers-from-1970s-chroot-to-docker-2016)** - From chroot to modern containers
- **[Docker vs Podman Timeline](https://developers.redhat.com/blog/2019/02/21/podman-and-buildah-for-docker-users)** - Evolution of container tools
- **[Kubernetes Origins](https://kubernetes.io/blog/2015/04/borg-predecessor-to-kubernetes/)** - From Google Borg to Kubernetes

### Related Technologies
- **[FreeBSD Jails](https://docs.freebsd.org/en/books/handbook/jails/)** - Container-like isolation on FreeBSD
- **[Solaris Zones](https://docs.oracle.com/cd/E53394_01/html/E54830/)** - Solaris container technology
- **[LXC Documentation](https://linuxcontainers.org/lxc/documentation/)** - Linux Containers project

## Books and Publications

### Technical Books
- **"Container Security" by Liz Rice** - Comprehensive container security guide
- **"Docker Deep Dive" by Nigel Poulton** - In-depth Docker technical guide
- **"Kubernetes in Action" by Marko Lukša** - Kubernetes internals and best practices

### Research Papers
- **[Borg Paper](https://research.google/pubs/pub43438/)** - Google's container orchestration system
- **[Linux Containers Research](https://lwn.net/Articles/531114/)** - Academic perspective on container technology
- **[Container Security Analysis](https://www.usenix.org/system/files/conference/usenixsecurity16/sec16_paper_combe.pdf)** - Security analysis of container runtimes

## Community Resources

### Forums and Discussion
- **[Podman Community](https://podman.io/community/)** - Official Podman community resources
- **[Container Reddit](https://www.reddit.com/r/docker/)** - Community discussions
- **[Stack Overflow Container Tags](https://stackoverflow.com/questions/tagged/containers)** - Q&A for container issues

### Conferences and Talks
- **[KubeCon + CloudNativeCon](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/)** - Premier container conference
- **[Container Days](https://containerdays.io/)** - European container conference
- **[DockerCon](https://www.docker.com/dockercon/)** - Docker-focused conference

## Tools for Further Exploration

### Analysis Tools
- **[dive](https://github.com/wagoodman/dive)** - Explore container image layers
- **[docker-slim](https://github.com/docker-slim/docker-slim)** - Minimize container images
- **[container-diff](https://github.com/GoogleContainerTools/container-diff)** - Compare container images

### Development Tools
- **[buildkit](https://github.com/moby/buildkit)** - Modern container build toolkit
- **[kaniko](https://github.com/GoogleContainerTools/kaniko)** - Build container images in Kubernetes
- **[img](https://github.com/genuinetools/img)** - Standalone container image building

## Next Episode Preview Resources
- **[Rootless Container Implementation](https://rootlesscontaine.rs/getting-started/common/cgroup2/)** - Technical details for Episode 2
- **[Podman vs Docker Security](https://developers.redhat.com/blog/2020/09/25/rootless-containers-with-podman-the-basics)** - Security comparison preparation