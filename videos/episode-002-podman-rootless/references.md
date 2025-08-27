# Episode 002 References: Podman vs Docker Security Revolution

## Essential Security Documentation

### Container Security Standards

- **[NIST SP 800-190](https://csrc.nist.gov/publications/detail/sp/800-190/final)** -
  Application Container Security Guide
- **[CIS Benchmarks - Container Runtime](https://www.cisecurity.org/benchmark/docker)** -
  Security configuration guidelines
- **[OWASP Container Security](https://owasp.org/www-project-container-security/)** -
  OWASP container security project
- **[PCI DSS Container Guidelines](https://www.pcisecuritystandards.org/documents/Guidance-for-PCI-DSS-and-Virtualization-v2.pdf)** -
  Compliance considerations

### User Namespaces and Rootless Containers

- **[User Namespaces Manual](https://man7.org/linux/man-pages/man7/user_namespaces.7.html)** -
  Complete technical reference
- **[Rootless Containers](https://rootlesscontaine.rs/)** - Comprehensive
  rootless container resource
- **[User Namespace Security](https://lwn.net/Articles/532593/)** - LWN article
  on user namespace security implications
- **[Podman Rootless Tutorial](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)** -
  Official rootless setup guide

## Docker Security Issues and CVEs

### Historical Vulnerabilities

- **[CVE-2019-5736](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-5736)** -
  runc container escape (RunC vulnerability)
- **[CVE-2019-14271](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-14271)** -
  Docker daemon privilege escalation
- **[CVE-2020-15257](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-15257)** -
  containerd vulnerability affecting Docker
- **[Docker Security Advisories](https://docs.docker.com/engine/security/)** -
  Official Docker security documentation

### Attack Vectors and Research

- **[Container Escape Techniques](https://blog.trailofbits.com/2019/07/19/understanding-docker-container-escapes/)** -
  Trail of Bits container escape analysis
- **[Breaking Out of Docker](https://blog.ropnop.com/docker-for-pentesters/)** -
  Penetration testing perspective
- **[Container Security Threats](https://www.aquasec.com/cloud-native-academy/container-security/container-security-threats/)** -
  Comprehensive threat landscape

## Podman Architecture and Security

### Official Documentation

- **[Podman Security Features](https://docs.podman.io/en/latest/markdown/podman.1.html#security-options)** -
  Official security documentation
- **[Podman Architecture](https://podman.io/whatis.html)** - How Podman differs
  from Docker
- **[Rootless Podman](https://docs.podman.io/en/latest/markdown/podman.1.html#rootless-mode)** -
  Rootless container implementation details

### Technical Implementation

- **[Podman Without Docker](https://developers.redhat.com/blog/2019/02/21/podman-and-buildah-for-docker-users)** -
  Migration guide and security benefits
- **[Fork vs Daemon](https://podman.io/blogs/2018/10/31/podman-why-no-daemon.html)** -
  Why daemonless is more secure
- **[User Namespace Mapping](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md#user-namespace-mapping)** -
  Technical details

## Linux Security Mechanisms

### SELinux and Container Security

- **[SELinux and Containers](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/using-selinux-with-container-runtimes_using-selinux)** -
  Red Hat SELinux container guide
- **[Container SELinux Policies](https://danwalsh.livejournal.com/74754.html)** -
  Dan Walsh's container SELinux blog
- **[MCS Labels](https://selinuxproject.org/page/NB_MLS)** - Multi-Category
  Security for containers

### AppArmor and Container Confinement

- **[AppArmor Container Profiles](https://wiki.ubuntu.com/AppArmor/Documentation)** -
  Ubuntu AppArmor documentation
- **[Container AppArmor Profiles](https://docs.docker.com/engine/security/apparmor/)** -
  Docker AppArmor integration
- **[Custom AppArmor Profiles](https://gitlab.com/apparmor/apparmor/-/wikis/Documentation)** -
  Creating custom profiles

### Seccomp and System Call Filtering

- **[Seccomp BPF](https://www.kernel.org/doc/Documentation/prctl/seccomp_filter.txt)** -
  Kernel seccomp documentation
- **[Container Seccomp Profiles](https://docs.docker.com/engine/security/seccomp/)** -
  Docker seccomp integration
- **[Seccomp Profile Generation](https://github.com/docker/labs/tree/master/security/seccomp)** -
  Tools for creating seccomp profiles

## Enterprise Security and Compliance

### Regulatory Compliance

- **[SOC 2 Container Security](https://www.aicpa.org/content/dam/aicpa/interestareas/frc/assuranceadvisoryservices/downloadabledocuments/trust-services-criteria.pdf)** -
  SOC 2 criteria for containers
- **[HIPAA Container Guidelines](https://www.hhs.gov/hipaa/for-professionals/security/guidance/cybersecurity/index.html)** -
  Healthcare compliance considerations
- **[FedRAMP Container Security](https://www.fedramp.gov/)** - Federal
  compliance requirements

### Enterprise Adoption Studies

- **[Red Hat Container Adoption](https://www.redhat.com/en/resources/state-of-enterprise-open-source-report-2021)** -
  2021 Enterprise Open Source Report
- **[CNCF Survey 2024](https://www.cncf.io/reports/cncf-annual-survey-2024/)** -
  Cloud Native adoption trends
- **[Docker Business Trends](https://www.docker.com/blog/2025-docker-state-of-app-dev/)** -
  2025 State of Application Development

## Security Tools and Scanning

### Container Image Scanning

- **[Clair](https://github.com/quay/clair)** - Open source vulnerability scanner
- **[Trivy](https://github.com/aquasecurity/trivy)** - Comprehensive
  vulnerability scanner
- **[Anchore Engine](https://github.com/anchore/anchore-engine)** - Container
  analysis and compliance
- **[Snyk Container](https://snyk.io/product/container-vulnerability-management/)** -
  Commercial container security

### Runtime Security

- **[Falco](https://falco.org/)** - Runtime security monitoring
- **[Sysdig Secure](https://sysdig.com/products/secure/)** - Commercial runtime
  protection
- **[Twistlock (Prisma Cloud)](https://www.paloaltonetworks.com/prisma/cloud)** -
  Comprehensive container security platform
- **[Aqua Security](https://www.aquasec.com/)** - End-to-end container security

### Security Benchmarking

- **[Docker Bench Security](https://github.com/docker/docker-bench-security)** -
  Docker security benchmarking tool
- **[kube-bench](https://github.com/aquasecurity/kube-bench)** - Kubernetes
  security benchmarking
- **[Container Security Benchmarks](https://www.cisecurity.org/benchmark/docker)** -
  CIS benchmarks for containers

## Migration and Best Practices

### Docker to Podman Migration

- **[Podman for Docker Users](https://developers.redhat.com/blog/2019/02/21/podman-and-buildah-for-docker-users)** -
  Comprehensive migration guide
- **[Docker Compose Alternative](https://github.com/containers/podman-compose)** -
  podman-compose for Docker Compose users
- **[Migration Checklist](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/building_running_and_managing_containers/assembly_porting-containers-to-systemd-using-podman_building-running-and-managing-containers)** -
  Red Hat migration documentation

### Security Best Practices

- **[Container Security Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Container_Security_Cheat_Sheet.html)** -
  OWASP security cheat sheet
- **[Least Privilege Containers](https://kubernetes.io/docs/concepts/security/pod-security-standards/)** -
  Kubernetes Pod Security Standards
- **[Supply Chain Security](https://slsa.dev/)** - Supply-chain Levels for
  Software Artifacts (SLSA)

## Kubernetes and Orchestration Security

### Pod Security

- **[Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)** -
  Kubernetes pod security policies
- **[OpenShift Security](https://docs.openshift.com/container-platform/4.12/authentication/managing-security-context-constraints.html)** -
  Security Context Constraints (SCCs)
- **[Gatekeeper](https://github.com/open-policy-agent/gatekeeper)** - Open
  Policy Agent for Kubernetes

### Network Security

- **[Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)** -
  Kubernetes network segmentation
- **[Calico Security](https://docs.projectcalico.org/security/)** - Calico
  network security features
- **[Istio Security](https://istio.io/latest/docs/concepts/security/)** -
  Service mesh security

## Research Papers and Academic Work

### Container Security Research

- **[An Updated Performance Comparison of Virtual Machines and Linux Containers](https://domino.research.ibm.com/library/cyberdig.nsf/papers/0929052195DD819C85257D2300681E7B/$File/rc25482.pdf)** -
  IBM Research paper
- **[Security Analysis of Container Runtimes](https://www.usenix.org/system/files/conference/usenixsecurity16/sec16_paper_combe.pdf)** -
  USENIX Security 2016
- **[Container Security: Issues, Challenges, and Solutions](https://ieeexplore.ieee.org/document/8693491)** -
  IEEE paper on container security

### Linux Security Mechanisms

- **[The Confused Deputy Problem](https://www.cs.jhu.edu/~fabian/courses/CS600.424/course_papers/confused_deputy.pdf)** -
  Classic security paper relevant to container privilege escalation
- **[Capability-Based Computer Systems](https://homes.cs.washington.edu/~levy/capabook/Chapter1.pdf)** -
  Theoretical foundation for Linux capabilities
- **[Security in Computing Systems](https://cseweb.ucsd.edu/~savage/papers/Oakland03.pdf)** -
  Computer security fundamentals

## Community Resources and Forums

### Security Communities

- **[Container Security Slack](https://cloud-native.slack.com/)** - CNCF Slack
  #security channel
- **[r/netsec](https://www.reddit.com/r/netsec/)** - Reddit security community
- **[Container Security Reddit](https://www.reddit.com/r/docker/)** -
  Docker/container discussions

### Conferences and Talks

- **[KubeCon Security Talks](https://www.youtube.com/playlist?list=PLj6h78yzYM2O1wlsM-Ma-RYhfT5LKq0XC)** -
  KubeCon container security presentations
- **[DockerCon Security](https://www.docker.com/dockercon/)** - Docker-focused
  security talks
- **[RSA Conference Container Security](https://www.rsaconference.com/)** -
  Enterprise security conference

### Security Blogs and Updates

- **[Aqua Security Blog](https://blog.aquasec.com/)** - Regular container
  security updates
- **[Sysdig Blog](https://sysdig.com/blog/)** - Runtime security insights
- **[Red Hat Security Blog](https://www.redhat.com/en/blog/channel/security)** -
  Enterprise container security
- **[Docker Security Blog](https://www.docker.com/blog/category/security/)** -
  Official Docker security updates

## Tools for Hands-on Learning

### Security Testing Tools

- **[kali-linux-docker](https://hub.docker.com/r/kalilinux/kali-rolling)** -
  Penetration testing environment
- **[DVWA Container](https://github.com/vulnerables/web-dvwa)** - Deliberately
  vulnerable web application
- **[Container Escape Practice](https://github.com/cdk-team/CDK)** - Container
  penetration testing toolkit

### Monitoring and Forensics

- **[osquery](https://osquery.io/)** - Operating system instrumentation and
  monitoring
- **[Sysmon for Linux](https://github.com/Sysinternals/SysmonForLinux)** -
  System monitoring for Linux
- **[auditd](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/auditing-the-system_security-hardening)** -
  Linux audit framework

## Next Episode Preparation

### Buildah Security Features

- **[Buildah Security](https://buildah.io/blogs/2017/06/21/introducing-buildah.html)** -
  Buildah introduction and security benefits
- **[Rootless Building](https://github.com/containers/buildah/blob/main/docs/tutorials/05-openshift-rootless-build.md)** -
  Rootless container building
- **[Build Security](https://developers.redhat.com/blog/2019/05/17/an-introduction-to-buildah/)** -
  Secure container building practices
