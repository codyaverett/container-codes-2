#!/usr/bin/env python3
"""
YouTube Comment Scraper CLI Tool
Command-line interface for scraping YouTube comments using the official YouTube Data API v3

Part of the ContainerCodes project for analyzing audience engagement and feedback.
"""

import os
import sys
import argparse
from pathlib import Path
from typing import Optional

# Add the src directory to the path so we can import our module
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

try:
    from app.youtube_scraper import YouTubeCommentScraper, get_comments_batch
except ImportError as e:
    print(f"Error importing YouTube scraper module: {e}")
    print("Make sure you're running from the project root and have installed dependencies.")
    sys.exit(1)


def setup_api_key() -> Optional[str]:
    """
    Interactive setup for YouTube API key if not already configured.
    
    Returns:
        API key string or None if setup cancelled
    """
    api_key = os.environ.get('YOUTUBE_API_KEY')
    
    if not api_key:
        print("\n🔑 YouTube Data API v3 Setup Required")
        print("=" * 50)
        print("To use this tool, you need a YouTube Data API v3 key.")
        print("\nSteps to get an API key:")
        print("1. Go to https://console.cloud.google.com/")
        print("2. Create a new project or select existing one")
        print("3. Enable the YouTube Data API v3")
        print("4. Create credentials (API key)")
        print("5. Set the YOUTUBE_API_KEY environment variable")
        print("\nExample:")
        print("export YOUTUBE_API_KEY='your_api_key_here'")
        print("# Add to ~/.bashrc or ~/.zshrc to persist")
        
        response = input("\nDo you want to enter your API key now? (y/N): ").lower()
        if response in ['y', 'yes']:
            api_key = input("Enter your YouTube API key: ").strip()
            if api_key:
                print("\n✅ API key set for this session.")
                print("Consider adding it to your environment variables for future use.")
                return api_key
        
        print("\n❌ Cannot proceed without API key.")
        return None
    
    return api_key


def validate_output_file(file_path: str, format_type: str) -> str:
    """
    Validate and ensure output file has correct extension, uses snake_case, and is in tmp directory.
    
    Args:
        file_path: Requested output file path
        format_type: Output format (json, csv, markdown)
        
    Returns:
        Validated file path with correct extension, snake_case filename, and tmp directory
    """
    import re
    
    path = Path(file_path)
    
    # If no directory specified, use tmp directory
    if len(path.parts) == 1:  # Just filename, no directory
        tmp_dir = Path("tmp")
        tmp_dir.mkdir(exist_ok=True)
        path = tmp_dir / path.name
        print(f"📁 Output will be saved to tmp directory: tmp/{path.name}")
    
    # Convert filename to snake_case (preserve directory structure)
    filename = path.stem
    if ' ' in filename or not filename.islower():
        print(f"Converting filename to snake_case: '{filename}' -> ", end="")
        # Convert to snake_case
        snake_case_name = re.sub(r'[^\w\-_]', '_', filename.lower())
        snake_case_name = re.sub(r'_+', '_', snake_case_name)  # Replace multiple underscores
        snake_case_name = snake_case_name.strip('_')  # Remove leading/trailing underscores
        print(f"'{snake_case_name}'")
        path = path.parent / snake_case_name
    
    # Add extension if missing
    expected_ext = f".{format_type}" if format_type != 'markdown' else '.md'
    if not path.suffix:
        path = path.with_suffix(expected_ext)
    elif path.suffix != expected_ext:
        print(f"Warning: File extension '{path.suffix}' doesn't match format '{format_type}'")
        print(f"Expected extension: '{expected_ext}'")
        
        response = input("Continue anyway? (y/N): ").lower()
        if response not in ['y', 'yes']:
            sys.exit(1)
    
    # Create parent directories if they don't exist
    path.parent.mkdir(parents=True, exist_ok=True)
    
    return str(path)


def print_video_summary(video_info: dict) -> None:
    """Print a summary of the video information."""
    print(f"\n📺 Video Information")
    print("=" * 50)
    print(f"Title: {video_info['title']}")
    print(f"Channel: {video_info['channel']}")
    print(f"Published: {video_info['published_at']}")
    print(f"Views: {video_info['view_count']:,}")
    print(f"Likes: {video_info['like_count']:,}")
    print(f"Comments: {video_info['comment_count']:,}")


def print_comment_summary(comments: list) -> None:
    """Print a summary of scraped comments."""
    if not comments:
        print("\n❌ No comments found or comments are disabled for this video.")
        return
    
    total_comments = len(comments)
    replies = len([c for c in comments if c.get('is_reply', False)])
    top_level = total_comments - replies
    
    # Calculate engagement metrics
    total_likes = sum(c['like_count'] for c in comments)
    avg_likes = total_likes / total_comments if total_comments > 0 else 0
    
    # Find most liked comment
    most_liked = max(comments, key=lambda c: c['like_count'])
    
    print(f"\n💬 Comment Summary")
    print("=" * 50)
    print(f"Total comments scraped: {total_comments:,}")
    print(f"Top-level comments: {top_level:,}")
    print(f"Replies: {replies:,}")
    print(f"Total likes on scraped comments: {total_likes:,}")
    print(f"Average likes per comment: {avg_likes:.1f}")
    print(f"\nMost liked comment ({most_liked['like_count']} likes):")
    print(f"By: {most_liked['author']}")
    print(f"Text: {most_liked['text'][:100]}{'...' if len(most_liked['text']) > 100 else ''}")


def main():
    """Main CLI interface."""
    parser = argparse.ArgumentParser(
        description="YouTube Comment Scraper - Extract comments from YouTube videos using the official API",
        epilog="Examples:\n"
               "  %(prog)s https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
               "  %(prog)s dQw4w9WgXcQ --max-comments 100 --format csv\n"
               "  %(prog)s https://youtu.be/dQw4w9WgXcQ --output comments.json\n"
               "  %(prog)s video_id --order relevance --format markdown",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    # Required arguments
    parser.add_argument("video", 
                       help="YouTube video URL or video ID")
    
    # Optional arguments
    parser.add_argument("--max-comments", "-n", type=int, default=None,
                       help="Maximum number of comments to retrieve (default: all)")
    
    parser.add_argument("--format", "-f", choices=['json', 'csv', 'markdown'], 
                       default='json', help="Output format (default: json)")
    
    parser.add_argument("--output", "-o", type=str, default=None,
                       help="Output file path (auto-generated if not specified)")
    
    parser.add_argument("--order", choices=['time', 'relevance'], default='time',
                       help="Comment ordering (default: time)")
    
    parser.add_argument("--api-key", type=str, default=None,
                       help="YouTube Data API v3 key (or set YOUTUBE_API_KEY env var)")
    
    parser.add_argument("--quiet", "-q", action="store_true",
                       help="Suppress progress output")
    
    parser.add_argument("--no-export", action="store_true",
                       help="Don't export to file, just display summary")
    
    parser.add_argument("--no-insights", action="store_true",
                       help="Skip generating detailed comment insights analysis")
    
    parser.add_argument("--setup", action="store_true",
                       help="Interactive API key setup")
    
    args = parser.parse_args()
    
    # Handle setup mode
    if args.setup:
        setup_api_key()
        return
    
    # Setup API key
    api_key = args.api_key or setup_api_key()
    if not api_key:
        sys.exit(1)
    
    try:
        if not args.quiet:
            print(f"🚀 Starting YouTube comment scraper...")
            print(f"Video: {args.video}")
            if args.max_comments:
                print(f"Max comments: {args.max_comments:,}")
            print(f"Order: {args.order}")
            print(f"Format: {args.format}")
        
        # Determine output file if needed
        output_file = None
        if not args.no_export:
            if args.output:
                output_file = validate_output_file(args.output, args.format)
            else:
                # Auto-generate filename - this will be done in get_comments_batch
                pass
        
        # Scrape comments
        if not args.quiet:
            print(f"\n⏳ Fetching video information and comments...")
        
        # Prepare command information for output headers
        import sys
        command_info = {
            'original_command': ' '.join(sys.argv),
            'max_comments': args.max_comments,
            'format': args.format,
            'order': args.order,
            'insights_enabled': not args.no_insights,
            'export_enabled': not args.no_export
        }
        
        comments, video_info = get_comments_batch(
            video_url=args.video,
            max_comments=args.max_comments,
            output_format=args.format if not args.no_export else None,
            output_file=output_file,
            api_key=api_key,
            show_insights=not args.no_insights,
            command_info=command_info
        )
        
        # Display results
        if not args.quiet:
            print_video_summary(video_info)
            # If insights disabled, show basic summary
            if args.no_insights:
                print_comment_summary(comments)
        
        if not args.no_export and not args.quiet:
            print(f"\n✅ Successfully scraped and exported comments!")
        elif args.no_export:
            print(f"\n✅ Successfully scraped {len(comments)} comments!")
            
    except KeyboardInterrupt:
        print(f"\n⚠️  Operation cancelled by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        if not args.quiet:
            print("\nTroubleshooting tips:")
            print("- Verify the video URL or ID is correct")
            print("- Check that your API key is valid and has quota remaining")
            print("- Ensure the video has comments enabled")
            print("- Try reducing the number of comments with --max-comments")
        sys.exit(1)


if __name__ == "__main__":
    main()