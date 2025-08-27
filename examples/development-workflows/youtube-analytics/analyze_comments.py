#!/usr/bin/env python3
"""
Enhanced Comment Analysis Script
Analyze YouTube comments for engagement patterns and insights
Now with optional AI-powered analysis using Anthropic's Claude
"""

import json
import sys
import os
from collections import Counter
from datetime import datetime
import re

# Add the src directory to the path for AI analyzer import
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..', 'src'))

try:
    from app.ai_comment_analyzer import AICommentAnalyzer
    AI_AVAILABLE = True
except ImportError:
    AI_AVAILABLE = False


def load_comments(file_path):
    """Load comments from JSON file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def basic_statistics(comments):
    """Generate basic comment statistics."""
    total_comments = len(comments)
    
    # Separate top-level comments and replies
    top_level = [c for c in comments if not c.get('is_reply', False)]
    replies = [c for c in comments if c.get('is_reply', False)]
    
    # Engagement metrics
    total_likes = sum(c['like_count'] for c in comments)
    avg_likes = total_likes / total_comments if total_comments > 0 else 0
    
    # Top contributors
    authors = Counter(c['author'] for c in comments)
    
    print("📊 Comment Analysis Report")
    print("=" * 50)
    print(f"Total Comments: {total_comments:,}")
    print(f"Top-level Comments: {len(top_level):,}")
    print(f"Replies: {len(replies):,}")
    print(f"Total Likes: {total_likes:,}")
    print(f"Average Likes per Comment: {avg_likes:.1f}")
    
    if authors:
        top_author = authors.most_common(1)[0]
        print(f"Most Active User: {top_author[0]} ({top_author[1]} comments)")
    
    return {
        'total_comments': total_comments,
        'top_level_comments': len(top_level),
        'replies': len(replies),
        'total_likes': total_likes,
        'avg_likes': avg_likes,
        'top_authors': authors.most_common(10)
    }


def engagement_analysis(comments):
    """Analyze engagement patterns."""
    if not comments:
        print("\n🔥 Engagement Analysis")
        print("=" * 50)
        print("No comments to analyze.")
        return
    
    # Convert timestamps and analyze by hour
    hourly_comments = Counter()
    
    for comment in comments:
        try:
            # Parse ISO timestamp
            dt = datetime.fromisoformat(comment['published_at'].replace('Z', '+00:00'))
            hourly_comments[dt.hour] += 1
        except (ValueError, KeyError):
            continue
    
    # Top engaging comments
    top_comments = sorted(comments, key=lambda x: x['like_count'], reverse=True)[:10]
    
    print("\n🔥 Engagement Analysis")
    print("=" * 50)
    
    if hourly_comments:
        print("Peak commenting hours:")
        for hour, count in hourly_comments.most_common(5):
            print(f"  {hour:02d}:00 - {count} comments")
    
    print("\nMost liked comments:")
    for i, comment in enumerate(top_comments[:3], 1):
        text = comment['text'][:80] + "..." if len(comment['text']) > 80 else comment['text']
        print(f"  {i}. 👤 {comment['author']} ({comment['like_count']} likes)")
        print(f"     {text}\n")


def sentiment_keywords(comments):
    """Extract common keywords and themes."""
    # Simple keyword extraction
    all_text = ' '.join(c['text'].lower() for c in comments)
    words = re.findall(r'\b\w{4,}\b', all_text)  # Words with 4+ characters
    
    # Filter out common words
    stop_words = {
        'this', 'that', 'with', 'have', 'will', 'from', 'they', 'been', 
        'were', 'said', 'each', 'which', 'their', 'time', 'would', 'there',
        'what', 'when', 'where', 'will', 'your', 'just', 'like', 'dont',
        'really', 'think', 'know', 'good', 'great', 'thanks', 'thank',
        'video', 'youtube', 'channel', 'subscribe'
    }
    
    filtered_words = [w for w in words if w not in stop_words and len(w) > 3]
    word_counts = Counter(filtered_words)
    
    print("\n🎯 Common Topics")
    print("=" * 50)
    
    if word_counts:
        for word, count in word_counts.most_common(15):
            print(f"  {word}: {count}")
    else:
        print("No significant topics found.")


def extract_questions(comments):
    """Find questions in comments for FAQ creation."""
    questions = []
    
    question_indicators = ['?', 'how', 'what', 'why', 'when', 'where', 'which', 'can you']
    
    for comment in comments:
        text = comment['text'].strip()
        text_lower = text.lower()
        
        # Check for question patterns
        if ('?' in text and 
            any(indicator in text_lower for indicator in question_indicators)):
            questions.append({
                'question': text,
                'author': comment['author'],
                'likes': comment['like_count']
            })
    
    # Sort by engagement
    questions.sort(key=lambda x: x['likes'], reverse=True)
    
    print("\n❓ Top Questions")
    print("=" * 50)
    
    if questions:
        for i, q in enumerate(questions[:5], 1):
            question_text = q['question'][:100] + "..." if len(q['question']) > 100 else q['question']
            print(f"  {i}. {question_text}")
            print(f"     By: {q['author']} ({q['likes']} likes)\n")
    else:
        print("No questions found.")
    
    return questions


def content_insights(comments):
    """Extract content insights for future episode planning."""
    topic_keywords = [
        'tutorial', 'explain', 'show how', 'guide', 'demo', 
        'example', 'walkthrough', 'deep dive', 'comparison',
        'please', 'would love', 'can you do', 'next video'
    ]
    
    content_requests = []
    
    for comment in comments:
        text_lower = comment['text'].lower()
        if any(keyword in text_lower for keyword in topic_keywords):
            content_requests.append({
                'text': comment['text'],
                'author': comment['author'],
                'likes': comment['like_count']
            })
    
    # Sort by engagement
    content_requests.sort(key=lambda x: x['likes'], reverse=True)
    
    print("\n💡 Content Requests")
    print("=" * 50)
    
    if content_requests:
        for i, request in enumerate(content_requests[:5], 1):
            request_text = request['text'][:100] + "..." if len(request['text']) > 100 else request['text']
            print(f"  {i}. {request_text}")
            print(f"     By: {request['author']} ({request['likes']} likes)\n")
    else:
        print("No specific content requests found.")
    
    return content_requests


def generate_summary(comments):
    """Generate executive summary."""
    if not comments:
        print("\n📋 Summary")
        print("=" * 50)
        print("No comments available for analysis.")
        return
    
    # Calculate key metrics
    total_comments = len(comments)
    total_likes = sum(c['like_count'] for c in comments)
    avg_likes = total_likes / total_comments
    
    # Find most engaging comment
    most_liked = max(comments, key=lambda x: x['like_count'])
    
    # Calculate engagement distribution
    high_engagement = len([c for c in comments if c['like_count'] > avg_likes * 2])
    
    print("\n📋 Executive Summary")
    print("=" * 50)
    print(f"🔢 Total Comments: {total_comments:,}")
    print(f"👍 Total Engagement: {total_likes:,} likes")
    print(f"📊 Average Engagement: {avg_likes:.1f} likes per comment")
    print(f"🔥 High-engagement comments: {high_engagement} ({high_engagement/total_comments*100:.1f}%)")
    print(f"🏆 Most liked comment: {most_liked['like_count']} likes by {most_liked['author']}")
    
    # Engagement health score
    if avg_likes > 5:
        health = "Excellent"
        emoji = "🟢"
    elif avg_likes > 2:
        health = "Good"
        emoji = "🟡"
    else:
        health = "Needs Improvement"
        emoji = "🔴"
    
    print(f"{emoji} Engagement Health: {health}")


def run_ai_analysis(comments, comments_file):
    """Run AI analysis if available."""
    if not AI_AVAILABLE:
        print("\n🤖 AI Analysis")
        print("=" * 50)
        print("AI analysis not available. Install anthropic package:")
        print("pip install anthropic>=0.40.0")
        print("Set ANTHROPIC_API_KEY environment variable")
        return
    
    api_key = os.environ.get('ANTHROPIC_API_KEY')
    if not api_key:
        print("\n🤖 AI Analysis")
        print("=" * 50)
        print("AI analysis available but ANTHROPIC_API_KEY not set.")
        print("Set your Anthropic API key to enable AI-powered insights:")
        print("export ANTHROPIC_API_KEY='your_key_here'")
        return
    
    try:
        print("\n🤖 AI-Powered Analysis")
        print("=" * 50)
        print("Generating AI insights... (this may take a moment)")
        
        analyzer = AICommentAnalyzer(api_key)
        
        # Run sentiment and themes analysis
        sentiment_result = analyzer.analyze_sentiment_and_themes(comments)
        if "error" not in sentiment_result:
            print("\n📊 AI Sentiment & Themes:")
            print("-" * 30)
            # Extract key insights from the analysis
            analysis_text = sentiment_result["analysis"]
            lines = analysis_text.split('\n')
            for line in lines[:10]:  # Show first 10 lines
                if line.strip():
                    print(f"  {line.strip()}")
            if len(lines) > 10:
                print("  ... (full analysis available in AI report)")
        
        # Run content recommendations
        rec_result = analyzer.generate_content_recommendations(comments)
        if "error" not in rec_result:
            print("\n💡 AI Content Recommendations:")
            print("-" * 30)
            rec_text = rec_result["recommendations"]
            rec_lines = rec_text.split('\n')
            for line in rec_lines[:8]:  # Show first 8 lines
                if line.strip():
                    print(f"  {line.strip()}")
            if len(rec_lines) > 8:
                print("  ... (full recommendations available in AI report)")
        
        # Save complete AI report
        ai_report_file = comments_file.replace('.json', '_ai_enhanced.json')
        complete_report = analyzer.generate_complete_ai_report(comments)
        with open(ai_report_file, 'w', encoding='utf-8') as f:
            json.dump(complete_report, f, indent=2, ensure_ascii=False)
        
        print(f"\n✨ Complete AI analysis saved to: {ai_report_file}")
        
    except Exception as e:
        print(f"\n❌ AI analysis failed: {e}")


def generate_report(comments_file, use_ai=True):
    """Generate complete analysis report with optional AI enhancement."""
    try:
        comments = load_comments(comments_file)
    except FileNotFoundError:
        print(f"❌ Error: File '{comments_file}' not found.")
        return
    except json.JSONDecodeError:
        print(f"❌ Error: Invalid JSON in file '{comments_file}'.")
        return
    
    if not comments:
        print("❌ No comments found in the file.")
        return
    
    print(f"Analyzing {len(comments)} comments from {comments_file}")
    print()
    
    # Run traditional analyses
    basic_statistics(comments)
    engagement_analysis(comments)
    sentiment_keywords(comments)
    extract_questions(comments)
    content_insights(comments)
    generate_summary(comments)
    
    # Run AI analysis if requested and available
    if use_ai:
        run_ai_analysis(comments, comments_file)
    
    print("\n" + "=" * 50)
    print("📄 Analysis complete!")
    print("💡 Use these insights to improve content and engagement.")
    if use_ai and AI_AVAILABLE and os.environ.get('ANTHROPIC_API_KEY'):
        print("✨ Enhanced with AI-powered insights from Anthropic Claude.")


if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: python3 analyze_comments.py <comments.json> [--no-ai]")
        print("\nExamples:")
        print("  python3 analyze_comments.py episode_comments.json")
        print("  python3 analyze_comments.py episode_comments.json --no-ai")
        print("\nThe --no-ai flag disables AI-powered analysis.")
        print("AI analysis requires anthropic package and ANTHROPIC_API_KEY.")
        sys.exit(1)
    
    comments_file = sys.argv[1]
    use_ai = len(sys.argv) == 2 or sys.argv[2] != "--no-ai"
    
    generate_report(comments_file, use_ai)