# Practical Container Examples & Code Samples

## 1. Development Environment Setup

### Python Development Container

```bash
#!/bin/bash
# python-dev-setup.sh

# Create container from Python image
container=$(buildah from python:3.11-slim)

# Install development tools
buildah run $container -- apt-get update
buildah run $container -- apt-get install -y \
    git \
    vim \
    curl \
    build-essential \
    postgresql-client

# Setup Python environment
buildah run $container -- pip install --upgrade pip
buildah run $container -- pip install \
    ipython \
    pytest \
    black \
    flake8 \
    mypy \
    poetry

# Configure workspace
buildah config --workingdir /workspace $container
buildah config --env PYTHONDONTWRITEBYTECODE=1 $container
buildah config --env PYTHONUNBUFFERED=1 $container
buildah config --volume /workspace $container

# Commit image
buildah commit $container python-dev:latest
buildah rm $container

# Run development container
podman run -it --rm \
    -v $(pwd):/workspace:Z \
    -p 8000:8000 \
    --name pydev \
    python-dev:latest \
    /bin/bash
```

### Node.js Development with Hot Reload

```dockerfile
# Dockerfile.node-dev
FROM node:18-alpine
WORKDIR /app
RUN apk add --no-cache git
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  node-app:
    build:
      context: .
      dockerfile: Dockerfile.node-dev
    volumes:
      - .:/app:z
      - /app/node_modules
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    command: npm run dev
```

```bash
# Run with Podman
podman-compose up

# Or with systemd
podman generate systemd --new --name node-app > ~/.config/systemd/user/node-app.service
systemctl --user enable --now node-app.service
```

## 2. Multi-Container Applications

### WordPress with MariaDB

```bash
#!/bin/bash
# wordpress-stack.sh

# Create pod
podman pod create --name wordpress-pod \
    -p 8080:80 \
    -p 3306:3306

# Run MariaDB
podman run -d --pod wordpress-pod \
    --name wordpress-db \
    -e MYSQL_ROOT_PASSWORD=rootpass \
    -e MYSQL_DATABASE=wordpress \
    -e MYSQL_USER=wpuser \
    -e MYSQL_PASSWORD=wppass \
    -v wordpress-db:/var/lib/mysql:Z \
    mariadb:latest

# Wait for database to be ready
sleep 10

# Run WordPress
podman run -d --pod wordpress-pod \
    --name wordpress-app \
    -e WORDPRESS_DB_HOST=127.0.0.1 \
    -e WORDPRESS_DB_USER=wpuser \
    -e WORDPRESS_DB_PASSWORD=wppass \
    -e WORDPRESS_DB_NAME=wordpress \
    -v wordpress-files:/var/www/html:Z \
    wordpress:latest

echo "WordPress available at http://localhost:8080"
```

### Microservices with Service Discovery

```yaml
# microservices.yaml
apiVersion: v1
kind: Pod
metadata:
  name: microservices
spec:
  containers:
  - name: api-gateway
    image: nginx:alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: nginx-config
      mountPath: /etc/nginx/conf.d
  - name: auth-service
    image: node:18-alpine
    command: ["node", "auth-server.js"]
    ports:
    - containerPort: 3001
  - name: data-service
    image: python:3.11-slim
    command: ["python", "-m", "http.server", "3002"]
    ports:
    - containerPort: 3002
  - name: cache
    image: redis:alpine
    ports:
    - containerPort: 6379
  volumes:
  - name: nginx-config
    hostPath:
      path: ./nginx-conf
```

```bash
# Deploy with Podman
podman play kube microservices.yaml

# Check pod status
podman pod ps
podman ps --pod
```

## 3. CI/CD Pipeline Examples

### GitLab CI with Buildah

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

variables:
  IMAGE_NAME: ${CI_REGISTRY_IMAGE}
  IMAGE_TAG: ${CI_COMMIT_SHORT_SHA}

build-image:
  stage: build
  image: quay.io/buildah/stable:latest
  script:
    - buildah bud --layers -t ${IMAGE_NAME}:${IMAGE_TAG} .
    - buildah push ${IMAGE_NAME}:${IMAGE_TAG}
  only:
    - main
    - develop

test-image:
  stage: test
  image: ${IMAGE_NAME}:${IMAGE_TAG}
  script:
    - pytest tests/
    - flake8 src/
    - mypy src/
  dependencies:
    - build-image

deploy-production:
  stage: deploy
  image: quay.io/skopeo/stable:latest
  script:
    - skopeo copy 
        docker://${IMAGE_NAME}:${IMAGE_TAG}
        docker://prod.registry.com/${IMAGE_NAME}:latest
  only:
    - main
```

### GitHub Actions with Multi-arch Build

```yaml
# .github/workflows/build.yml
name: Build and Push Container

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install qemu
        run: |
          sudo apt-get update
          sudo apt-get install -y qemu-user-static
      
      - name: Build multi-arch image
        run: |
          buildah bud \
            --platform linux/amd64,linux/arm64,linux/arm/v7 \
            --manifest ${GITHUB_REPOSITORY}:latest \
            .
      
      - name: Push to registry
        run: |
          buildah push \
            --creds ${GITHUB_ACTOR}:${{ secrets.GITHUB_TOKEN }} \
            ${GITHUB_REPOSITORY}:latest \
            docker://ghcr.io/${GITHUB_REPOSITORY}:latest
```

## 4. Production Deployment Patterns

### Blue-Green Deployment

```bash
#!/bin/bash
# blue-green-deploy.sh

REGISTRY="registry.example.com"
APP_NAME="myapp"
NEW_VERSION=$1

# Deploy green environment
echo "Deploying green environment with version ${NEW_VERSION}..."
podman run -d \
    --name ${APP_NAME}-green \
    --label environment=green \
    --label version=${NEW_VERSION} \
    -p 8081:80 \
    ${REGISTRY}/${APP_NAME}:${NEW_VERSION}

# Health check
echo "Running health checks..."
for i in {1..30}; do
    if curl -f http://localhost:8081/health; then
        echo "Green environment healthy"
        break
    fi
    sleep 2
done

# Switch traffic
echo "Switching traffic to green..."
podman stop ${APP_NAME}-blue
podman rm ${APP_NAME}-blue
podman rename ${APP_NAME}-green ${APP_NAME}-blue

# Update load balancer
podman run -d \
    --name nginx-lb \
    --rm \
    -v ./nginx-green.conf:/etc/nginx/nginx.conf:ro \
    -p 80:80 \
    nginx:alpine

echo "Deployment complete"
```

### Canary Deployment with Traffic Splitting

```nginx
# nginx-canary.conf
upstream backend {
    # 90% traffic to stable
    server stable-app:80 weight=9;
    # 10% traffic to canary
    server canary-app:80 weight=1;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}
```

```bash
#!/bin/bash
# canary-deploy.sh

# Deploy canary
podman run -d \
    --name app-canary \
    --network app-network \
    registry.example.com/app:canary

# Update nginx config
podman exec nginx-lb nginx -s reload

# Monitor metrics
podman stats --no-stream app-canary app-stable
```

## 5. Database Containers

### PostgreSQL with Persistent Storage

```bash
#!/bin/bash
# postgres-setup.sh

# Create volume
podman volume create postgres-data

# Run PostgreSQL
podman run -d \
    --name postgres \
    -e POSTGRES_PASSWORD=secretpass \
    -e POSTGRES_USER=appuser \
    -e POSTGRES_DB=appdb \
    -v postgres-data:/var/lib/postgresql/data:Z \
    -p 5432:5432 \
    --health-cmd='pg_isready -U appuser' \
    --health-interval=10s \
    --health-retries=5 \
    --health-start-period=30s \
    postgres:15-alpine

# Create backup script
cat > backup-postgres.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
podman exec postgres pg_dump -U appuser appdb | gzip > backup_${DATE}.sql.gz
EOF

chmod +x backup-postgres.sh
```

### MongoDB Replica Set

```bash
#!/bin/bash
# mongodb-replica.sh

# Create network
podman network create mongo-network

# Start MongoDB instances
for i in 1 2 3; do
    podman run -d \
        --name mongo${i} \
        --network mongo-network \
        -v mongo${i}-data:/data/db:Z \
        mongo:latest \
        --replSet rs0
done

# Initialize replica set
sleep 5
podman exec mongo1 mongosh --eval "
rs.initiate({
    _id: 'rs0',
    members: [
        {_id: 0, host: 'mongo1:27017'},
        {_id: 1, host: 'mongo2:27017'},
        {_id: 2, host: 'mongo3:27017'}
    ]
})"
```

## 6. Security-Focused Containers

### Minimal Distroless Application

```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o server

# Runtime stage - distroless
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/server /
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### Rootless Container with Limited Capabilities

```bash
#!/bin/bash
# secure-container.sh

# Run with minimal capabilities
podman run -d \
    --name secure-app \
    --cap-drop=all \
    --cap-add=NET_BIND_SERVICE \
    --read-only \
    --tmpfs /tmp:noexec,nosuid,size=100M \
    --security-opt=no-new-privileges \
    --user 1000:1000 \
    --network none \
    myapp:latest
```

### SELinux-Enforced Container

```bash
# Run with custom SELinux context
podman run -d \
    --name selinux-app \
    --security-opt label=type:container_runtime_t \
    --security-opt label=level:s0:c100,c200 \
    -v /data:/data:Z \
    myapp:latest

# Verify SELinux context
podman inspect selinux-app | grep -A5 "SecurityOpt"
ps -eZ | grep container_runtime_t
```

## 7. Monitoring & Logging

### Prometheus + Grafana Stack

```yaml
# monitoring-stack.yaml
version: '3'
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus:Z
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    volumes:
      - grafana-data:/var/lib/grafana:Z
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"

volumes:
  prometheus-data:
  grafana-data:
```

### Centralized Logging with Fluentd

```dockerfile
# Dockerfile.fluentd
FROM fluent/fluentd:latest
USER root
RUN gem install fluent-plugin-elasticsearch
USER fluent
COPY fluent.conf /fluentd/etc/
```

```conf
# fluent.conf
<source>
  @type forward
  port 24224
</source>

<match **>
  @type elasticsearch
  host elasticsearch
  port 9200
  logstash_format true
</match>
```

## 8. Testing Containers

### Integration Testing Setup

```bash
#!/bin/bash
# integration-test.sh

# Start test database
podman run -d \
    --name test-db \
    -e POSTGRES_PASSWORD=test \
    postgres:15-alpine

# Wait for database
until podman exec test-db pg_isready; do
    sleep 1
done

# Run application tests
podman run --rm \
    --link test-db:database \
    -e DATABASE_URL="postgresql://postgres:test@database/test" \
    myapp:latest \
    pytest tests/integration/

# Cleanup
podman stop test-db
podman rm test-db
```

### Load Testing with k6

```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
    stages: [
        { duration: '30s', target: 100 },
        { duration: '1m', target: 100 },
        { duration: '30s', target: 0 },
    ],
};

export default function() {
    let response = http.get('http://app:8080/api/endpoint');
    check(response, {
        'status is 200': (r) => r.status === 200,
        'response time < 500ms': (r) => r.timings.duration < 500,
    });
    sleep(1);
}
```

```bash
# Run load test
podman run --rm \
    --network container:app \
    -v $(pwd)/load-test.js:/test.js:ro \
    grafana/k6 run /test.js
```

## 9. Air-Gapped Deployment

```bash
#!/bin/bash
# airgap-export.sh

IMAGES=(
    "nginx:alpine"
    "postgres:15"
    "redis:7"
    "python:3.11-slim"
)

# Export images
for image in "${IMAGES[@]}"; do
    echo "Exporting ${image}..."
    skopeo copy \
        docker://docker.io/${image} \
        oci-archive:$(echo $image | tr ':/' '_').tar
done

# Create bundle
tar czf container-bundle.tar.gz *.tar
```

```bash
#!/bin/bash
# airgap-import.sh

# Extract bundle
tar xzf container-bundle.tar.gz

# Import to local registry
for archive in *.tar; do
    image_name=$(echo $archive | sed 's/.tar$//' | tr '_' ':')
    echo "Importing ${image_name}..."
    skopeo copy \
        oci-archive:${archive} \
        docker://local-registry:5000/${image_name}
done
```

## 10. Container Debugging

### Debug Container with Tools

```dockerfile
# Dockerfile.debug
FROM alpine:latest
RUN apk add --no-cache \
    curl \
    wget \
    netcat-openbsd \
    bind-tools \
    tcpdump \
    strace \
    htop \
    vim \
    jq
CMD ["/bin/sh"]
```

```bash
# Attach to running container's network
podman run -it --rm \
    --network container:target-container \
    --pid container:target-container \
    --cap-add SYS_PTRACE \
    debug-tools:latest

# Inside debug container
strace -p 1
tcpdump -i eth0
netstat -tulpn
```

### Memory Profiling

```bash
#!/bin/bash
# memory-profile.sh

CONTAINER=$1

# Get container PID
PID=$(podman inspect -f '{{.State.Pid}}' $CONTAINER)

# Create memory dump
podman exec $CONTAINER cat /proc/$PID/smaps > smaps_dump.txt

# Analyze with custom script
awk '/Rss:/{sum+=$2} END {print "RSS: " sum/1024 " MB"}' smaps_dump.txt

# Monitor in real-time
podman stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $CONTAINER
```

## 11. Automated Updates

```bash
#!/bin/bash
# auto-update.sh

# Label containers for auto-update
podman run -d \
    --name web \
    --label io.containers.autoupdate=registry \
    nginx:latest

# Create systemd timer
cat > ~/.config/systemd/user/podman-auto-update.timer << EOF
[Unit]
Description=Podman auto-update timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user enable --now podman-auto-update.timer
```

## 12. GPU-Accelerated Containers

```bash
#!/bin/bash
# gpu-container.sh

# NVIDIA GPU
podman run --rm \
    --device nvidia.com/gpu=all \
    --security-opt=label=disable \
    nvidia/cuda:11.8.0-base-ubuntu22.04 \
    nvidia-smi

# AMD GPU
podman run --rm \
    --device=/dev/kfd \
    --device=/dev/dri \
    --security-opt=label=disable \
    rocm/tensorflow:latest \
    python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

These practical examples demonstrate real-world usage of container tools for various scenarios including development, deployment, testing, and operations.