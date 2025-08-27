# YouTube Comment Analysis

## Overview

The YouTube Comment Scraper is a defensive tool for extracting and analyzing
YouTube comments using the official YouTube Data API v3. This tool respects
YouTube's Terms of Service and implements proper rate limiting for ethical data
collection.

## Features

- **Official API Integration**: Uses YouTube Data API v3 for legitimate access
- **Multiple Export Formats**: JSON, CSV, and Markdown output formats
- **Rate Limiting**: Built-in respect for API quotas and terms of service
- **Comment Hierarchy**: Handles both top-level comments and replies
- **Flexible Filtering**: Support for comment ordering and quantity limits
- **Comprehensive Metadata**: Extracts author, timestamps, engagement metrics
- **Security-First**: Environment variable API key handling

## Setup

### 1. Get YouTube Data API v3 Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the YouTube Data API v3
4. Create credentials (API key)
5. Set the API key as an environment variable:

```bash
export YOUTUBE_API_KEY='your_api_key_here'
```

Add this to your `~/.bashrc` or `~/.zshrc` to persist across sessions.

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Interactive Setup

Run the setup command for guided API key configuration:

```bash
make youtube-setup
```

## Usage

### Command Line Interface

Basic usage:

```bash
# Scrape all comments from a video (saves to tmp/ directory)
python3 scripts/youtube-comment-scraper.py https://www.youtube.com/watch?v=VIDEO_ID

# Limit to 100 comments
python3 scripts/youtube-comment-scraper.py VIDEO_ID --max-comments 100

# Export to CSV (saves to tmp/ directory)
python3 scripts/youtube-comment-scraper.py https://youtu.be/VIDEO_ID --format csv

# Custom output file (automatically uses tmp/ directory if no path specified)
python3 scripts/youtube-comment-scraper.py VIDEO_ID --output my_analysis.json

# Specify full path to save outside tmp directory
python3 scripts/youtube-comment-scraper.py VIDEO_ID --output data/comments.json
```

### Makefile Commands

```bash
# Setup API key interactively
make youtube-setup

# Scrape comments with default settings (saves to tmp/ directory)
make youtube-comments URL='https://youtu.be/VIDEO_ID'

# Limit number of comments (saves to tmp/ directory)
make youtube-comments URL='https://youtu.be/VIDEO_ID' MAX=100
```

### Python Module Usage

```python
from src.app.youtube_scraper import YouTubeCommentScraper, get_comments_batch

# Quick batch processing
comments, video_info = get_comments_batch(
    'https://www.youtube.com/watch?v=VIDEO_ID',
    max_comments=100,
    output_format='json'
)

# Advanced usage with custom scraper
scraper = YouTubeCommentScraper(api_key='your_key_here')
video_id = scraper.extract_video_id('https://youtu.be/VIDEO_ID')

# Get video information
video_info = scraper.get_video_info(video_id)

# Scrape comments with pagination
for comment in scraper.scrape_comments(video_id, max_comments=50):
    print(f"{comment['author']}: {comment['text'][:100]}...")
```

## Command Options

| Option               | Description                             | Example                  |
| -------------------- | --------------------------------------- | ------------------------ |
| `--max-comments, -n` | Maximum number of comments to retrieve  | `--max-comments 100`     |
| `--format, -f`       | Output format (json, csv, markdown)     | `--format csv`           |
| `--output, -o`       | Custom output file path                 | `--output comments.json` |
| `--order`            | Comment ordering (time, relevance)      | `--order relevance`      |
| `--api-key`          | YouTube API key (or use env var)        | `--api-key YOUR_KEY`     |
| `--quiet, -q`        | Suppress progress output                | `--quiet`                |
| `--no-export`        | Don't export to file, show summary only | `--no-export`            |
| `--setup`            | Interactive API key setup               | `--setup`                |

## Output Formats

### JSON Format

```json
[
  {
    "comment_id": "ABC123",
    "author": "john_doe",
    "author_channel_id": "UC...",
    "text": "Great video!",
    "text_original": "Great video!",
    "like_count": 5,
    "published_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "is_reply": false,
    "parent_comment_id": null,
    "can_reply": true
  }
]
```

### CSV Format

Standard CSV with all comment fields as columns.

### Markdown Format

```markdown
# YouTube Comments: Video Title

**Channel:** Channel Name **Published:** 2024-01-15T10:30:00Z **View Count:**
1,234 **Comment Count:** 56

---

## Comment 1

**Author:** john_doe **Posted:** 2024-01-15T10:30:00Z **Likes:** 5

Great video! Really helpful explanation.

---
```

## Data Fields

Each comment includes the following information:

- `comment_id`: Unique comment identifier
- `author`: Author's display name
- `author_channel_id`: Author's channel ID
- `text`: Processed comment text (with links, etc.)
- `text_original`: Original raw comment text
- `like_count`: Number of likes on the comment
- `published_at`: When the comment was posted
- `updated_at`: When the comment was last modified
- `is_reply`: Whether this is a reply to another comment
- `parent_comment_id`: ID of parent comment (if reply)
- `can_reply`: Whether replies are allowed

## Rate Limiting and Ethics

### Built-in Protection

- **API Quota Respect**: 1-second delay between requests
- **Error Handling**: Graceful handling of API errors and limits
- **Terms Compliance**: Uses official API endpoints only
- **Public Data Only**: Only accesses publicly available comments

### Best Practices

1. **Respect Quotas**: YouTube API has daily quota limits
2. **Cache Results**: Avoid re-scraping the same data repeatedly
3. **Privacy Awareness**: Remember that comments contain personal information
4. **Purpose Limitation**: Use data only for legitimate research/analysis
5. **Data Retention**: Delete scraped data when no longer needed

## Analysis Examples

### Common Use Cases

1. **Audience Engagement Analysis**

   - Comment sentiment analysis
   - Popular topics identification
   - Engagement pattern tracking

2. **Content Performance Metrics**

   - Comment-to-view ratios
   - Response time analysis
   - Community interaction patterns

3. **Community Management**
   - Identifying frequently asked questions
   - Monitoring feedback trends
   - Understanding audience preferences

### Sample Analysis Script

```python
import json
from collections import Counter

# Load scraped comments
with open('comments.json', 'r') as f:
    comments = json.load(f)

# Basic statistics
total_comments = len(comments)
total_likes = sum(c['like_count'] for c in comments)
avg_likes = total_likes / total_comments

print(f"Total Comments: {total_comments}")
print(f"Average Likes per Comment: {avg_likes:.1f}")

# Top contributors
authors = Counter(c['author'] for c in comments)
print("Top Contributors:")
for author, count in authors.most_common(5):
    print(f"  {author}: {count} comments")

# Most engaging comments
top_comments = sorted(comments, key=lambda x: x['like_count'], reverse=True)[:5]
print("\nMost Liked Comments:")
for comment in top_comments:
    print(f"  {comment['author']} ({comment['like_count']} likes): {comment['text'][:100]}...")
```

## Troubleshooting

### Common Issues

1. **API Key Not Found**

   - Run `make youtube-setup` for interactive setup
   - Verify `YOUTUBE_API_KEY` environment variable is set
   - Check API key has YouTube Data API v3 enabled

2. **Quota Exceeded**

   - Wait 24 hours for quota reset
   - Reduce `max_comments` parameter
   - Consider using multiple API keys with rotation

3. **Comments Disabled**

   - Some videos have comments disabled
   - Tool will report this and exit gracefully

4. **Invalid Video URL**
   - Supports multiple YouTube URL formats
   - Can also accept bare video IDs
   - Check video exists and is publicly accessible

### Debug Mode

For detailed error information:

```bash
python3 scripts/youtube-comment-scraper.py VIDEO_ID --verbose
```

## Integration with ContainerCodes Workflow

This tool integrates with the existing ContainerCodes project structure:

- **Makefile Integration**: Available via `make youtube-comments`
- **Content Analysis**: Analyze comments on ContainerCodes episodes
- **Audience Insights**: Understand viewer questions and feedback
- **Content Planning**: Use comment data to inform future episodes

## Security Considerations

- **API Keys**: Never commit API keys to version control
- **Data Privacy**: Comments contain personal information
- **Storage**: Store scraped data securely and limit retention
- **Access Control**: Limit access to scraped data appropriately

## Legal and Ethical Notes

- Uses official YouTube Data API v3
- Respects YouTube Terms of Service
- Only accesses publicly available data
- Implements appropriate rate limiting
- Designed for legitimate research and analysis purposes

For questions about usage or issues with the tool, please refer to the project
documentation or open an issue in the repository.
