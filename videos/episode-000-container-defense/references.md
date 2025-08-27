# Episode 000 References: Container Defense Against Malicious Code

## Essential Security Resources

### Container Security Standards
- **[NIST SP 800-190](https://csrc.nist.gov/publications/detail/sp/800-190/final)** - Application Container Security Guide
- **[CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)** - Security configuration benchmarks
- **[CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)** - Kubernetes security standards
- **[OWASP Container Security Top 10](https://owasp.org/www-project-container-security/)** - Top container security risks

### AI Code Security and Ethics
- **[OWASP AI Security Guide](https://owasp.org/www-project-ai-security-and-privacy-guide/)** - AI/ML security best practices
- **[Microsoft AI Security Framework](https://www.microsoft.com/en-us/research/publication/toward-comprehensive-risk-assessments-and-assurance-of-ai-based-systems/)** - Enterprise AI security
- **[NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework)** - Government AI security standards
- **[Partnership on AI Tenets](https://partnershiponai.org/tenets/)** - Industry AI ethics guidelines

## Supply Chain Security

### Package Security and Vulnerability Management
- **[SLSA Framework](https://slsa.dev/)** - Supply-chain Levels for Software Artifacts
- **[NIST Secure Software Development Framework](https://csrc.nist.gov/Projects/ssdf)** - Software supply chain security
- **[CISA Software Bill of Materials](https://www.cisa.gov/sbom)** - Government SBOM requirements
- **[OpenSSF Scorecard](https://github.com/ossf/scorecard)** - Open source project security scoring

### Dependency Vulnerability Databases
- **[National Vulnerability Database](https://nvd.nist.gov/)** - CVE database maintained by NIST
- **[GitHub Advisory Database](https://github.com/advisories)** - Security advisories for open source
- **[PyPI Advisory Database](https://github.com/pypa/advisory-database)** - Python package vulnerabilities
- **[npm Security Advisories](https://www.npmjs.com/advisories)** - Node.js package vulnerabilities
- **[RustSec Advisory Database](https://rustsec.org/)** - Rust crate vulnerabilities
- **[Go Vulnerability Database](https://pkg.go.dev/vuln/)** - Go module vulnerabilities

## Container Security Tools

### Vulnerability Scanners
- **[Trivy](https://github.com/aquasecurity/trivy)** - Comprehensive container vulnerability scanner
  - Supports OS packages, language dependencies, IaC misconfigurations
  - Multiple output formats including JSON, SARIF, CycloneDX
  - Can scan filesystems, container images, and Git repositories

- **[Grype](https://github.com/anchore/grype)** - Fast vulnerability scanner from Anchore
  - Focuses on speed and accuracy
  - Good integration with Syft for SBOM generation
  - Supports multiple Linux distributions and language ecosystems

- **[Clair](https://github.com/quay/clair)** - Container vulnerability analysis service
  - API-driven architecture for integration
  - Used by Quay.io and other registries
  - Supports incremental scanning

- **[Snyk Container](https://snyk.io/product/container-vulnerability-management/)** - Commercial vulnerability management
  - Deep integration with development workflows
  - Comprehensive language support
  - License compliance checking

### Static Analysis and Code Security
- **[Bandit](https://github.com/PyCQA/bandit)** - Python security linter
- **[Brakeman](https://brakemanscanner.org/)** - Ruby on Rails security scanner  
- **[ESLint Security Plugin](https://github.com/nodesecurity/eslint-plugin-security)** - JavaScript security rules
- **[Gosec](https://github.com/securecodewarrior/gosec)** - Go security analyzer
- **[Semgrep](https://semgrep.dev/)** - Multi-language static analysis
- **[CodeQL](https://codeql.github.com/)** - GitHub's code analysis engine

### Runtime Security
- **[Falco](https://falco.org/)** - Runtime security monitoring
- **[Sysdig Secure](https://sysdig.com/products/secure/)** - Commercial runtime protection
- **[Twistlock/Prisma Cloud](https://www.paloaltonetworks.com/prisma/cloud)** - Enterprise container security
- **[Aqua Security](https://www.aquasec.com/)** - Full-stack container security platform

## Rootless and User Namespace Security

### Rootless Container Technology
- **[Rootless Containers](https://rootlesscontaine.rs/)** - Comprehensive rootless container guide
- **[Podman Rootless Guide](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)** - Official Podman rootless tutorial
- **[User Namespaces](https://man7.org/linux/man-pages/man7/user_namespaces.7.html)** - Linux user namespace documentation
- **[Rootless Docker](https://docs.docker.com/engine/security/rootless/)** - Docker's rootless mode

### Linux Security Mechanisms
- **[SELinux Container Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/using-selinux-with-container-runtimes_using-selinux)** - SELinux and containers
- **[AppArmor Profiles](https://wiki.ubuntu.com/AppArmor/Documentation)** - Application confinement
- **[Seccomp BPF](https://www.kernel.org/doc/Documentation/prctl/seccomp_filter.txt)** - System call filtering
- **[Linux Capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)** - Fine-grained privilege control

## AI Code Generation Security

### Code Generation Risks
- **[Copilot Security Study](https://arxiv.org/abs/2108.09293)** - "Do Users Write More Insecure Code with AI Assistants?"
- **[CodeT5 Security Analysis](https://arxiv.org/abs/2109.00859)** - Security implications of code generation models
- **[GitHub Copilot Security](https://github.blog/2021-06-30-github-copilot-research-recitation/)** - GitHub's research on code generation security

### Code Review and Analysis
- **[SAST Tools Comparison](https://owasp.org/www-community/Source_Code_Analysis_Tools)** - OWASP static analysis tools
- **[Code Review Guidelines](https://google.github.io/eng-practices/review/)** - Google's code review practices
- **[Security Code Review](https://cheatsheetseries.owasp.org/cheatsheets/Code_Review_Introduction_Cheat_Sheet.html)** - OWASP security code review

## Container Isolation and Sandboxing

### Container Runtime Security
- **[OCI Runtime Specification](https://github.com/opencontainers/runtime-spec/blob/main/spec.md)** - Container runtime standards
- **[runc Security](https://github.com/opencontainers/runc/blob/main/docs/security.md)** - Reference runtime security
- **[gVisor](https://gvisor.dev/)** - Application kernel for container isolation
- **[Firecracker](https://firecracker-microvm.github.io/)** - Secure microVM technology

### Advanced Sandboxing
- **[Kata Containers](https://katacontainers.io/)** - Lightweight VMs for container workloads  
- **[Confidential Containers](https://github.com/confidential-containers)** - Hardware-based container isolation
- **[Intel TDX](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-trust-domain-extensions.html)** - Hardware-based trusted execution
- **[AMD SEV](https://developer.amd.com/sev/)** - Secure Encrypted Virtualization

## Development Environment Security

### Secure Development Practices
- **[NIST Secure Software Development](https://csrc.nist.gov/Projects/ssdf)** - Framework for secure development
- **[OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)** - DevSecOps best practices
- **[Microsoft Security Development Lifecycle](https://www.microsoft.com/en-us/securityengineering/sdl/)** - SDL practices

### Container Development Security
- **[Distroless Images](https://github.com/GoogleContainerTools/distroless)** - Minimal container images
- **[Multi-stage Builds](https://docs.docker.com/develop/dev-best-practices/)** - Secure container building
- **[Image Signing](https://docs.sigstore.dev/)** - Container image signing with Sigstore
- **[Harbor Registry](https://goharbor.io/)** - Enterprise container registry with security scanning

## Compliance and Governance

### Regulatory Frameworks
- **[SOC 2 Container Controls](https://www.aicpa.org/content/dam/aicpa/interestareas/frc/assuranceadvisoryservices/downloadabledocuments/trust-services-criteria.pdf)** - SOC 2 Type II controls
- **[HIPAA Container Compliance](https://www.hhs.gov/hipaa/for-professionals/security/guidance/cybersecurity/index.html)** - Healthcare compliance
- **[PCI DSS Containers](https://www.pcisecuritystandards.org/documents/Guidance-for-PCI-DSS-and-Virtualization-v2.pdf)** - Payment card industry compliance
- **[FedRAMP Container Security](https://www.fedramp.gov/assets/resources/documents/CSP_Continuous_Monitoring_Strategy_Guide.pdf)** - Federal compliance

### Industry Standards
- **[ISO 27001 Container Controls](https://www.iso.org/isoiec-27001-information-security.html)** - Information security management
- **[GDPR Data Protection](https://gdpr.eu/what-is-gdpr/)** - European data protection regulation
- **[SOX Container Controls](https://www.sec.gov/about/laws/soa2002.pdf)** - Sarbanes-Oxley compliance

## Threat Intelligence and Incident Response

### Container Threat Landscape
- **[MITRE ATT&CK Containers](https://attack.mitre.org/matrices/enterprise/containers/)** - Container attack techniques
- **[Unit 42 Container Threat Report](https://unit42.paloaltonetworks.com/)** - Palo Alto container security research
- **[Sysdig Container Threat Report](https://sysdig.com/blog/sysdig-2023-cloud-native-security-and-usage-report/)** - Annual threat landscape analysis

### Incident Response
- **[NIST Incident Response Guide](https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final)** - Computer security incident handling
- **[Container Forensics](https://github.com/google/docker-explorer)** - Container forensic analysis tools
- **[SANS Container Incident Response](https://www.sans.org/white-papers/)** - SANS incident response guides

## Academic Research and Papers

### Container Security Research
- **[Container Security: Issues, Challenges, and Solutions](https://ieeexplore.ieee.org/document/8693491)** - IEEE comprehensive analysis
- **[Security Analysis of Docker Containers](https://www.usenix.org/system/files/conference/usenixsecurity16/sec16_paper_combe.pdf)** - USENIX Security 2016
- **[Improving Docker Container Security](https://dl.acm.org/doi/10.1145/3134600.3134612)** - ACM research paper

### AI Security Research  
- **[Adversarial Examples for Code](https://arxiv.org/abs/1910.07517)** - Code adversarial attacks
- **[Security Risks in Deep Learning](https://arxiv.org/abs/1904.07204)** - ML security comprehensive survey
- **[AI Supply Chain Security](https://arxiv.org/abs/2204.04197)** - Machine learning supply chain attacks

## Tools and Automation

### CI/CD Security Integration
- **[GitHub Actions Security](https://docs.github.com/en/actions/security-guides)** - GitHub Actions security best practices
- **[Jenkins Container Security](https://www.jenkins.io/doc/book/pipeline/docker/)** - Jenkins Docker pipeline security
- **[GitLab Container Scanning](https://docs.gitlab.com/ee/user/application_security/container_scanning/)** - GitLab security scanning

### Infrastructure as Code Security
- **[Terraform Security](https://www.terraform.io/docs/cloud/sentinel/index.html)** - Policy as code for Terraform
- **[Checkov](https://github.com/bridgecrewio/checkov)** - Static analysis for IaC
- **[Terrascan](https://github.com/accurics/terrascan)** - Security scanner for IaC
- **[KICS](https://github.com/Checkmarx/kics)** - Infrastructure security scanner

### Monitoring and Observability
- **[Prometheus Security](https://prometheus.io/docs/operating/security/)** - Monitoring security
- **[Grafana Security](https://grafana.com/docs/grafana/latest/administration/security/)** - Dashboard security
- **[Jaeger Security](https://www.jaegertracing.io/docs/1.37/security/)** - Distributed tracing security

## Community Resources

### Security Communities
- **[CNCF Security TAG](https://github.com/cncf/tag-security)** - Cloud Native Computing Foundation security
- **[Container Security Slack](https://cloud-native.slack.com/)** - CNCF Slack #security channel
- **[Reddit r/netsec](https://www.reddit.com/r/netsec/)** - Network security community
- **[InfoSec Community](https://infosec.exchange/)** - Mastodon security community

### Conferences and Events
- **[RSA Conference](https://www.rsaconference.com/)** - Premier security conference
- **[Black Hat](https://www.blackhat.com/)** - Information security conference
- **[DEF CON](https://defcon.org/)** - Hacker conference
- **[KubeCon + CloudNativeCon](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/)** - Container platform conference
- **[DockerCon](https://www.docker.com/dockercon/)** - Container technology conference

### Training and Certification
- **[SANS Container Security](https://www.sans.org/cyber-security-courses/container-security-deployment-and-runtime-protection/)** - Professional container security training
- **[Linux Foundation Container Security](https://training.linuxfoundation.org/training/kubernetes-security-essentials-lfs260/)** - Kubernetes security certification
- **[Cloud Security Alliance](https://cloudsecurityalliance.org/education/)** - Cloud security education

## Emerging Technologies

### Zero Trust Architecture
- **[NIST Zero Trust Architecture](https://csrc.nist.gov/publications/detail/sp/800-207/final)** - Zero trust principles
- **[CISA Zero Trust Maturity Model](https://www.cisa.gov/zero-trust-maturity-model)** - Government zero trust guidance
- **[Container Zero Trust](https://www.nist.gov/blogs/cybersecurity-insights/implementing-zero-trust-architecture)** - Zero trust for containers

### Confidential Computing
- **[Confidential Computing Consortium](https://confidentialcomputing.io/)** - Industry consortium
- **[Intel SGX](https://software.intel.com/content/www/us/en/develop/topics/software-guard-extensions.html)** - Software Guard Extensions
- **[ARM TrustZone](https://www.arm.com/products/security/trustzone)** - ARM security technology

### Quantum-Safe Security
- **[NIST Post-Quantum Cryptography](https://csrc.nist.gov/Projects/post-quantum-cryptography)** - Quantum-resistant cryptography
- **[Quantum Safe Security](https://www.quantum-safe-security.org/)** - Quantum security working group

## Next Episode Resources

### Container Internals (Episode 1 Preparation)
- **[Linux Namespaces Deep Dive](https://man7.org/linux/man-pages/man7/namespaces.7.html)** - Technical namespace documentation
- **[Control Groups v2](https://docs.kernel.org/admin-guide/cgroup-v2.html)** - Cgroups technical documentation
- **[OCI Runtime Implementation](https://github.com/opencontainers/runc)** - Reference container runtime

### Podman vs Docker Security (Episode 2 Preparation)
- **[Podman Security Advantages](https://developers.redhat.com/blog/2020/09/25/rootless-containers-with-podman-the-basics)** - Rootless container benefits
- **[Docker Security Best Practices](https://docs.docker.com/engine/security/)** - Docker security guidelines
- **[Container Runtime Comparison](https://kubernetes.io/blog/2016/12/container-runtime-interface-cri-in-kubernetes/)** - CRI and runtime security