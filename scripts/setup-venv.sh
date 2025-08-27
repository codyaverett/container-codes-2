#!/bin/bash
# Virtual Environment Setup Script for ContainerCodes YouTube Analytics
# Creates and configures a Python virtual environment with all dependencies

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_NAME="$PROJECT_ROOT/.venv"
PYTHON_VERSION="python3.11"
PROJECT_NAME="ContainerCodes YouTube Analytics"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                  ${YELLOW}$PROJECT_NAME Setup${PURPLE}                  ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Python version
check_python() {
    print_status "Checking Python installation..."
    
    # Try to find the best Python version
    if command -v "$PYTHON_VERSION" &> /dev/null; then
        PYTHON_CMD="$PYTHON_VERSION"
    elif command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        print_error "Python not found! Please install Python 3.8 or later."
        exit 1
    fi
    
    # Check Python version
    PYTHON_VERSION_STR=$($PYTHON_CMD --version 2>&1)
    print_success "Found $PYTHON_VERSION_STR"
    
    # Extract major and minor version
    PYTHON_MAJOR=$($PYTHON_CMD -c 'import sys; print(sys.version_info[0])')
    PYTHON_MINOR=$($PYTHON_CMD -c 'import sys; print(sys.version_info[1])')
    
    if [[ "$PYTHON_MAJOR" -lt 3 ]] || [[ "$PYTHON_MAJOR" -eq 3 && "$PYTHON_MINOR" -lt 8 ]]; then
        print_error "Python 3.8 or later is required. Found: $PYTHON_VERSION_STR"
        exit 1
    fi
}

# Create virtual environment
create_venv() {
    print_status "Creating virtual environment..."
    
    # Remove existing venv if requested
    if [[ -d "$VENV_NAME" ]]; then
        if [[ "${FORCE:-}" == "true" ]]; then
            print_warning "Removing existing virtual environment..."
            rm -rf "$VENV_NAME"
        else
            print_warning "Virtual environment already exists at $VENV_NAME"
            read -p "Do you want to recreate it? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$VENV_NAME"
            else
                print_status "Using existing virtual environment"
                return
            fi
        fi
    fi
    
    # Create new virtual environment
    $PYTHON_CMD -m venv "$VENV_NAME" --prompt "youtube-analytics"
    print_success "Virtual environment created at $VENV_NAME"
}

# Upgrade pip and setuptools
upgrade_pip() {
    print_status "Upgrading pip and setuptools..."
    
    # Activate virtual environment for this subshell
    source "$VENV_NAME/bin/activate"
    
    pip install --quiet --upgrade pip setuptools wheel
    print_success "pip upgraded to $(pip --version | cut -d' ' -f2)"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Activate virtual environment for this subshell
    source "$VENV_NAME/bin/activate"
    
    # Install from requirements.txt
    if [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
        print_status "Installing from requirements.txt..."
        pip install --quiet -r "$PROJECT_ROOT/requirements.txt"
        print_success "Core dependencies installed"
    else
        print_warning "requirements.txt not found at $PROJECT_ROOT"
    fi
    
    # Install optional development dependencies
    if [[ "${DEV:-}" == "true" ]]; then
        print_status "Installing development dependencies..."
        pip install --quiet black isort flake8 mypy pytest pytest-cov pip-audit
        print_success "Development dependencies installed"
    fi
    
    # Install optional data analysis dependencies
    if [[ "${EXTRAS:-}" == "true" ]]; then
        print_status "Installing extra analysis dependencies..."
        pip install --quiet pandas matplotlib seaborn wordcloud jupyter
        print_success "Extra analysis dependencies installed"
    fi
}

# Create activation scripts
create_activation_scripts() {
    print_status "Creating activation helper scripts..."
    
    # Create activate.sh for easy activation
    cat > "$SCRIPT_DIR/activate.sh" << 'EOF'
#!/bin/bash
# Quick activation script for YouTube Analytics virtual environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_NAME="$PROJECT_ROOT/.venv"

if [[ -z "${VIRTUAL_ENV}" ]]; then
    if [[ -f "$VENV_NAME/bin/activate" ]]; then
        source "$VENV_NAME/bin/activate"
        echo "✓ Virtual environment activated"
        echo "Python: $(which python)"
        echo "Version: $(python --version)"
        echo ""
        echo "Available commands:"
        echo "  python scripts/youtube-comment-scraper.py"
        echo "  python scripts/youtube-content-scraper.py"
        echo "  python src/app/youtube_caption_downloader.py"
        echo "  python src/app/ai_comment_analyzer.py"
        echo ""
        echo "Type 'deactivate' to exit the virtual environment"
    else
        echo "❌ Virtual environment not found!"
        echo "Run 'scripts/setup-venv.sh' first to create it"
    fi
else
    echo "Virtual environment is already activated: $VIRTUAL_ENV"
fi
EOF
    chmod +x "$SCRIPT_DIR/activate.sh"
    
    # Create a fish shell activation script if fish is installed
    if command -v fish &> /dev/null; then
        cat > "$SCRIPT_DIR/activate.fish" << 'EOF'
#!/usr/bin/env fish
# Quick activation script for fish shell

set SCRIPT_DIR (dirname (status --current-filename))
set PROJECT_ROOT (dirname $SCRIPT_DIR)
set VENV_NAME "$PROJECT_ROOT/.venv"

if test -z "$VIRTUAL_ENV"
    if test -f "$VENV_NAME/bin/activate.fish"
        source "$VENV_NAME/bin/activate.fish"
        echo "✓ Virtual environment activated"
        echo "Python: "(which python)
        echo "Version: "(python --version)
    else
        echo "❌ Virtual environment not found!"
        echo "Run 'scripts/setup-venv.sh' first to create it"
    end
else
    echo "Virtual environment is already activated: $VIRTUAL_ENV"
end
EOF
        chmod +x "$SCRIPT_DIR/activate.fish"
    fi
    
    # Create envrc for direnv users
    if command -v direnv &> /dev/null; then
        cat > "$PROJECT_ROOT/.envrc" << 'EOF'
# Automatically activate virtual environment with direnv
# Run 'direnv allow' to enable

if [[ -f .venv/bin/activate ]]; then
    source .venv/bin/activate
fi

# Load environment variables from .env if it exists
if [[ -f .env ]]; then
    dotenv
fi
EOF
        print_status "Created .envrc for direnv (run 'direnv allow' to enable)"
    fi
    
    print_success "Activation scripts created"
}

# Create run script for easy command execution
create_run_script() {
    print_status "Creating run helper script..."
    
    cat > "$SCRIPT_DIR/run.py" << 'EOF'
#!/usr/bin/env python3
"""
YouTube Analytics Runner - Interactive CLI for all tools
"""

import os
import sys
import subprocess
from pathlib import Path

# Colors for terminal output
class Colors:
    PURPLE = '\033[0;35m'
    BLUE = '\033[0;34m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'  # No Color

def print_menu():
    """Display interactive menu."""
    print(f"\n{Colors.PURPLE}═══════════════════════════════════════════════════════{Colors.NC}")
    print(f"{Colors.PURPLE}     YouTube Analytics Tools - Interactive Runner      {Colors.NC}")
    print(f"{Colors.PURPLE}═══════════════════════════════════════════════════════{Colors.NC}\n")
    
    print(f"{Colors.BLUE}Available Tools:{Colors.NC}")
    print(f"  {Colors.GREEN}1{Colors.NC} - Scrape YouTube Comments")
    print(f"  {Colors.GREEN}2{Colors.NC} - Download YouTube Captions")
    print(f"  {Colors.GREEN}3{Colors.NC} - AI Comment Analysis")
    print(f"  {Colors.GREEN}4{Colors.NC} - Complete Analysis (Comments + Captions + AI)")
    print(f"  {Colors.GREEN}5{Colors.NC} - View Recent Analysis Results")
    print(f"  {Colors.GREEN}6{Colors.NC} - Environment Setup Check")
    print(f"  {Colors.GREEN}0{Colors.NC} - Exit")
    print()

def check_environment():
    """Check if environment is properly configured."""
    issues = []
    
    # Check virtual environment
    if not sys.prefix.endswith('.venv'):
        issues.append("Virtual environment not activated (run: source activate.sh)")
    
    # Check API keys
    if not os.environ.get('YOUTUBE_API_KEY'):
        issues.append("YOUTUBE_API_KEY not set")
    if not os.environ.get('ANTHROPIC_API_KEY'):
        issues.append("ANTHROPIC_API_KEY not set (optional for AI features)")
    
    # Check dependencies
    try:
        import googleapiclient
    except ImportError:
        issues.append("Google API client not installed")
    
    try:
        import youtube_transcript_api
    except ImportError:
        issues.append("YouTube Transcript API not installed")
    
    try:
        import anthropic
    except ImportError:
        issues.append("Anthropic SDK not installed (optional)")
    
    if issues:
        print(f"{Colors.YELLOW}Environment Issues Found:{Colors.NC}")
        for issue in issues:
            print(f"  {Colors.RED}⚠{Colors.NC}  {issue}")
    else:
        print(f"{Colors.GREEN}✓ Environment is properly configured!{Colors.NC}")
    
    return len(issues) == 0

def run_tool(tool_num):
    """Run the selected tool."""
    if tool_num == 1:  # Comments
        video_url = input(f"{Colors.BLUE}Enter YouTube video URL or ID: {Colors.NC}")
        max_comments = input(f"{Colors.BLUE}Max comments (default: 200): {Colors.NC}") or "200"
        cmd = ["python", "scripts/youtube-comment-scraper.py", video_url, 
               "--max-comments", max_comments, "--format", "json"]
        
    elif tool_num == 2:  # Captions
        video_url = input(f"{Colors.BLUE}Enter YouTube video URL or ID: {Colors.NC}")
        language = input(f"{Colors.BLUE}Language code (default: en, or 'all'): {Colors.NC}") or "en"
        cmd = ["python", "src/app/youtube_caption_downloader.py", video_url, language, "json"]
        
    elif tool_num == 3:  # AI Analysis
        file_path = input(f"{Colors.BLUE}Enter path to comments JSON file: {Colors.NC}")
        if not Path(file_path).exists():
            print(f"{Colors.RED}File not found: {file_path}{Colors.NC}")
            return
        cmd = ["python", "src/app/ai_comment_analyzer.py", file_path]
        
    elif tool_num == 4:  # Complete Analysis
        video_url = input(f"{Colors.BLUE}Enter YouTube video URL or ID: {Colors.NC}")
        max_comments = input(f"{Colors.BLUE}Max comments (default: 200): {Colors.NC}") or "200"
        caption_lang = input(f"{Colors.BLUE}Caption language (default: en): {Colors.NC}") or "en"
        cmd = ["python", "scripts/youtube-content-scraper.py", video_url,
               "--max-comments", max_comments, "--caption-lang", caption_lang]
        
    elif tool_num == 5:  # View Results
        tmp_dir = Path("tmp")
        if not tmp_dir.exists():
            print(f"{Colors.YELLOW}No analysis results found in tmp/{Colors.NC}")
            return
        
        # List recent analysis directories
        dirs = sorted([d for d in tmp_dir.iterdir() if d.is_dir()], 
                     key=lambda x: x.stat().st_mtime, reverse=True)[:10]
        
        if not dirs:
            print(f"{Colors.YELLOW}No analysis directories found{Colors.NC}")
            return
            
        print(f"\n{Colors.BLUE}Recent Analysis Results:{Colors.NC}")
        for i, d in enumerate(dirs, 1):
            print(f"  {i}. {d.name}")
        
        choice = input(f"\n{Colors.BLUE}Select directory to explore (1-{len(dirs)}): {Colors.NC}")
        try:
            selected = dirs[int(choice) - 1]
            print(f"\n{Colors.GREEN}Contents of {selected}:{Colors.NC}")
            for file in sorted(selected.iterdir()):
                print(f"  - {file.name}")
            
            # Offer to open README
            readme = selected / "README.md"
            if readme.exists():
                if input(f"\n{Colors.BLUE}View README? (y/N): {Colors.NC}").lower() == 'y':
                    print(readme.read_text())
        except (ValueError, IndexError):
            print(f"{Colors.RED}Invalid selection{Colors.NC}")
        return
        
    elif tool_num == 6:  # Environment Check
        check_environment()
        return
    
    # Run the command
    print(f"\n{Colors.YELLOW}Running: {' '.join(cmd)}{Colors.NC}\n")
    try:
        result = subprocess.run(cmd, check=True)
        print(f"\n{Colors.GREEN}✓ Command completed successfully!{Colors.NC}")
    except subprocess.CalledProcessError as e:
        print(f"\n{Colors.RED}✗ Command failed with error code {e.returncode}{Colors.NC}")
    except FileNotFoundError:
        print(f"\n{Colors.RED}✗ Command not found. Make sure you're in the project root.{Colors.NC}")

def main():
    """Main interactive loop."""
    # Initial environment check
    if not check_environment():
        print(f"\n{Colors.YELLOW}Some features may not work properly.{Colors.NC}")
        if input(f"{Colors.BLUE}Continue anyway? (y/N): {Colors.NC}").lower() != 'y':
            return
    
    while True:
        print_menu()
        
        try:
            choice = input(f"{Colors.BLUE}Select option (0-6): {Colors.NC}")
            tool_num = int(choice)
            
            if tool_num == 0:
                print(f"{Colors.GREEN}Goodbye!{Colors.NC}")
                break
            elif 1 <= tool_num <= 6:
                run_tool(tool_num)
                input(f"\n{Colors.BLUE}Press Enter to continue...{Colors.NC}")
            else:
                print(f"{Colors.RED}Invalid option. Please select 0-6.{Colors.NC}")
        except ValueError:
            print(f"{Colors.RED}Invalid input. Please enter a number.{Colors.NC}")
        except KeyboardInterrupt:
            print(f"\n{Colors.YELLOW}Interrupted by user{Colors.NC}")
            break

if __name__ == "__main__":
    main()
EOF
    chmod +x "$SCRIPT_DIR/run.py"
    
    print_success "Run helper script created"
}

# Create environment file template
create_env_template() {
    print_status "Creating environment file template..."
    
    if [[ ! -f "$PROJECT_ROOT/.env.example" ]]; then
        cat > "$PROJECT_ROOT/.env.example" << 'EOF'
# YouTube Analytics Environment Variables
# Copy this file to .env and fill in your API keys

# YouTube Data API v3 Key (required for comment scraping)
# Get from: https://console.cloud.google.com/
YOUTUBE_API_KEY=your_youtube_api_key_here

# Anthropic API Key (required for AI analysis features)
# Get from: https://console.anthropic.com/
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Optional: Container runtime preference
CONTAINER_ENGINE=podman  # or docker

# Optional: Default analysis limits
MAX_COMMENTS=200
CAPTION_LANGUAGE=en
EOF
        print_success "Created .env.example template"
    fi
    
    if [[ ! -f "$PROJECT_ROOT/.env" ]]; then
        print_warning "No .env file found. Copy .env.example to .env and add your API keys."
    fi
}

# Display final instructions
show_instructions() {
    echo
    print_header
    print_success "Virtual environment setup complete!"
    
    echo -e "${GREEN}Quick Start:${NC}"
    echo "1. Activate the virtual environment:"
    echo "   ${BLUE}source scripts/activate.sh${NC}"
    echo
    echo "2. Set your API keys:"
    echo "   ${BLUE}export YOUTUBE_API_KEY='your_key'${NC}"
    echo "   ${BLUE}export ANTHROPIC_API_KEY='your_key'${NC}"
    echo "   Or copy .env.example to .env and fill in your keys"
    echo
    echo "3. Run the interactive tool:"
    echo "   ${BLUE}python scripts/run.py${NC}"
    echo
    echo -e "${GREEN}Alternative Usage:${NC}"
    echo "   ${BLUE}python scripts/youtube-comment-scraper.py VIDEO_URL${NC}"
    echo "   ${BLUE}python src/app/youtube_caption_downloader.py VIDEO_URL${NC}"
    echo "   ${BLUE}python scripts/youtube-content-scraper.py VIDEO_URL${NC}"
    echo
    echo -e "${GREEN}Available Scripts:${NC}"
    echo "   • scripts/activate.sh - Quick virtual environment activation"
    echo "   • scripts/run.py - Interactive tool runner"
    echo "   • scripts/setup-venv.sh - This setup script"
    echo
    
    if [[ "${DEV:-}" == "true" ]]; then
        echo -e "${GREEN}Development Tools Installed:${NC}"
        echo "   • black - Code formatting"
        echo "   • isort - Import sorting"
        echo "   • flake8 - Linting"
        echo "   • mypy - Type checking"
        echo "   • pytest - Testing"
        echo "   • pip-audit - Security scanning"
        echo
    fi
}

# Main execution
main() {
    print_header
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --dev)
                DEV=true
                print_status "Development mode enabled"
                ;;
            --extras)
                EXTRAS=true
                print_status "Extra dependencies will be installed"
                ;;
            --force)
                FORCE=true
                print_status "Force mode enabled - will recreate existing venv"
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --dev     Install development dependencies"
                echo "  --extras  Install extra analysis dependencies"
                echo "  --force   Force recreate virtual environment"
                echo "  --help    Show this help message"
                echo
                echo "Examples:"
                echo "  $0                    # Basic setup"
                echo "  $0 --dev              # Include dev tools"
                echo "  $0 --dev --extras     # Everything"
                echo "  $0 --force            # Recreate venv"
                exit 0
                ;;
        esac
    done
    
    check_python
    create_venv
    upgrade_pip
    install_dependencies
    create_activation_scripts
    create_run_script
    create_env_template
    show_instructions
}

# Run main function
main "$@"