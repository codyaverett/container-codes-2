# Container Fundamentals: Complete Technical Guide

## What Are Containers?

Containers are lightweight, standalone, executable packages that include everything needed to run software: code, runtime, system tools, libraries, and settings. They leverage Linux kernel features to provide process isolation and resource management.

## Linux Kernel Features

### 1. Namespaces (Isolation)

Namespaces provide isolation between containers by partitioning kernel resources so that one set of processes sees one set of resources while another set sees a different set.

#### Types of Namespaces

##### PID Namespace (Process ID)
```bash
# Create new PID namespace
unshare --pid --fork --mount-proc /bin/bash

# Inside namespace
ps aux  # Shows only processes in this namespace
echo $$  # PID 1 in namespace

# View namespaces
ls -la /proc/$$/ns/
```

##### Network Namespace
```bash
# Create network namespace
ip netns add mynet

# Execute in namespace
ip netns exec mynet ip addr show

# Connect namespaces
ip link add veth0 type veth peer name veth1
ip link set veth1 netns mynet
```

##### Mount Namespace
```bash
# Create mount namespace
unshare --mount /bin/bash

# Mounts are isolated
mount -t tmpfs tmpfs /mnt
# Only visible in this namespace
```

##### UTS Namespace (Unix Time-sharing System)
```bash
# Create UTS namespace
unshare --uts /bin/bash

# Change hostname (isolated)
hostname container-host
```

##### IPC Namespace (Inter-Process Communication)
```bash
# Create IPC namespace
unshare --ipc /bin/bash

# IPC resources are isolated
ipcs  # Shows only this namespace's IPC resources
```

##### User Namespace
```bash
# Create user namespace
unshare --user --map-root-user /bin/bash

# Check user mapping
cat /proc/$$/uid_map
cat /proc/$$/gid_map
```

##### Cgroup Namespace
```bash
# Create cgroup namespace
unshare --cgroup /bin/bash

# Cgroup view is virtualized
cat /proc/$$/cgroup
```

### 2. Control Groups (cgroups)

Control groups (cgroups) limit, account for, and isolate resource usage (CPU, memory, disk I/O, network) of process groups.

#### cgroups v2 Architecture
```
/sys/fs/cgroup/
├── cgroup.controllers     # Available controllers
├── cgroup.subtree_control  # Enabled controllers
├── cpu.max                 # CPU limits
├── memory.max              # Memory limits
├── memory.current          # Current memory usage
└── io.max                  # I/O limits
```

#### Resource Controllers

##### CPU Controller
```bash
# Create cgroup
mkdir /sys/fs/cgroup/myapp

# Set CPU limit (50% of one CPU)
echo "50000 100000" > /sys/fs/cgroup/myapp/cpu.max

# Add process to cgroup
echo $$ > /sys/fs/cgroup/myapp/cgroup.procs
```

##### Memory Controller
```bash
# Set memory limit (100MB)
echo "104857600" > /sys/fs/cgroup/myapp/memory.max

# Set memory swap limit
echo "209715200" > /sys/fs/cgroup/myapp/memory.swap.max

# Check memory usage
cat /sys/fs/cgroup/myapp/memory.current
```

##### I/O Controller
```bash
# Set I/O limit (1MB/s read, 500KB/s write)
echo "8:0 rbps=1048576 wbps=524288" > /sys/fs/cgroup/myapp/io.max

# Monitor I/O stats
cat /sys/fs/cgroup/myapp/io.stat
```

##### PIDs Controller
```bash
# Limit number of processes
echo "100" > /sys/fs/cgroup/myapp/pids.max

# Check current count
cat /sys/fs/cgroup/myapp/pids.current
```

### 3. Union File Systems

Union filesystems allow files and directories of separate filesystems to be transparently overlaid, forming a single coherent filesystem.

#### OverlayFS

##### How OverlayFS Works
```
Upper Layer (read-write)
    ↓
Overlay Mount Point (merged view)
    ↑
Lower Layers (read-only)
```

##### Manual OverlayFS Setup
```bash
# Create directories
mkdir lower upper work merged

# Add content to lower
echo "base file" > lower/base.txt

# Mount overlay
mount -t overlay overlay \
  -o lowerdir=lower,upperdir=upper,workdir=work \
  merged

# Changes go to upper layer
echo "modified" > merged/base.txt
ls upper/  # Shows modified base.txt
```

##### Container Layer Structure
```bash
# Inspect container layers
podman inspect container_name | jq '.[0].GraphDriver'

# View actual layers
ls -la /var/lib/containers/storage/overlay/*/diff/
```

#### Other Storage Drivers

##### Device Mapper
```bash
# Thin provisioning with LVM
lvcreate -L 10G -T vg/thinpool
lvcreate -V 1G -T vg/thinpool -n container1
```

##### Btrfs
```bash
# Subvolume for container
btrfs subvolume create /var/lib/containers/storage/btrfs/container1
btrfs subvolume snapshot /source /container1
```

##### ZFS
```bash
# Dataset for container
zfs create pool/containers/container1
zfs snapshot pool/containers/container1@snapshot1
zfs clone pool/containers/container1@snapshot1 pool/containers/container2
```

## Container Runtime Components

### 1. OCI Runtime Specification

The Open Container Initiative (OCI) defines standards for container runtimes and images.

#### Runtime Specification Structure
```json
{
  "ociVersion": "1.0.2",
  "process": {
    "terminal": true,
    "user": {
      "uid": 0,
      "gid": 0
    },
    "args": ["/bin/sh"],
    "env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ],
    "cwd": "/",
    "capabilities": {
      "bounding": ["CAP_AUDIT_WRITE", "CAP_KILL"],
      "effective": ["CAP_AUDIT_WRITE", "CAP_KILL"],
      "permitted": ["CAP_AUDIT_WRITE", "CAP_KILL"]
    }
  },
  "root": {
    "path": "rootfs",
    "readonly": false
  },
  "mounts": [
    {
      "destination": "/proc",
      "type": "proc",
      "source": "proc"
    }
  ],
  "linux": {
    "namespaces": [
      {"type": "pid"},
      {"type": "network"},
      {"type": "ipc"},
      {"type": "uts"},
      {"type": "mount"}
    ],
    "resources": {
      "memory": {
        "limit": 536870912
      },
      "cpu": {
        "shares": 1024,
        "quota": 50000,
        "period": 100000
      }
    }
  }
}
```

### 2. Low-Level Runtimes

#### runc (Reference Implementation)
```bash
# Create bundle
mkdir mycontainer
cd mycontainer

# Create rootfs
mkdir rootfs
tar -C rootfs -xf /path/to/rootfs.tar

# Generate spec
runc spec

# Run container
runc run mycontainer

# Lifecycle commands
runc create mycontainer
runc start mycontainer
runc kill mycontainer
runc delete mycontainer
```

#### crun (C-based Alternative)
```bash
# Faster, smaller alternative to runc
crun --version

# Run with crun
crun run mycontainer

# Podman with crun
podman --runtime /usr/bin/crun run alpine
```

### 3. High-Level Runtimes

#### containerd
```bash
# Pull image
ctr image pull docker.io/library/alpine:latest

# Run container
ctr run docker.io/library/alpine:latest mycontainer

# List containers
ctr containers list

# Execute in container
ctr task exec --exec-id myexec mycontainer sh
```

#### CRI-O
```bash
# Configuration
cat /etc/crio/crio.conf

# Socket for Kubernetes
ls -la /var/run/crio/crio.sock

# crictl commands
crictl ps          # List containers
crictl images      # List images
crictl exec -it container_id sh
```

## Container Networking

### 1. Network Namespaces

```bash
# Create network namespace
ip netns add container_ns

# Create veth pair
ip link add veth0 type veth peer name veth1

# Move one end to namespace
ip link set veth1 netns container_ns

# Configure host side
ip addr add 10.0.0.1/24 dev veth0
ip link set veth0 up

# Configure container side
ip netns exec container_ns ip addr add 10.0.0.2/24 dev veth1
ip netns exec container_ns ip link set veth1 up
ip netns exec container_ns ip link set lo up

# Add default route
ip netns exec container_ns ip route add default via 10.0.0.1

# Enable forwarding
sysctl -w net.ipv4.ip_forward=1

# NAT for external access
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -j MASQUERADE
```

### 2. Container Network Interface (CNI)

#### CNI Configuration
```json
{
  "cniVersion": "1.0.0",
  "name": "mynet",
  "type": "bridge",
  "bridge": "cni0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "subnet": "10.88.0.0/16",
    "routes": [
      { "dst": "0.0.0.0/0" }
    ]
  }
}
```

#### Using CNI Plugins
```bash
# Bridge plugin
CNI_PATH=/usr/libexec/cni
$CNI_PATH/bridge < config.json

# Available plugins
ls /usr/libexec/cni/
# bridge, loopback, macvlan, ipvlan, vlan, host-local, dhcp
```

### 3. Network Drivers

#### Bridge Network
```bash
# Create bridge
ip link add name br0 type bridge
ip addr add 172.20.0.1/16 dev br0
ip link set br0 up

# Connect container
ip link set veth0 master br0
```

#### Macvlan Network
```bash
# Create macvlan
ip link add macvlan0 link eth0 type macvlan mode bridge

# In container namespace
ip netns exec container_ns ip link set macvlan0 up
```

#### IPvlan Network
```bash
# Create ipvlan
ip link add ipvlan0 link eth0 type ipvlan mode l2

# Configure in namespace
ip netns exec container_ns ip addr add 192.168.1.100/24 dev ipvlan0
```

## Container Security

### 1. Linux Capabilities

```bash
# View capabilities
capsh --print

# Drop all and add specific
--cap-drop=all --cap-add=NET_BIND_SERVICE

# Common capabilities for containers
CAP_CHOWN           # Change file ownership
CAP_DAC_OVERRIDE    # Bypass file permissions
CAP_FSETID          # Don't clear setuid/setgid bits
CAP_FOWNER          # Bypass permission checks on operations
CAP_MKNOD           # Create special files
CAP_NET_RAW         # Use RAW and PACKET sockets
CAP_SETGID          # Make arbitrary manipulations of process GIDs
CAP_SETUID          # Make arbitrary manipulations of process UIDs
CAP_SETFCAP         # Set file capabilities
CAP_SETPCAP         # Modify process capabilities
CAP_NET_BIND_SERVICE # Bind to ports < 1024
CAP_SYS_CHROOT      # Use chroot()
CAP_KILL            # Bypass permission checks for sending signals
CAP_AUDIT_WRITE     # Write to kernel audit log
```

### 2. Seccomp (Secure Computing Mode)

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": ["read", "write", "exit", "sigreturn"],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["clone"],
      "action": "SCMP_ACT_ALLOW",
      "args": [
        {
          "index": 0,
          "value": 2080505856,
          "op": "SCMP_CMP_MASKED_EQ"
        }
      ]
    }
  ]
}
```

### 3. SELinux

```bash
# Container SELinux contexts
ls -Z /var/lib/containers/

# Types
container_t         # Container process
container_file_t    # Container files
container_var_lib_t # Container persistent data

# Volume labeling
# :z - Shared among containers
# :Z - Private to container
-v /host/path:/container/path:Z
```

### 4. AppArmor

```bash
# Profile for container
#include <tunables/global>

profile container-default flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>
  
  network,
  capability,
  
  deny @{PROC}/* w,
  deny @{PROC}/{*,**^[0-9*],sys/kernel/shm*} wkx,
  deny mount,
  deny /sys/[^f]*/** wklx,
  deny /sys/f[^s]*/** wklx,
  deny /sys/fs/[^c]*/** wklx,
  deny /sys/fs/c[^g]*/** wklx,
  deny /sys/fs/cg[^r]*/** wklx,
}
```

## Container Image Format

### 1. OCI Image Specification

#### Image Layout
```
image/
├── blobs/
│   └── sha256/
│       ├── <config-hash>      # Image configuration
│       ├── <layer-hash>       # Layer tar files
│       └── <manifest-hash>    # Image manifest
├── index.json                 # Image index
└── oci-layout                 # Layout version
```

#### Image Manifest
```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "digest": "sha256:...",
    "size": 1469
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "digest": "sha256:...",
      "size": 5312
    }
  ]
}
```

#### Image Configuration
```json
{
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "Env": ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"],
    "Cmd": ["/bin/sh"],
    "WorkingDir": "/",
    "User": "0:0"
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:..."
    ]
  },
  "history": [
    {
      "created": "2024-01-01T00:00:00Z",
      "created_by": "/bin/sh -c #(nop) ADD file:... in /",
      "empty_layer": false
    }
  ]
}
```

### 2. Layer Management

```bash
# Extract layer
tar -xf layer.tar.gz -C layer_contents/

# Create new layer
tar -czf new_layer.tar.gz -C changes/ .

# Calculate diff
rsync -a --compare-dest=../lower/ upper/ diff/

# Apply layer
tar -xf layer.tar.gz -C rootfs/ --overwrite
```

## Process Management

### 1. Container Init Systems

#### tini (Tiny Init)
```dockerfile
FROM alpine
RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["your-app"]
```

#### dumb-init
```dockerfile
FROM alpine
RUN apk add --no-cache dumb-init
ENTRYPOINT ["dumb-init", "--"]
CMD ["your-app"]
```

### 2. Signal Handling

```bash
# Forward signals to container process
kill -TERM $(podman inspect -f '{{.State.Pid}}' container_name)

# Graceful shutdown
podman stop --time 30 container_name  # 30 second grace period
```

### 3. Process Monitoring

```bash
# Monitor container processes
podman top container_name

# Real-time stats
podman stats container_name

# System calls trace
strace -p $(podman inspect -f '{{.State.Pid}}' container_name)
```

## Resource Management

### 1. CPU Management

```bash
# CPU shares (relative weight)
--cpu-shares=512  # Default is 1024

# CPU quota and period
--cpu-quota=50000 --cpu-period=100000  # 50% of one CPU

# CPU cores
--cpuset-cpus="0,1"  # Use CPU 0 and 1

# Real-time scheduling
--cpu-rt-runtime=950000 --cpu-rt-period=1000000
```

### 2. Memory Management

```bash
# Memory limit
--memory=1g

# Memory + swap limit
--memory=1g --memory-swap=2g

# Memory reservation (soft limit)
--memory-reservation=750m

# Kernel memory limit
--kernel-memory=50m

# OOM killer disable
--oom-kill-disable
```

### 3. I/O Management

```bash
# Block I/O weight
--blkio-weight=500  # 10-1000

# Device read/write rates
--device-read-bps=/dev/sda:1mb
--device-write-bps=/dev/sda:500kb

# Device I/O operations per second
--device-read-iops=/dev/sda:1000
--device-write-iops=/dev/sda:500
```

## Advanced Topics

### 1. Rootless Containers

```bash
# Enable user namespaces
sysctl -w kernel.unprivileged_userns_clone=1

# Configure subuid/subgid
echo "$USER:100000:65536" | sudo tee -a /etc/subuid
echo "$USER:100000:65536" | sudo tee -a /etc/subgid

# Run rootless
podman run --rm -it alpine

# Check namespace mapping
podman unshare cat /proc/self/uid_map
```

### 2. Container Checkpointing (CRIU)

```bash
# Install CRIU
dnf install criu

# Checkpoint running container
podman container checkpoint container_name

# Restore container
podman container restore container_name

# Migrate container
podman container checkpoint container_name --export=/tmp/checkpoint.tar.gz
# On target host:
podman container restore --import=/tmp/checkpoint.tar.gz
```

### 3. GPU Support

```bash
# NVIDIA GPU
podman run --device nvidia.com/gpu=all nvidia/cuda:11.0-base nvidia-smi

# AMD GPU
podman run --device=/dev/dri --device=/dev/kfd rocm/tensorflow:latest

# Generic GPU passthrough
podman run --device=/dev/dri:/dev/dri:rwm ubuntu glxinfo
```

## Performance Tuning

### 1. Kernel Parameters

```bash
# Network performance
sysctl -w net.core.somaxconn=65535
sysctl -w net.ipv4.tcp_max_syn_backlog=65535
sysctl -w net.ipv4.ip_local_port_range="1024 65535"

# File descriptors
sysctl -w fs.file-max=2097152
sysctl -w fs.nr_open=2097152

# Memory management
sysctl -w vm.max_map_count=262144
sysctl -w vm.swappiness=10
```

### 2. Storage Optimization

```bash
# Use tmpfs for temporary data
--mount type=tmpfs,destination=/tmp,tmpfs-size=1G

# Direct LVM
--storage-opt dm.directlvm_device=/dev/sdb

# Overlay2 options
--storage-opt overlay.override_kernel_check=true
```

## Debugging Containers

### 1. Debugging Tools

```bash
# Enter container namespaces
nsenter -t $(podman inspect -f '{{.State.Pid}}' container) -a

# Debug with toolbox container
podman run -it --pid=container:target --network=container:target \
  --cap-add SYS_PTRACE nicolaka/netshoot

# System call tracing
strace -f -p $(podman inspect -f '{{.State.Pid}}' container)

# Network debugging
tcpdump -i eth0 -w capture.pcap
```

### 2. Troubleshooting Commands

```bash
# Inspect container
podman inspect container_name

# View logs
podman logs --tail=100 -f container_name

# Events
podman events --filter container=container_name

# Healthcheck
podman healthcheck run container_name

# Resource usage
podman stats --no-stream container_name
```

## Resources and References

- [OCI Specifications](https://github.com/opencontainers/runtime-spec)
- [Linux Kernel Documentation](https://www.kernel.org/doc/)
- [cgroups v2 Documentation](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html)
- [Container Security Best Practices](https://www.nist.gov/publications/application-container-security-guide)