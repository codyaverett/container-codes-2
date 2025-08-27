#!/bin/bash
# Container-based YouTube Analytics Runner
# Secure wrapper script for running YouTube analytics tools in containers

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTAINER_IMAGE="youtube-analytics"
CONTAINER_ENGINE="${CONTAINER_ENGINE:-podman}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
YouTube Analytics Container Runner

USAGE:
    $0 [OPTIONS] COMMAND [ARGS...]

AVAILABLE COMMANDS:
    comments <video_url>              - Scrape comments from a YouTube video
    captions <video_url>              - Download captions from a YouTube video  
    analyze <comments.json>           - Run AI analysis on scraped comments
    complete <video_url>              - Full analysis (comments + captions + AI)
    shell                             - Open interactive shell in container

GLOBAL OPTIONS:
    --engine ENGINE                   - Container engine (podman/docker, default: podman)
    --build                           - Build container image before running
    --help, -h                        - Show this help message

EXAMPLES:
    # Download comments and captions with AI analysis
    $0 complete "https://www.youtube.com/watch?v=VIDEO_ID"
    
    # Just download captions (no API key needed)
    $0 captions "VIDEO_ID" --caption-lang en
    
    # Scrape comments with custom limits  
    $0 comments "VIDEO_ID" --max-comments 100 --format json
    
    # Run AI analysis on existing comment file
    $0 analyze comments.json
    
    # Build image and run complete analysis
    $0 --build complete "VIDEO_ID"

ENVIRONMENT VARIABLES:
    YOUTUBE_API_KEY                   - Required for comment scraping
    ANTHROPIC_API_KEY                 - Required for AI analysis
    CONTAINER_ENGINE                  - Container engine preference (podman/docker)

SECURITY NOTES:
    - Container runs as non-root user
    - Read-only filesystem with limited write access
    - No network privileges beyond API calls
    - API keys passed securely via environment variables
    
EOF
}

# Check if container engine is available
check_container_engine() {
    if ! command -v "$CONTAINER_ENGINE" &> /dev/null; then
        print_error "Container engine '$CONTAINER_ENGINE' not found"
        echo "Please install $CONTAINER_ENGINE or set CONTAINER_ENGINE environment variable"
        exit 1
    fi
    
    # Check if container engine is running (for docker)
    if [[ "$CONTAINER_ENGINE" == "docker" ]]; then
        if ! docker info &> /dev/null; then
            print_error "Docker daemon is not running"
            echo "Please start Docker service"
            exit 1
        fi
    fi
}

# Build container image
build_image() {
    print_status "Building YouTube Analytics container image..."
    
    cd "$PROJECT_ROOT"
    
    if ! $CONTAINER_ENGINE build -t "$CONTAINER_IMAGE" -f containers/app/Dockerfile .; then
        print_error "Failed to build container image"
        exit 1
    fi
    
    print_success "Container image built successfully"
}

# Check if image exists
check_image() {
    if ! $CONTAINER_ENGINE image exists "$CONTAINER_IMAGE" 2>/dev/null; then
        print_warning "Container image '$CONTAINER_IMAGE' not found"
        print_status "Building image automatically..."
        build_image
    fi
}

# Validate environment variables
check_environment() {
    local command="$1"
    
    case "$command" in
        "comments"|"complete")
            if [[ -z "${YOUTUBE_API_KEY:-}" ]]; then
                print_error "YOUTUBE_API_KEY environment variable is required for comment scraping"
                echo "Get your API key from: https://console.cloud.google.com/"
                echo "Then set it with: export YOUTUBE_API_KEY='your_key_here'"
                exit 1
            fi
            ;;
    esac
    
    case "$command" in
        "analyze"|"complete")
            if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
                print_warning "ANTHROPIC_API_KEY not set - AI analysis will be skipped"
                echo "Get your API key from: https://console.anthropic.com/"
                echo "Then set it with: export ANTHROPIC_API_KEY='your_key_here'"
            fi
            ;;
    esac
}

# Run container with security best practices
run_container() {
    local cmd=("$@")
    
    # Ensure output directories exist
    mkdir -p "$PROJECT_ROOT/tmp" "$PROJECT_ROOT/data"
    
    # Build container run command with security options
    local container_args=(
        "run"
        "--rm"
        "--interactive"
        "--tty"
        # Security options
        "--security-opt" "no-new-privileges:true"
        "--cap-drop=ALL"
        "--read-only"
        "--tmpfs" "/tmp:rw,nosuid,nodev,noexec"
        # Volume mounts
        "-v" "$PROJECT_ROOT/tmp:/app/tmp:rw"
        "-v" "$PROJECT_ROOT/data:/app/data:rw"
        "-v" "$PROJECT_ROOT/src:/app/src:ro"
        "-v" "$PROJECT_ROOT/scripts:/app/scripts:ro"
        # Environment variables (only pass if set)
        $(if [[ -n "${YOUTUBE_API_KEY:-}" ]]; then echo "-e YOUTUBE_API_KEY"; fi)
        $(if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then echo "-e ANTHROPIC_API_KEY"; fi)
        # Set working directory
        "-w" "/app"
        # Container image
        "$CONTAINER_IMAGE"
    )
    
    # Add the actual command
    container_args+=("${cmd[@]}")
    
    print_status "Running: $CONTAINER_ENGINE ${container_args[*]}"
    exec $CONTAINER_ENGINE "${container_args[@]}"
}

# Parse global options
SHOULD_BUILD=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --engine)
            CONTAINER_ENGINE="$2"
            shift 2
            ;;
        --build)
            SHOULD_BUILD=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        --*)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Check for command
if [[ $# -eq 0 ]]; then
    print_error "No command specified"
    show_help
    exit 1
fi

COMMAND="$1"
shift

# Validate environment
check_container_engine
check_environment "$COMMAND"

# Build image if requested
if [[ "$SHOULD_BUILD" == "true" ]]; then
    build_image
else
    check_image
fi

# Execute command
case "$COMMAND" in
    "comments")
        if [[ $# -eq 0 ]]; then
            print_error "Video URL/ID required for comments command"
            echo "Usage: $0 comments <video_url> [options]"
            exit 1
        fi
        print_status "Scraping YouTube comments..."
        run_container python scripts/youtube-comment-scraper.py "$@"
        ;;
    
    "captions")
        if [[ $# -eq 0 ]]; then
            print_error "Video URL/ID required for captions command"
            echo "Usage: $0 captions <video_url> [language] [format]"
            exit 1
        fi
        print_status "Downloading YouTube captions..."
        run_container python src/app/youtube_caption_downloader.py "$@"
        ;;
    
    "analyze")
        if [[ $# -eq 0 ]]; then
            print_error "Comments file required for analyze command"
            echo "Usage: $0 analyze <comments.json>"
            exit 1
        fi
        print_status "Running AI analysis on comments..."
        run_container python src/app/ai_comment_analyzer.py "$@"
        ;;
    
    "complete")
        if [[ $# -eq 0 ]]; then
            print_error "Video URL/ID required for complete command"
            echo "Usage: $0 complete <video_url> [options]"
            exit 1
        fi
        print_status "Running complete YouTube content analysis..."
        run_container python scripts/youtube-content-scraper.py "$@"
        ;;
    
    "shell")
        print_status "Opening interactive shell in YouTube Analytics container..."
        run_container bash
        ;;
    
    *)
        print_error "Unknown command: $COMMAND"
        echo ""
        echo "Available commands: comments, captions, analyze, complete, shell"
        echo "Use --help for detailed usage information"
        exit 1
        ;;
esac