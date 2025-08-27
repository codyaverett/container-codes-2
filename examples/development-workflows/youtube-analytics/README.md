# YouTube Analytics Development Workflow

**Difficulty:** Intermediate  
**Category:** Development Workflows  
**Technologies:** Python, YouTube Data API v3, Data Analysis, Anthropic Claude AI

## Overview

This enhanced example demonstrates how to set up and use the YouTube comment scraper tool
for analyzing audience engagement on the ContainerCodes YouTube channel. It now includes
AI-powered analysis capabilities using Anthropic's Claude for deeper insights into audience
feedback and content recommendations.

### 🆕 NEW: AI-Powered Analysis Features
- Advanced sentiment analysis using Claude AI
- Intelligent comment categorization  
- Automated content recommendations
- FAQ generation from questions
- Technical depth assessment
- Engagement quality analysis

## Prerequisites

- Python 3.8+
- YouTube Data API v3 key  
- **NEW:** Anthropic API key (for AI features)
- Basic familiarity with Python data analysis

## Setup

### 1. Install Dependencies

```bash
# From project root
pip install -r requirements.txt

# Optional: Install analysis dependencies
pip install pandas matplotlib seaborn wordcloud
```

### 2. Configure API Access

```bash
# YouTube Data API v3
export YOUTUBE_API_KEY='your_youtube_api_key_here'

# NEW: Anthropic API for AI features
export ANTHROPIC_API_KEY='your_anthropic_api_key_here'

# Interactive setup (legacy)
make youtube-setup
```

#### Getting API Keys

**YouTube Data API v3:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project and enable YouTube Data API v3
3. Create an API key

**Anthropic API (for AI features):**
1. Go to [Anthropic Console](https://console.anthropic.com/)
2. Create account and generate API key

### 3. Test Installation

```bash
# Scrape a small sample
make youtube-comments URL='https://youtu.be/dQw4w9WgXcQ' MAX=10
```

## Basic Workflow

### 1. Data Collection

```bash
#!/bin/bash
# collect_comments.sh

# Scrape comments from latest ContainerCodes episode
EPISODE_URL="https://www.youtube.com/watch?v=YOUR_VIDEO_ID"

echo "Collecting comments from: $EPISODE_URL"

# Scrape with different formats for different use cases
python3 scripts/youtube-comment-scraper.py "$EPISODE_URL" \
  --format json \
  --output "data/episode_comments.json" \
  --max-comments 500

# Also export as CSV for spreadsheet analysis
python3 scripts/youtube-comment-scraper.py "$EPISODE_URL" \
  --format csv \
  --output "data/episode_comments.csv" \
  --no-export

echo "Data collection complete!"
```

### 2. Basic Analysis Script

```python
#!/usr/bin/env python3
# analyze_comments.py

import json
import pandas as pd
from collections import Counter
from datetime import datetime
import matplotlib.pyplot as plt

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
    print(f"Most Active User: {authors.most_common(1)[0][0]} ({authors.most_common(1)[0][1]} comments)")

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
    # Convert to DataFrame for easier analysis
    df = pd.DataFrame(comments)
    df['published_at'] = pd.to_datetime(df['published_at'])

    # Engagement by hour
    df['hour'] = df['published_at'].dt.hour
    hourly_comments = df.groupby('hour').size()

    # Top engaging comments
    top_comments = df.nlargest(10, 'like_count')

    print("\n🔥 Engagement Analysis")
    print("=" * 50)
    print("Peak commenting hours:")
    for hour, count in hourly_comments.nlargest(5).items():
        print(f"  {hour:02d}:00 - {count} comments")

    print("\nMost liked comments:")
    for _, comment in top_comments.head(3).iterrows():
        text = comment['text'][:80] + "..." if len(comment['text']) > 80 else comment['text']
        print(f"  👤 {comment['author']} ({comment['like_count']} likes)")
        print(f"     {text}\n")

def sentiment_keywords(comments):
    """Extract common keywords and themes."""
    from collections import Counter
    import re

    # Simple keyword extraction
    all_text = ' '.join(c['text'].lower() for c in comments)
    words = re.findall(r'\b\w{4,}\b', all_text)  # Words with 4+ characters

    # Filter out common words
    stop_words = {'this', 'that', 'with', 'have', 'will', 'from', 'they', 'been',
                  'were', 'said', 'each', 'which', 'their', 'time', 'would', 'there'}

    filtered_words = [w for w in words if w not in stop_words]
    word_counts = Counter(filtered_words)

    print("\n🎯 Common Topics")
    print("=" * 50)
    for word, count in word_counts.most_common(15):
        print(f"  {word}: {count}")

def generate_report(comments_file):
    """Generate complete analysis report."""
    comments = load_comments(comments_file)

    # Run all analyses
    basic_stats = basic_statistics(comments)
    engagement_analysis(comments)
    sentiment_keywords(comments)

    # Generate visualizations if matplotlib is available
    try:
        import matplotlib.pyplot as plt

        # Comment length distribution
        lengths = [len(c['text']) for c in comments]
        plt.figure(figsize=(10, 6))
        plt.hist(lengths, bins=50, alpha=0.7)
        plt.xlabel('Comment Length (characters)')
        plt.ylabel('Frequency')
        plt.title('Comment Length Distribution')
        plt.savefig('comment_lengths.png')
        print("\n📊 Visualization saved: comment_lengths.png")

        # Engagement over time
        df = pd.DataFrame(comments)
        df['published_at'] = pd.to_datetime(df['published_at'])
        df = df.sort_values('published_at')

        plt.figure(figsize=(12, 6))
        plt.plot(df['published_at'], df['like_count'].cumsum())
        plt.xlabel('Time')
        plt.ylabel('Cumulative Likes')
        plt.title('Comment Engagement Over Time')
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig('engagement_timeline.png')
        print("📊 Visualization saved: engagement_timeline.png")

    except ImportError:
        print("\n💡 Install matplotlib for visualizations: pip install matplotlib pandas")

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python3 analyze_comments.py comments.json")
        sys.exit(1)

    generate_report(sys.argv[1])
```

## 🤖 NEW: AI-Powered Analysis

The enhanced analysis now includes AI capabilities using Anthropic's Claude:

### Quick Start with AI

```bash
# Run enhanced analysis with AI insights
python3 examples/development-workflows/youtube-analytics/analyze_comments.py episode_comments.json

# Traditional analysis only (no AI)  
python3 examples/development-workflows/youtube-analytics/analyze_comments.py episode_comments.json --no-ai

# Standalone AI analysis
python3 src/app/ai_comment_analyzer.py episode_comments.json
```

### AI Analysis Features

#### 1. Advanced Sentiment & Themes Analysis
```bash
# Example output:
📊 AI Sentiment & Themes:
  Overall sentiment: 78% positive, 18% neutral, 4% negative
  Key themes: container security, rootless containers, production deployments
  Learning indicators: High engagement with technical explanations
  Audience level: Intermediate to advanced DevOps practitioners
```

#### 2. Intelligent Comment Categorization
Comments are automatically sorted into:
- **Questions** (15%): Specific technical questions
- **Technical Discussion** (35%): Advanced insights and experiences  
- **Feedback** (25%): Constructive content feedback
- **Requests** (12%): Future content suggestions
- **Appreciation** (10%): Thanks and praise
- **Other** (3%): Miscellaneous comments

#### 3. Content Recommendations
```bash
# Example AI recommendations:
💡 AI Content Recommendations:
  1. Deep dive on Podman networking - high interest in comments
  2. Comparison video: Docker vs Podman security features
  3. Tutorial: Container monitoring in production environments
  4. Follow-up: Advanced rootless container configurations
```

#### 4. FAQ Generation
The AI analyzes questions to create FAQ content:
- Identifies most important questions by engagement
- Groups similar questions together
- Suggests answer complexity (simple/detailed/video-worthy)
- Reveals common misconceptions

### AI Analysis Output Files

When AI analysis runs, you get:

1. **Enhanced Console Output**: Key insights displayed during analysis
2. **Complete AI Report**: `comments_ai_enhanced.json` with full analysis
3. **Structured Data**: Machine-readable format for further processing

### Cost and Usage Considerations

- **YouTube API**: Free tier with daily quota limits
- **Anthropic API**: Pay-per-token usage (typically $0.01-0.05 per analysis)
- **Optimization**: Tool samples comments intelligently to manage costs
- **Control**: Use `--no-ai` flag when you want traditional analysis only

### 3. Automated Analysis Pipeline

```bash
#!/bin/bash
# analysis_pipeline.sh

set -e

VIDEO_URL="$1"
OUTPUT_DIR="analysis_$(date +%Y%m%d_%H%M%S)"

if [ -z "$VIDEO_URL" ]; then
    echo "Usage: $0 <youtube_video_url>"
    exit 1
fi

echo "🚀 Starting YouTube Analytics Pipeline"
echo "Video: $VIDEO_URL"
echo "Output Directory: $OUTPUT_DIR"

# Create output directory
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

# Step 1: Collect data
echo "📥 Step 1: Collecting comment data..."
python3 ../scripts/youtube-comment-scraper.py "$VIDEO_URL" \
    --format json \
    --output comments.json \
    --max-comments 1000

# Step 2: Basic analysis
echo "📊 Step 2: Running analysis..."
python3 ../examples/development-workflows/youtube-analytics/analyze_comments.py comments.json > analysis_report.txt

# Step 3: Generate summary
echo "📋 Step 3: Generating summary..."
cat << EOF > README.md
# YouTube Comment Analysis Report

**Generated:** $(date)
**Video URL:** $VIDEO_URL
**Comments Analyzed:** $(jq length comments.json)

## Files

- \`comments.json\` - Raw comment data
- \`analysis_report.txt\` - Detailed analysis report
- \`comment_lengths.png\` - Comment length distribution
- \`engagement_timeline.png\` - Engagement over time

## Quick Stats

$(head -20 analysis_report.txt)

---

Generated with ContainerCodes YouTube Analytics Toolkit
EOF

echo "✅ Analysis complete! Results in: $OUTPUT_DIR"
echo "📁 View results: cat $OUTPUT_DIR/README.md"
```

## Advanced Use Cases

### 1. Multi-Video Comparison

```python
# compare_videos.py
import json
import pandas as pd

def compare_videos(video_files):
    """Compare metrics across multiple videos."""
    results = []

    for file_path in video_files:
        with open(file_path, 'r') as f:
            comments = json.load(f)

        # Calculate metrics
        total_comments = len(comments)
        avg_likes = sum(c['like_count'] for c in comments) / total_comments
        reply_ratio = len([c for c in comments if c.get('is_reply')]) / total_comments

        results.append({
            'video': file_path,
            'total_comments': total_comments,
            'avg_likes': avg_likes,
            'reply_ratio': reply_ratio
        })

    df = pd.DataFrame(results)
    print(df.to_string(index=False))

    return df
```

### 2. Automated Monitoring

```bash
#!/bin/bash
# monitor_comments.sh - Daily comment monitoring

# Cron job example: Run daily at 9 AM
# 0 9 * * * /path/to/monitor_comments.sh

CHANNEL_VIDEOS=(
    "https://www.youtube.com/watch?v=VIDEO1"
    "https://www.youtube.com/watch?v=VIDEO2"
    "https://www.youtube.com/watch?v=VIDEO3"
)

REPORT_DIR="daily_reports/$(date +%Y%m%d)"
mkdir -p "$REPORT_DIR"

for video in "${CHANNEL_VIDEOS[@]}"; do
    video_id=$(python3 -c "from src.app.youtube_scraper import YouTubeCommentScraper; s = YouTubeCommentScraper(); print(s.extract_video_id('$video'))")

    echo "Monitoring: $video_id"
    python3 scripts/youtube-comment-scraper.py "$video" \
        --format json \
        --output "$REPORT_DIR/${video_id}_comments.json" \
        --max-comments 100 \
        --quiet
done

echo "Daily monitoring complete: $REPORT_DIR"
```

### 3. Integration with ContainerCodes Content Planning

```python
# content_insights.py
"""Extract content insights from comment analysis."""

def extract_questions(comments):
    """Find questions in comments for FAQ creation."""
    questions = []

    for comment in comments:
        text = comment['text'].strip()
        # Simple question detection
        if '?' in text and any(word in text.lower() for word in ['how', 'what', 'why', 'when', 'where']):
            questions.append({
                'question': text,
                'author': comment['author'],
                'likes': comment['like_count']
            })

    # Sort by engagement
    questions.sort(key=lambda x: x['likes'], reverse=True)
    return questions[:10]

def identify_topics(comments):
    """Identify requested topics for future episodes."""
    topic_keywords = [
        'tutorial', 'explain', 'show how', 'guide', 'demo',
        'example', 'walkthrough', 'deep dive', 'comparison'
    ]

    topic_requests = []
    for comment in comments:
        text = comment['text'].lower()
        if any(keyword in text for keyword in topic_keywords):
            topic_requests.append(comment)

    return topic_requests
```

## Best Practices

### 1. Data Management

```bash
# Organize data by date and video
mkdir -p data/{raw,processed,reports}
mkdir -p data/raw/$(date +%Y/%m)

# Use consistent naming
VIDEO_ID_comments_$(date +%Y%m%d).json
```

### 2. Privacy and Ethics

- Always respect commenter privacy
- Aggregate data when possible
- Don't store personal information longer than necessary
- Be transparent about data collection and usage

### 3. Performance Tips

```python
# Use streaming for large datasets
def process_large_dataset(file_path):
    with open(file_path, 'r') as f:
        for line in f:
            comment = json.loads(line)
            yield process_comment(comment)

# Implement caching
import functools

@functools.lru_cache(maxsize=128)
def expensive_analysis(comment_text):
    # Heavy processing here
    return result
```

## Integration with CI/CD

```yaml
# .github/workflows/comment-analysis.yml
name: Weekly Comment Analysis

on:
  schedule:
    - cron: "0 9 * * 1" # Every Monday at 9 AM

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: "3.8"
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run analysis
        env:
          YOUTUBE_API_KEY: ${{ secrets.YOUTUBE_API_KEY }}
        run: |
          bash examples/development-workflows/youtube-analytics/weekly_analysis.sh
      - name: Upload results
        uses: actions/upload-artifact@v2
        with:
          name: weekly-analysis
          path: analysis_*
```

## Troubleshooting

### Common Issues

1. **API Quota Limits**

   - Implement backoff strategies
   - Use multiple API keys with rotation
   - Cache results to avoid re-scraping

2. **Large Datasets**

   - Process data in chunks
   - Use streaming JSON parsing
   - Implement progress indicators

3. **Memory Usage**
   - Process files line by line for large datasets
   - Use generators instead of loading all data
   - Clean up unused variables

### Performance Monitoring

```python
import time
import psutil
import os

def monitor_performance(func):
    """Decorator to monitor function performance."""
    def wrapper(*args, **kwargs):
        start_time = time.time()
        start_memory = psutil.Process(os.getpid()).memory_info().rss / 1024 / 1024

        result = func(*args, **kwargs)

        end_time = time.time()
        end_memory = psutil.Process(os.getpid()).memory_info().rss / 1024 / 1024

        print(f"Function: {func.__name__}")
        print(f"Execution time: {end_time - start_time:.2f} seconds")
        print(f"Memory usage: {end_memory - start_memory:.2f} MB")

        return result
    return wrapper
```

## Next Steps

1. **Advanced Analytics**: Implement sentiment analysis, topic modeling
2. **Real-time Monitoring**: Set up webhooks for immediate comment analysis
3. **Visualization Dashboard**: Create web-based dashboard for insights
4. **Machine Learning**: Train models to predict comment engagement
5. **Integration**: Connect with other analytics tools and platforms

This workflow provides a solid foundation for YouTube comment analysis within
the ContainerCodes project structure, following security best practices and
respecting platform terms of service.
