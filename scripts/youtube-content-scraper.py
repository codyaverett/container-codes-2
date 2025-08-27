#!/usr/bin/env python3
"""
YouTube Complete Content Scraper CLI Tool
Download both comments and captions from YouTube videos for comprehensive content analysis

Part of the ContainerCodes project for analyzing video content and audience engagement.
"""

import os
import sys
import argparse
from pathlib import Path
from typing import Optional
from datetime import datetime

# Add the src directory to the path so we can import our modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

try:
    from app.youtube_scraper import YouTubeCommentScraper, get_comments_batch
    from app.youtube_caption_downloader import YouTubeCaptionDownloader, download_captions_for_video, CaptionAnalyzer
except ImportError as e:
    print(f"Error importing modules: {e}")
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
        print("To scrape comments, you need a YouTube Data API v3 key.")
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
        
        print("\n❌ Cannot proceed with comment scraping without API key.")
        print("Caption downloading will still work without an API key.")
        return None
    
    return api_key


def create_analysis_directory(video_info: dict) -> Path:
    """Create organized directory structure for analysis output."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Clean title for directory name
    import re
    safe_title = re.sub(r'[^\w\-_]', '_', video_info.get('title', 'unknown').lower())
    safe_title = re.sub(r'_+', '_', safe_title).strip('_')[:40]
    
    video_id = video_info.get('id', 'unknown')
    analysis_dir = Path("tmp") / f"{safe_title}_{video_id}_{timestamp}"
    analysis_dir.mkdir(parents=True, exist_ok=True)
    
    return analysis_dir


def scrape_complete_content(video_url: str, max_comments: Optional[int] = None,
                           caption_language: str = 'en', include_auto_captions: bool = True,
                           api_key: Optional[str] = None, output_dir: Optional[str] = None) -> dict:
    """
    Scrape both comments and captions from a YouTube video.
    
    Args:
        video_url: YouTube video URL or ID
        max_comments: Maximum number of comments to retrieve (None for all)
        caption_language: Language code for captions ('en', 'all' for all available)
        include_auto_captions: Include auto-generated captions
        api_key: YouTube Data API key for comment scraping
        output_dir: Custom output directory
        
    Returns:
        Dictionary with scraping results
    """
    results = {
        'video_url': video_url,
        'timestamp': datetime.now().isoformat(),
        'comments': None,
        'captions': None,
        'video_info': None,
        'analysis_dir': None,
        'errors': []
    }
    
    # Extract video ID and get basic video info
    try:
        scraper = YouTubeCommentScraper(api_key) if api_key else None
        downloader = YouTubeCaptionDownloader()
        
        if scraper:
            video_id = scraper.extract_video_id(video_url)
            video_info = scraper.get_video_info(video_id)
        else:
            video_id = downloader.extract_video_id(video_url)
            video_info = {'id': video_id, 'title': f'Video {video_id}'}
        
        results['video_info'] = video_info
        
    except Exception as e:
        results['errors'].append(f"Failed to extract video info: {e}")
        return results
    
    # Create output directory
    if output_dir:
        analysis_dir = Path(output_dir)
        analysis_dir.mkdir(parents=True, exist_ok=True)
    else:
        analysis_dir = create_analysis_directory(video_info)
    
    results['analysis_dir'] = str(analysis_dir)
    
    print(f"📁 Analysis directory: {analysis_dir}")
    
    # Scrape comments if API key is available
    if api_key and scraper:
        print(f"\n💬 Scraping comments...")
        try:
            command_info = {
                'original_command': ' '.join(sys.argv),
                'max_comments': max_comments,
                'format': 'json',
                'scraper_type': 'complete_content'
            }
            
            comments, _ = get_comments_batch(
                video_url=video_url,
                max_comments=max_comments,
                output_format='json',
                output_file=analysis_dir / 'comments.json',
                api_key=api_key,
                show_insights=True,
                command_info=command_info
            )
            
            results['comments'] = {
                'count': len(comments),
                'file': str(analysis_dir / 'comments.json'),
                'insights_file': str(analysis_dir / 'insights.txt')
            }
            
            print(f"   ✅ Scraped {len(comments)} comments")
            
        except Exception as e:
            error_msg = f"Comment scraping failed: {e}"
            results['errors'].append(error_msg)
            print(f"   ❌ {error_msg}")
    else:
        print(f"\n💬 Skipping comment scraping (no API key provided)")
    
    # Download captions
    print(f"\n📹 Downloading captions...")
    try:
        caption_results = download_captions_for_video(
            video_url=video_url,
            language_code=caption_language,
            output_format='json',
            output_dir=analysis_dir / 'captions',
            include_auto_generated=include_auto_captions
        )
        
        if 'error' in caption_results:
            results['errors'].append(f"Caption download failed: {caption_results['error']}")
            print(f"   ❌ Caption download failed: {caption_results['error']}")
        else:
            results['captions'] = caption_results
            
            # Count downloaded captions
            caption_count = 0
            if 'captions' in caption_results:
                caption_count = len(caption_results['captions'])
            
            print(f"   ✅ Downloaded captions in {caption_count} language(s)")
            
            # Generate combined analysis if we have both comments and captions
            if results['comments'] and 'captions' in caption_results:
                print(f"\n🔍 Generating combined content analysis...")
                generate_combined_analysis(results, analysis_dir)
    
    except Exception as e:
        error_msg = f"Caption download failed: {e}"
        results['errors'].append(error_msg)
        print(f"   ❌ {error_msg}")
    
    # Create summary report
    create_summary_report(results, analysis_dir)
    
    return results


def generate_combined_analysis(results: dict, analysis_dir: Path):
    """Generate combined analysis of comments and captions."""
    try:
        # Load comment data
        import json
        with open(analysis_dir / 'comments.json', 'r', encoding='utf-8') as f:
            comment_data = json.load(f)
        
        comments = comment_data.get('comments', []) if isinstance(comment_data, dict) else comment_data
        
        # Get first available caption data
        caption_data = None
        captions_info = results['captions']
        if 'captions' in captions_info:
            # Get first available caption
            for lang_code, data in captions_info['captions'].items():
                caption_data = data
                break
        
        if not caption_data:
            print("   ⚠️  No caption data available for combined analysis")
            return
        
        # Analyze captions
        caption_analyzer = CaptionAnalyzer(caption_data)
        caption_topics = caption_analyzer.extract_key_topics(top_n=15)
        technical_terms = caption_analyzer.find_technical_terms()
        
        # Analyze comment topics (simplified)
        comment_texts = [c.get('text', '') for c in comments]
        all_comment_text = ' '.join(comment_texts).lower()
        
        # Find overlapping topics between video content and comments
        video_topics = {topic for topic, _ in caption_topics}
        comment_mentions = {}
        
        for topic, count in caption_topics:
            mentions = all_comment_text.count(topic.lower())
            if mentions > 0:
                comment_mentions[topic] = mentions
        
        # Generate combined insights
        combined_analysis = []
        combined_analysis.append("🔍 COMBINED CONTENT ANALYSIS")
        combined_analysis.append("=" * 60)
        combined_analysis.append(f"Video: {results['video_info'].get('title', 'Unknown')}")
        combined_analysis.append(f"Analysis Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        combined_analysis.append("")
        
        # Video content summary
        combined_analysis.append("📹 VIDEO CONTENT OVERVIEW")
        combined_analysis.append("-" * 30)
        stats = caption_data.get('statistics', {})
        combined_analysis.append(f"Duration: {stats.get('duration_formatted', 'Unknown')}")
        combined_analysis.append(f"Words: {stats.get('total_words', 0):,}")
        combined_analysis.append(f"Speaking Rate: {stats.get('words_per_minute', 0):.1f} WPM")
        combined_analysis.append("")
        
        # Comment engagement summary
        combined_analysis.append("💬 AUDIENCE ENGAGEMENT OVERVIEW")
        combined_analysis.append("-" * 30)
        combined_analysis.append(f"Comments Analyzed: {len(comments):,}")
        total_likes = sum(c.get('like_count', 0) for c in comments)
        avg_likes = total_likes / len(comments) if comments else 0
        combined_analysis.append(f"Total Likes: {total_likes:,}")
        combined_analysis.append(f"Average Engagement: {avg_likes:.1f} likes/comment")
        combined_analysis.append("")
        
        # Topic alignment analysis
        if comment_mentions:
            combined_analysis.append("🎯 CONTENT-AUDIENCE ALIGNMENT")
            combined_analysis.append("-" * 30)
            combined_analysis.append("Topics from video mentioned in comments:")
            
            sorted_mentions = sorted(comment_mentions.items(), key=lambda x: x[1], reverse=True)
            for topic, mentions in sorted_mentions[:10]:
                combined_analysis.append(f"  • {topic}: {mentions} mention(s) in comments")
            
            alignment_score = len(comment_mentions) / len(caption_topics) * 100 if caption_topics else 0
            combined_analysis.append(f"\nAlignment Score: {alignment_score:.1f}% of video topics mentioned in comments")
            combined_analysis.append("")
        
        # Technical depth comparison
        if technical_terms:
            combined_analysis.append("🔧 TECHNICAL CONTENT ANALYSIS")
            combined_analysis.append("-" * 30)
            combined_analysis.append(f"Technical terms covered: {len(technical_terms)}")
            combined_analysis.append(f"Terms: {', '.join(technical_terms[:10])}")
            if len(technical_terms) > 10:
                combined_analysis.append(f"       ... and {len(technical_terms) - 10} more")
            combined_analysis.append("")
        
        # Recommendations
        combined_analysis.append("💡 CONTENT OPTIMIZATION RECOMMENDATIONS")
        combined_analysis.append("-" * 30)
        
        if alignment_score < 30:
            combined_analysis.append("• Low topic alignment - consider addressing audience questions more directly")
        elif alignment_score > 70:
            combined_analysis.append("• Excellent topic alignment - content resonates well with audience")
        else:
            combined_analysis.append("• Good topic alignment - minor adjustments could improve engagement")
        
        if avg_likes < 2:
            combined_analysis.append("• Consider more interactive content or clearer explanations")
        elif avg_likes > 5:
            combined_analysis.append("• High engagement - current content strategy is effective")
        
        if stats.get('words_per_minute', 0) > 180:
            combined_analysis.append("• Speaking rate is fast - consider slowing down for better comprehension")
        elif stats.get('words_per_minute', 0) < 120:
            combined_analysis.append("• Speaking rate is slow - could increase pace for better retention")
        
        # Save combined analysis
        analysis_file = analysis_dir / 'combined_analysis.txt'
        with open(analysis_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(combined_analysis))
        
        print(f"   📊 Combined analysis saved to: {analysis_file}")
        
        # Display key insights
        print(f"\n🎯 KEY INSIGHTS:")
        if comment_mentions:
            print(f"   • Content-Audience Alignment: {alignment_score:.1f}%")
            print(f"   • Most Discussed Video Topic: {sorted_mentions[0][0]} ({sorted_mentions[0][1]} mentions)")
        print(f"   • Audience Engagement: {avg_likes:.1f} avg likes per comment")
        print(f"   • Technical Depth: {len(technical_terms)} technical terms covered")
        
    except Exception as e:
        print(f"   ❌ Combined analysis failed: {e}")


def create_summary_report(results: dict, analysis_dir: Path):
    """Create a comprehensive summary report."""
    summary = []
    summary.append("# YouTube Content Analysis Report\n")
    
    video_info = results.get('video_info', {})
    summary.append(f"**🔗 Video:** [Watch on YouTube](https://www.youtube.com/watch?v={video_info.get('id', 'unknown')})")
    summary.append(f"**📺 Title:** {video_info.get('title', 'Unknown')}")
    summary.append(f"**🏷️ Channel:** {video_info.get('channel', 'Unknown')}")
    summary.append(f"**📅 Analysis Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    summary.append("")
    
    # Command used
    summary.append("## Command Used\n")
    summary.append(f"```bash\n{' '.join(sys.argv)}\n```\n")
    
    # Files generated
    summary.append("## Files Generated\n")
    
    if results['comments']:
        summary.append(f"### 💬 Comments Analysis")
        summary.append(f"- `comments.json` - Raw comment data ({results['comments']['count']:,} comments)")
        summary.append(f"- `insights.txt` - Comment analysis and insights")
        summary.append("")
    
    if results['captions']:
        summary.append(f"### 📹 Caption Analysis")
        if 'captions' in results['captions']:
            for lang_code in results['captions']['captions'].keys():
                summary.append(f"- `captions/captions_{video_info.get('id', 'unknown')}_{lang_code}.json` - Caption data")
                summary.append(f"- `captions/analysis_{lang_code}.txt` - Caption content analysis")
        summary.append("")
    
    if results['comments'] and results['captions']:
        summary.append(f"### 🔍 Combined Analysis")
        summary.append(f"- `combined_analysis.txt` - Content-audience alignment analysis")
        summary.append("")
    
    # Errors
    if results['errors']:
        summary.append("## ⚠️ Errors Encountered\n")
        for error in results['errors']:
            summary.append(f"- {error}")
        summary.append("")
    
    # Usage instructions
    summary.append("## 📖 How to Use This Analysis\n")
    summary.append("1. **Review comment insights** to understand audience engagement and questions")
    summary.append("2. **Analyze caption content** to see what topics were actually covered")
    summary.append("3. **Check combined analysis** for content-audience alignment insights")
    summary.append("4. **Use recommendations** to improve future content")
    summary.append("")
    
    summary.append("Generated with ContainerCodes YouTube Content Analysis Toolkit")
    
    # Save summary
    readme_file = analysis_dir / 'README.md'
    with open(readme_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(summary))
    
    print(f"\n📄 Analysis summary: {readme_file}")


def main():
    """Main CLI interface."""
    parser = argparse.ArgumentParser(
        description="YouTube Complete Content Scraper - Download comments and captions for comprehensive analysis",
        epilog="Examples:\n"
               "  %(prog)s https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
               "  %(prog)s dQw4w9WgXcQ --max-comments 100 --caption-lang en\n"
               "  %(prog)s video_id --caption-lang all --no-auto-captions\n"
               "  %(prog)s https://youtu.be/dQw4w9WgXcQ --output-dir analysis_output",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    # Required arguments
    parser.add_argument("video", 
                       help="YouTube video URL or video ID")
    
    # Comment scraping options
    parser.add_argument("--max-comments", "-n", type=int, default=None,
                       help="Maximum number of comments to retrieve (default: all)")
    
    parser.add_argument("--api-key", type=str, default=None,
                       help="YouTube Data API v3 key (or set YOUTUBE_API_KEY env var)")
    
    # Caption download options  
    parser.add_argument("--caption-lang", "-l", type=str, default='en',
                       help="Caption language code or 'all' for all languages (default: en)")
    
    parser.add_argument("--no-auto-captions", action="store_true",
                       help="Exclude auto-generated captions")
    
    # Output options
    parser.add_argument("--output-dir", "-o", type=str, default=None,
                       help="Output directory (auto-generated if not specified)")
    
    parser.add_argument("--quiet", "-q", action="store_true",
                       help="Suppress progress output")
    
    parser.add_argument("--setup", action="store_true",
                       help="Interactive API key setup")
    
    args = parser.parse_args()
    
    # Handle setup mode
    if args.setup:
        setup_api_key()
        return
    
    # Setup API key for comment scraping
    api_key = args.api_key or os.environ.get('YOUTUBE_API_KEY')
    if not api_key:
        if not args.quiet:
            print("🔑 No YouTube API key found - comment scraping will be skipped")
            print("   Set YOUTUBE_API_KEY environment variable or use --api-key")
            print("   Caption downloading will still work")
    
    try:
        if not args.quiet:
            print(f"🚀 Starting comprehensive YouTube content analysis...")
            print(f"Video: {args.video}")
            if args.max_comments:
                print(f"Max comments: {args.max_comments:,}")
            print(f"Caption language: {args.caption_lang}")
            print(f"Include auto-captions: {not args.no_auto_captions}")
        
        # Run complete content scraping
        results = scrape_complete_content(
            video_url=args.video,
            max_comments=args.max_comments,
            caption_language=args.caption_lang,
            include_auto_captions=not args.no_auto_captions,
            api_key=api_key,
            output_dir=args.output_dir
        )
        
        # Display results
        if not args.quiet:
            print(f"\n✅ Analysis complete!")
            print(f"📁 Results saved to: {results['analysis_dir']}")
            
            if results['errors']:
                print(f"\n⚠️  Some errors occurred:")
                for error in results['errors']:
                    print(f"   • {error}")
            
            print(f"\n📖 View the README.md file in the analysis directory for a complete overview.")
            
    except KeyboardInterrupt:
        print(f"\n⚠️  Operation cancelled by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        if not args.quiet:
            print("\nTroubleshooting tips:")
            print("- Verify the video URL or ID is correct")
            print("- Check your internet connection")
            print("- For comment scraping: verify API key is valid")
            print("- For captions: ensure the video has captions enabled")
        sys.exit(1)


if __name__ == "__main__":
    main()