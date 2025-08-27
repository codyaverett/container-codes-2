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
