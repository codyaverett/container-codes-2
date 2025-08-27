# YouTube Comment Analytics User Guide

## Overview

The YouTube Comment Analytics tool helps content creators understand their audience engagement, identify trending topics, and make data-driven decisions about future content. This guide covers everything from basic setup to advanced analysis techniques.

## Table of Contents

- [Quick Start](#quick-start)
- [Installation & Setup](#installation--setup)
- [Basic Usage](#basic-usage)
- [Advanced Features](#advanced-features)
- [Understanding Output](#understanding-output)
- [Best Practices](#best-practices)
- [Automation](#automation)

## Quick Start

### 5-Minute Setup

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Setup YouTube API key
make youtube-setup

# 3. Analyze your first video
make youtube-comments URL='https://youtu.be/YOUR_VIDEO_ID'
```

That's it! You'll get comprehensive insights about your video's comments.

## Installation & Setup

### Prerequisites

- Python 3.8 or higher
- YouTube Data API v3 key
- Internet connection for API requests

### Step 1: Get YouTube Data API Key

1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the "YouTube Data API v3"
4. Navigate to "Credentials" > "Create Credentials" > "API Key"
5. Copy your API key (keep it secure!)

### Step 2: Install Dependencies

```bash
# From project root
pip install -r requirements.txt
```

### Step 3: Configure API Key

**Option A: Interactive Setup**
```bash
make youtube-setup
```

**Option B: Environment Variable**
```bash
export YOUTUBE_API_KEY='your_api_key_here'
# Add to ~/.bashrc or ~/.zshrc to persist
```

### Step 4: Verify Installation

```bash
# Test with a small sample
make youtube-comments URL='https://youtu.be/dQw4w9WgXcQ' MAX=10
```

## Basic Usage

### Using Make Commands (Recommended)

```bash
# Analyze with default settings (200 comments)
make youtube-comments URL='https://youtu.be/VIDEO_ID'

# Limit number of comments
make youtube-comments URL='https://youtu.be/VIDEO_ID' MAX=500

# Different video URL formats work
make youtube-comments URL='https://www.youtube.com/watch?v=VIDEO_ID'
make youtube-comments URL='VIDEO_ID'  # Just the ID
```

### Using Python Script Directly

```bash
# Basic usage
python3 scripts/youtube-comment-scraper.py 'https://youtu.be/VIDEO_ID'

# With options
python3 scripts/youtube-comment-scraper.py VIDEO_ID \
  --max-comments 300 \
  --format json \
  --output my_analysis.json

# Different formats
python3 scripts/youtube-comment-scraper.py VIDEO_ID --format csv
python3 scripts/youtube-comment-scraper.py VIDEO_ID --format markdown
```

### Command Options

| Option | Description | Example |
|--------|-------------|---------|
| `--max-comments, -n` | Limit number of comments | `--max-comments 100` |
| `--format, -f` | Output format (json/csv/markdown) | `--format csv` |
| `--output, -o` | Custom output filename | `--output analysis.json` |
| `--order` | Comment order (time/relevance) | `--order relevance` |
| `--quiet, -q` | Suppress progress output | `--quiet` |
| `--no-export` | Analysis only, no file export | `--no-export` |
| `--no-insights` | Skip detailed analysis | `--no-insights` |

## Advanced Features

### AI-Powered Topic Suggestions

The tool automatically suggests future video topics based on comment analysis:

```bash
# Full AI analysis (default)
make youtube-comments URL='https://youtu.be/VIDEO_ID'

# Skip AI insights for faster analysis
python3 scripts/youtube-comment-scraper.py VIDEO_ID --no-insights
```

### Batch Analysis

Analyze multiple videos efficiently:

```bash
#!/bin/bash
VIDEOS=(
  "https://youtu.be/VIDEO_1"
  "https://youtu.be/VIDEO_2" 
  "https://youtu.be/VIDEO_3"
)

for video in "${VIDEOS[@]}"; do
  echo "Analyzing: $video"
  make youtube-comments URL="$video" MAX=200
  sleep 2  # Rate limiting
done
```

### Custom Analysis Scripts

Use the Python module in your own scripts:

```python
from src.app.youtube_scraper import get_comments_batch, CommentAnalyzer

# Scrape comments
comments, video_info = get_comments_batch(
    'https://youtu.be/VIDEO_ID',
    max_comments=500,
    show_insights=False  # We'll do custom analysis
)

# Custom analysis
analyzer = CommentAnalyzer(comments)
keywords = analyzer.extract_keywords(min_word_length=5, top_n=20)
questions = analyzer.find_questions(20)
suggestions = analyzer.suggest_future_topics(10)

# Your custom processing here
print(f"Found {len(questions)} questions")
for suggestion in suggestions[:3]:
    print(f"- {suggestion['title']}")
```

## Understanding Output

### File Outputs

All files are saved to the `tmp/` directory:

```
tmp/
├── video_title_20240127_143052.json      # Raw comment data
├── video_title_20240127_143052.csv       # CSV format
├── video_title_20240127_143052.md        # Markdown report  
└── video_title_20240127_143052_insights.txt  # AI analysis
```

### Console Insights

The tool displays comprehensive analysis including:

#### Basic Statistics
```
💬 Total Comments: 1,234
   ├─ Top-level: 987
   └─ Replies: 247 (20.0%)
👍 Engagement: 5,678 total likes
```

#### Topic Analysis
```
🎯 TOP DISCUSSION TOPICS:
    1. kubernetes (45 mentions)
    2. security (38 mentions)
    3. containers (32 mentions)
```

#### Future Content Suggestions
```
🚀 SUGGESTED FUTURE VIDEO TOPICS:
   1. 🔥 Kubernetes networking deep dive
      └─ Based on 23 mentions of 'kubernetes'
   2. ⭐ Container security scanning  
      └─ Based on 12 mentions of 'security'
```

#### Audience Analysis
```
👥 AUDIENCE TECHNICAL LEVEL:
   Primary audience: Intermediate
   Distribution: Beginner 25% | Intermediate 55% | Advanced 20%
   💡 Focus on: Best practices, real-world examples
```

### Priority Indicators

- 🔥 **High Priority**: High engagement + many mentions
- ⭐ **Medium Priority**: Solid interest, moderate engagement  
- 💡 **Emerging**: New trends from questions
- 📹 **Standard**: General suggestions

## Best Practices

### 1. API Usage

```bash
# Respect rate limits
sleep 2  # between requests

# Use appropriate comment limits
MAX=200   # Good for most videos
MAX=500   # For in-depth analysis
MAX=1000  # For comprehensive research (uses more quota)
```

### 2. Data Management

```bash
# Organize outputs by date
mkdir -p analysis/$(date +%Y-%m)

# Archive old analyses
tar -czf analysis_archive_$(date +%Y%m).tar.gz tmp/
```

### 3. Content Planning Workflow

1. **Analyze Recent Videos**: Get topic trends
2. **Identify Gaps**: What topics aren't covered?
3. **Check Audience Level**: Match complexity to audience
4. **Plan Series**: Group related topic suggestions
5. **Track Performance**: Re-analyze after new uploads

### 4. Privacy & Ethics

```bash
# Anonymize data for sharing
jq 'map(del(.author, .author_channel_id))' comments.json > anonymized.json

# Regular cleanup
find tmp/ -name "*.json" -mtime +30 -delete
```

## Automation

### Daily Analysis Script

```bash
#!/bin/bash
# daily_analysis.sh

# Get latest video from channel (requires channel ID)
LATEST_VIDEO=$(python3 -c "
import os
from googleapiclient.discovery import build
youtube = build('youtube', 'v3', developerKey=os.environ['YOUTUBE_API_KEY'])
response = youtube.search().list(
    part='id',
    channelId='YOUR_CHANNEL_ID',
    order='date',
    maxResults=1,
    type='video'
).execute()
print('https://youtu.be/' + response['items'][0]['id']['videoId'])
")

echo "Analyzing latest video: $LATEST_VIDEO"
make youtube-comments URL="$LATEST_VIDEO" MAX=100

# Process insights for content planning
python3 scripts/process_insights.py tmp/*_insights.txt
```

### Cron Job Setup

```bash
# Edit crontab
crontab -e

# Add daily analysis at 9 AM
0 9 * * * cd /path/to/container-codes && bash daily_analysis.sh

# Add weekly comprehensive analysis
0 9 * * 1 cd /path/to/container-codes && bash weekly_analysis.sh
```

### GitHub Actions Integration

```yaml
name: Weekly Comment Analysis
on:
  schedule:
    - cron: '0 9 * * 1'  # Monday 9 AM
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run analysis
        env:
          YOUTUBE_API_KEY: ${{ secrets.YOUTUBE_API_KEY }}
        run: bash scripts/weekly_analysis.sh
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: weekly-analysis
          path: tmp/
```

## Troubleshooting

### Common Issues

**API Key Problems**
```bash
# Verify key is set
echo $YOUTUBE_API_KEY

# Test API access
python3 -c "
import os
from googleapiclient.discovery import build
youtube = build('youtube', 'v3', developerKey=os.environ['YOUTUBE_API_KEY'])
print('API key works!')
"
```

**Quota Exceeded**
- Wait 24 hours for quota reset
- Reduce `max_comments` parameter
- Consider multiple API keys with rotation

**No Comments Found**
- Check if comments are enabled on the video
- Verify video is publicly accessible
- Try with a different video ID

For more troubleshooting, see [Troubleshooting Guide](../troubleshooting/api-issues.md).

## Next Steps

- Explore [Advanced Insights Tutorial](../tutorials/advanced-insights.md)
- Learn about [Custom Analysis](../tutorials/custom-analysis.md)
- Check out [API Reference](../api-reference/youtube-scraper.md)

---

*Need help? Check the [FAQ](../faq/youtube-analytics.md) or open an issue.*