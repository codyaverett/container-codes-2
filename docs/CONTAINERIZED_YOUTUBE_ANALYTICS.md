# Containerized YouTube Analytics System

Complete container-based solution for YouTube content analysis using security best practices and environment variable management.

## 🎯 Overview

This system provides secure, containerized YouTube analytics tools that demonstrate container security best practices while enabling comprehensive video content analysis for the ContainerCodes channel.

### Key Features

✅ **Secure by Default**: Rootless containers, read-only filesystems, minimal privileges  
✅ **Environment Variable Management**: Secure API key handling  
✅ **Multi-format Support**: Comments, captions, AI analysis  
✅ **Container Best Practices**: Multi-stage builds, health checks, proper user management  
✅ **Multiple Interfaces**: Makefile targets, shell scripts, compose services  

## 🔧 Quick Start

### Prerequisites

```bash
# Container runtime (Podman recommended, Docker supported)
podman --version  # or docker --version

# API Keys (set as environment variables)
export YOUTUBE_API_KEY="your_youtube_api_key"        # For comment scraping
export ANTHROPIC_API_KEY="your_anthropic_api_key"    # For AI analysis
```

### Basic Usage

```bash
# Build the container image
make youtube-build

# Complete analysis (comments + captions + AI)
make youtube-complete URL="https://www.youtube.com/watch?v=VIDEO_ID"

# Individual operations
make youtube-comments URL="VIDEO_ID" MAX=100
make youtube-captions URL="VIDEO_ID" LANG=en
make youtube-analyze FILE="tmp/comments.json"

# Interactive container shell
make youtube-shell
```

## 🏗️ Architecture

### Container Security Features

```dockerfile
# Multi-stage build for minimal attack surface
FROM python:3.11-slim AS builder
# ... build dependencies ...

FROM python:3.11-slim AS production
# Non-root user
RUN groupadd -r analytics && useradd -r -g analytics analytics

# Security hardening
USER analytics
# Read-only filesystem with specific writable areas
# Dropped capabilities (principle of least privilege)
# No new privileges allowed
```

### Directory Structure

```
containers/app/
├── Dockerfile              # Multi-stage container build
src/app/
├── youtube_scraper.py       # Enhanced comment scraper
├── youtube_caption_downloader.py  # Caption download & analysis
└── ai_comment_analyzer.py   # AI-powered analysis
scripts/
├── run-youtube-analytics.sh # Container wrapper script
└── youtube-content-scraper.py # Complete analysis tool
compose.yml                  # Container service definitions
```

### Security Model

```yaml
# Container security configuration
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL                      # Drop all Linux capabilities
read_only: true             # Read-only root filesystem
tmpfs:                      # Writable areas only in memory
  - /tmp:rw,nosuid,nodev,noexec,relatime
  - /app/tmp:rw,nosuid,nodev,noexec,relatime
```

## 📋 Available Commands

### Makefile Targets

| Command | Description | Example |
|---------|-------------|---------|
| `youtube-build` | Build container image | `make youtube-build` |
| `youtube-complete` | Full analysis (comments + captions + AI) | `make youtube-complete URL="VIDEO_ID"` |
| `youtube-comments` | Scrape comments only | `make youtube-comments URL="VIDEO_ID" MAX=100` |
| `youtube-captions` | Download captions only | `make youtube-captions URL="VIDEO_ID" LANG=es` |
| `youtube-analyze` | AI analysis of existing comments | `make youtube-analyze FILE="comments.json"` |
| `youtube-shell` | Interactive container shell | `make youtube-shell` |

### Shell Script Interface

```bash
# Direct script usage with more control
./scripts/run-youtube-analytics.sh [OPTIONS] COMMAND [ARGS...]

# Available commands:
./scripts/run-youtube-analytics.sh complete VIDEO_ID
./scripts/run-youtube-analytics.sh comments VIDEO_ID --max-comments 100
./scripts/run-youtube-analytics.sh captions VIDEO_ID en json
./scripts/run-youtube-analytics.sh analyze comments.json
./scripts/run-youtube-analytics.sh shell  # Interactive mode
```

### Container Runtime Options

```bash
# Use specific container engine
CONTAINER_ENGINE=podman ./scripts/run-youtube-analytics.sh complete VIDEO_ID
CONTAINER_ENGINE=docker ./scripts/run-youtube-analytics.sh complete VIDEO_ID

# Force rebuild before running
./scripts/run-youtube-analytics.sh --build complete VIDEO_ID
```

## 🔒 Security Best Practices

### Environment Variable Security

```bash
# ✅ Secure: Environment variables
export YOUTUBE_API_KEY="your_key_here"
export ANTHROPIC_API_KEY="your_key_here"

# ✅ Secure: Using .env file (not committed to git)
echo "YOUTUBE_API_KEY=your_key" >> .env
echo "ANTHROPIC_API_KEY=your_key" >> .env

# ❌ Insecure: Command line arguments (visible in process list)
./script.py --api-key your_key_here  # Don't do this!
```

### Container Security Features

#### Rootless Operation
```bash
# Container runs as non-root user 'analytics'
USER analytics
WORKDIR /app

# User has minimal system permissions
uid=1001(analytics) gid=1001(analytics) groups=1001(analytics)
```

#### Read-only Filesystem
```bash
# Root filesystem is read-only
docker run --read-only ...

# Only specific directories allow writes
tmpfs:
  - /tmp:rw,nosuid,nodev,noexec,relatime
  - /app/tmp:rw,nosuid,nodev,noexec,relatime
```

#### Capability Dropping
```bash
# Drop all Linux capabilities
cap_drop:
  - ALL

# No new privileges can be gained
security_opt:
  - no-new-privileges:true
```

#### Network Security
```bash
# Only allows outbound HTTPS to YouTube and Anthropic APIs
# No inbound network access required
# No exposed ports (CLI tool, not a service)
```

### Data Security

#### Output Directory Isolation
```bash
# Outputs isolated to specific directories
/app/tmp/     # Analysis results
/app/data/    # Persistent data
```

#### API Key Validation
```bash
# Script validates environment variables before container execution
check_environment() {
    case "$command" in
        "comments"|"complete")
            if [[ -z "${YOUTUBE_API_KEY:-}" ]]; then
                print_error "YOUTUBE_API_KEY environment variable is required"
                exit 1
            fi ;;
    esac
}
```

## 📊 Output Management

### File Organization

```
tmp/                                    # Analysis outputs
├── video_title_VIDEO_ID_timestamp/
│   ├── comments.json                   # Raw comment data
│   ├── insights.txt                    # Traditional analysis
│   ├── comments_ai_enhanced.json       # AI analysis results
│   ├── captions/
│   │   ├── captions_VIDEO_ID_en.json   # Caption data
│   │   └── analysis_en.txt             # Caption analysis
│   ├── combined_analysis.txt           # Content-audience alignment
│   └── README.md                       # Analysis overview
```

### Data Formats

#### JSON Output (Structured Data)
```json
{
  "metadata": {
    "exported_at": "2024-01-15T10:30:00",
    "total_comments": 150,
    "video": {
      "id": "VIDEO_ID",
      "title": "Container Security Deep Dive",
      "url": "https://www.youtube.com/watch?v=VIDEO_ID"
    }
  },
  "comments": [...],
  "ai_analysis": {...}
}
```

#### Text Output (Human Readable)
```text
📊 COMMENT ANALYSIS INSIGHTS
==================================================
💬 Total Comments: 150
   ├─ Top-level: 120
   └─ Replies: 30 (20.0%)

🎯 TOP DISCUSSION TOPICS:
   1. security (25 mentions)
   2. containers (18 mentions)
   3. podman (12 mentions)
```

## 🔍 Analysis Capabilities

### Comment Analysis
- **Basic Statistics**: Engagement metrics, reply ratios, active users
- **Topic Extraction**: Key themes and discussion points
- **Question Identification**: FAQ candidate questions
- **Content Requests**: Viewer-requested topics for future videos

### Caption Analysis  
- **Content Topics**: Technical terms and concepts covered
- **Structure Analysis**: Content flow, transitions, speaking patterns
- **Technical Depth**: Assessment of complexity level
- **Duration Metrics**: Speaking rate, content density

### AI-Powered Insights
- **Sentiment Analysis**: Overall audience sentiment distribution
- **Content Categorization**: Automatic comment classification
- **Recommendations**: Data-driven content suggestions
- **Alignment Analysis**: Content-audience interest matching

### Combined Analysis
- **Content-Audience Alignment**: How well video topics match comment interests
- **Engagement Correlation**: Links between content and audience response
- **Optimization Recommendations**: Specific improvement suggestions

## 🚀 Advanced Usage

### Batch Processing
```bash
# Process multiple videos
for video in VIDEO_ID1 VIDEO_ID2 VIDEO_ID3; do
    ./scripts/run-youtube-analytics.sh complete "$video"
done
```

### Custom Analysis Pipeline
```bash
# Step-by-step analysis with custom parameters
./scripts/run-youtube-analytics.sh comments VIDEO_ID --max-comments 500
./scripts/run-youtube-analytics.sh captions VIDEO_ID all json
./scripts/run-youtube-analytics.sh analyze tmp/comments.json

# Custom output directory
./scripts/run-youtube-analytics.sh complete VIDEO_ID --output-dir custom_analysis
```

### Development Mode
```bash
# Interactive container for development
make youtube-shell

# Inside container:
analytics@container:/app$ python scripts/youtube-comment-scraper.py --help
analytics@container:/app$ python src/app/youtube_caption_downloader.py --help
analytics@container:/app$ ls -la tmp/
```

### CI/CD Integration
```yaml
# GitHub Actions example
- name: Analyze YouTube Content
  run: |
    export YOUTUBE_API_KEY="${{ secrets.YOUTUBE_API_KEY }}"
    export ANTHROPIC_API_KEY="${{ secrets.ANTHROPIC_API_KEY }}"
    make youtube-complete URL="${{ github.event.inputs.video_url }}"
    
- name: Archive Analysis Results
  uses: actions/upload-artifact@v3
  with:
    name: youtube-analysis
    path: tmp/
```

## 🛠️ Troubleshooting

### Container Issues

#### Build Failures
```bash
# Check Docker/Podman is running
podman info  # or docker info

# Clean build (remove cached layers)
./scripts/run-youtube-analytics.sh --build complete VIDEO_ID

# Manual build for debugging
podman build -t youtube-analytics -f containers/app/Dockerfile .
```

#### Permission Issues
```bash
# Ensure output directories exist and are writable
mkdir -p tmp data
chmod 755 tmp data

# Check container user permissions
./scripts/run-youtube-analytics.sh shell
# Inside container: id -u -n  # Should show 'analytics'
```

### API Issues

#### YouTube API Problems
```bash
# Test API key
curl -s "https://www.googleapis.com/youtube/v3/videos?id=dQw4w9WgXcQ&key=$YOUTUBE_API_KEY&part=snippet"

# Common issues:
# - API key not set: export YOUTUBE_API_KEY="your_key"
# - Quota exceeded: Check Google Cloud Console
# - Wrong permissions: Enable YouTube Data API v3
```

#### Anthropic API Problems  
```bash
# Test API key
curl -s -H "x-api-key: $ANTHROPIC_API_KEY" https://api.anthropic.com/v1/messages

# Common issues:
# - API key not set: export ANTHROPIC_API_KEY="your_key"  
# - Insufficient credits: Check Anthropic Console
# - Rate limiting: Tool includes automatic retry logic
```

### Analysis Issues

#### No Comments Found
```bash
# Check video has comments enabled
# Try different video URL formats:
./scripts/run-youtube-analytics.sh comments "https://www.youtube.com/watch?v=VIDEO_ID"
./scripts/run-youtube-analytics.sh comments "https://youtu.be/VIDEO_ID" 
./scripts/run-youtube-analytics.sh comments "VIDEO_ID"
```

#### No Captions Available
```bash
# Check available languages first
./scripts/run-youtube-analytics.sh shell
# Inside container:
python src/app/youtube_caption_downloader.py VIDEO_ID
# This will show available caption languages
```

## 🎓 Educational Value

### Container Security Demonstration

This system serves as a practical example of:

1. **Multi-stage Docker builds** for minimal attack surface
2. **Rootless container execution** for reduced privilege escalation risk
3. **Read-only filesystems** with controlled writable areas
4. **Capability dropping** and security option hardening
5. **Environment variable management** for secure credential handling
6. **Container composition** with docker-compose best practices

### Security Learning Outcomes

After using this system, users understand:

- How to implement defense-in-depth for containerized applications
- Proper separation of build-time and runtime environments
- Secure credential management in container workflows  
- File system isolation and permission management
- Network security boundaries for containerized tools
- Monitoring and health checking for container applications

## 📚 Integration with ContainerCodes Content

### Content Creation Workflow

```bash
# 1. Record and publish video
# 2. Analyze audience response
make youtube-complete URL="NEW_EPISODE_URL"

# 3. Review analysis results
cat tmp/*/README.md
cat tmp/*/combined_analysis.txt

# 4. Plan next episode based on insights
# 5. Update content strategy
```

### Educational Content Topics

This system demonstrates concepts suitable for ContainerCodes episodes:

- **Container Security Best Practices** (rootless, read-only, capabilities)
- **Environment Variable Security** (avoiding credential exposure)
- **Multi-stage Docker Builds** (optimizing images, reducing attack surface)
- **Container Composition** (docker-compose, service orchestration)
- **Python Application Containerization** (dependency management, virtual environments)
- **Data Volume Management** (persistent storage, temporary filesystems)
- **Container Health Monitoring** (health checks, logging, debugging)

## 🔄 Continuous Improvement

### Monitoring Usage

```bash
# Container resource usage
podman stats youtube-analytics

# Analysis output quality
ls -la tmp/*/
wc -l tmp/*/insights.txt
du -h tmp/*
```

### Performance Optimization

```bash
# Image size optimization
podman images youtube-analytics

# Build cache utilization
podman build --no-cache -t youtube-analytics -f containers/app/Dockerfile .

# Runtime performance
time make youtube-complete URL="VIDEO_ID"
```

### Security Auditing

```bash
# Container security scan
podman run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  quay.io/coreos/clair:latest analyze youtube-analytics

# Dependency vulnerability check
pip-audit -r requirements.txt

# Dockerfile best practices
hadolint containers/app/Dockerfile
```

---

This containerized system provides a secure, scalable foundation for YouTube analytics while serving as an excellent educational example of container security best practices for the ContainerCodes audience.