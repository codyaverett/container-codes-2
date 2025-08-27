# YouTube Scraper API Reference

## Overview

The YouTube Scraper API provides programmatic access to YouTube comment extraction and analysis. This reference covers all classes, methods, and functions available in the `src.app.youtube_scraper` module.

## Table of Contents

- [Classes](#classes)
  - [YouTubeCommentScraper](#youtubecommentscraper)
  - [CommentAnalyzer](#commentanalyzer)
- [Functions](#functions)
  - [get_comments_batch](#get_comments_batch)
- [Data Structures](#data-structures)
- [Error Handling](#error-handling)
- [Examples](#examples)

## Classes

### YouTubeCommentScraper

Main class for scraping YouTube comments using the official YouTube Data API v3.

#### Constructor

```python
YouTubeCommentScraper(api_key: Optional[str] = None)
```

**Parameters:**
- `api_key` (str, optional): YouTube Data API v3 key. If None, reads from `YOUTUBE_API_KEY` environment variable.

**Raises:**
- `ValueError`: If no API key is provided or found in environment.

**Example:**
```python
from src.app.youtube_scraper import YouTubeCommentScraper

# Using environment variable
scraper = YouTubeCommentScraper()

# Using explicit API key
scraper = YouTubeCommentScraper(api_key='your_api_key_here')
```

#### Methods

##### extract_video_id

```python
extract_video_id(url: str) -> str
```

Extract video ID from various YouTube URL formats.

**Parameters:**
- `url` (str): YouTube video URL or video ID

**Returns:**
- `str`: 11-character video ID

**Raises:**
- `ValueError`: If URL format is invalid or video ID cannot be extracted

**Supported URL Formats:**
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://youtube.com/embed/VIDEO_ID`
- `VIDEO_ID` (bare video ID)

**Example:**
```python
video_id = scraper.extract_video_id('https://youtu.be/dQw4w9WgXcQ')
print(video_id)  # Output: dQw4w9WgXcQ
```

##### get_video_info

```python
get_video_info(video_id: str) -> Dict
```

Get basic video information and statistics.

**Parameters:**
- `video_id` (str): YouTube video ID

**Returns:**
- `Dict`: Video information with keys:
  - `id` (str): Video ID
  - `title` (str): Video title
  - `channel` (str): Channel name
  - `published_at` (str): Publication timestamp
  - `view_count` (int): Number of views
  - `like_count` (int): Number of likes
  - `comment_count` (int): Number of comments
  - `description` (str): Video description
  - `tags` (List[str]): Video tags

**Example:**
```python
video_info = scraper.get_video_info('dQw4w9WgXcQ')
print(f"Title: {video_info['title']}")
print(f"Views: {video_info['view_count']:,}")
```

##### scrape_comments

```python
scrape_comments(video_id: str, max_comments: Optional[int] = None, 
                order: str = 'time') -> Iterator[Dict]
```

Scrape comments from a YouTube video with pagination.

**Parameters:**
- `video_id` (str): YouTube video ID
- `max_comments` (int, optional): Maximum comments to retrieve. None for all.
- `order` (str): Comment order. Options: 'time', 'relevance'. Default: 'time'.

**Yields:**
- `Dict`: Comment data (see [Comment Structure](#comment-structure))

**Example:**
```python
# Get first 100 comments
for comment in scraper.scrape_comments('dQw4w9WgXcQ', max_comments=100):
    print(f"{comment['author']}: {comment['text'][:50]}...")
    
# Get all comments ordered by relevance
comments = list(scraper.scrape_comments('dQw4w9WgXcQ', order='relevance'))
```

##### Export Methods

```python
export_to_json(comments: List[Dict], output_file: str) -> None
export_to_csv(comments: List[Dict], output_file: str) -> None
export_to_markdown(comments: List[Dict], output_file: str, 
                   video_info: Optional[Dict] = None) -> None
```

Export comments to various formats.

**Parameters:**
- `comments` (List[Dict]): List of comment dictionaries
- `output_file` (str): Output file path
- `video_info` (Dict, optional): Video information for context (markdown only)

**Example:**
```python
comments = list(scraper.scrape_comments('dQw4w9WgXcQ', max_comments=50))

# Export to different formats
scraper.export_to_json(comments, 'tmp/comments.json')
scraper.export_to_csv(comments, 'tmp/comments.csv')
scraper.export_to_markdown(comments, 'tmp/comments.md', video_info)
```

### CommentAnalyzer

Advanced analysis engine for extracting insights from scraped comments.

#### Constructor

```python
CommentAnalyzer(comments: List[Dict])
```

**Parameters:**
- `comments` (List[Dict]): List of comment dictionaries from scraper

**Example:**
```python
from src.app.youtube_scraper import CommentAnalyzer

analyzer = CommentAnalyzer(comments)
```

#### Methods

##### get_basic_stats

```python
get_basic_stats() -> Dict
```

Get basic statistical information about comments.

**Returns:**
- `Dict`: Statistics with keys:
  - `total_comments` (int): Total number of comments
  - `top_level_comments` (int): Number of top-level comments
  - `replies` (int): Number of replies
  - `total_likes` (int): Sum of all likes
  - `avg_likes` (float): Average likes per comment
  - `avg_comment_length` (float): Average character length
  - `high_engagement_count` (int): Comments with above-average engagement
  - `most_active_authors` (List[Tuple]): Top contributors
  - `reply_ratio` (float): Ratio of replies to total comments

**Example:**
```python
stats = analyzer.get_basic_stats()
print(f"Total comments: {stats['total_comments']:,}")
print(f"Average engagement: {stats['avg_likes']:.1f} likes")
```

##### extract_keywords

```python
extract_keywords(min_word_length: int = 4, top_n: int = 15) -> List[Tuple[str, int]]
```

Extract most common keywords from comments.

**Parameters:**
- `min_word_length` (int): Minimum word length to consider. Default: 4.
- `top_n` (int): Number of top keywords to return. Default: 15.

**Returns:**
- `List[Tuple[str, int]]`: List of (keyword, count) tuples

**Example:**
```python
keywords = analyzer.extract_keywords(min_word_length=5, top_n=10)
for word, count in keywords:
    print(f"{word}: {count}")
```

##### find_questions

```python
find_questions(top_n: int = 10) -> List[Dict]
```

Identify questions in comments for FAQ creation.

**Parameters:**
- `top_n` (int): Maximum number of questions to return

**Returns:**
- `List[Dict]`: Questions sorted by engagement with keys:
  - `text` (str): Question text (truncated)
  - `author` (str): Question author
  - `likes` (int): Number of likes
  - `is_reply` (bool): Whether it's a reply

**Example:**
```python
questions = analyzer.find_questions(5)
for q in questions:
    print(f"Q: {q['text']}")
    print(f"   By: {q['author']} ({q['likes']} likes)")
```

##### suggest_future_topics

```python
suggest_future_topics(top_n: int = 8) -> List[Dict]
```

Suggest future video topics based on comment analysis.

**Parameters:**
- `top_n` (int): Maximum number of suggestions to return

**Returns:**
- `List[Dict]`: Topic suggestions with keys:
  - `title` (str): Suggested video title
  - `based_on_topic` (str): Source topic/keyword
  - `mentions` (int): Number of mentions
  - `avg_engagement` (float): Average engagement
  - `priority` (str): Priority level ('High', 'Medium', 'Emerging')

**Example:**
```python
suggestions = analyzer.suggest_future_topics(5)
for suggestion in suggestions:
    priority_emoji = {'High': '🔥', 'Medium': '⭐', 'Emerging': '💡'}[suggestion['priority']]
    print(f"{priority_emoji} {suggestion['title']}")
```

##### analyze_audience_level

```python
analyze_audience_level() -> Dict
```

Analyze technical sophistication of the audience.

**Returns:**
- `Dict`: Audience analysis with keys:
  - `dominant_level` (str): Primary audience level ('beginner', 'intermediate', 'advanced')
  - `distribution` (Dict[str, float]): Percentage distribution
  - `total_classified` (int): Number of comments classified

**Example:**
```python
audience = analyzer.analyze_audience_level()
print(f"Primary audience: {audience['dominant_level'].title()}")
print(f"Distribution: {audience['distribution']}")
```

##### generate_insights_summary

```python
generate_insights_summary() -> str
```

Generate comprehensive text summary of all insights.

**Returns:**
- `str`: Formatted insights summary

**Example:**
```python
insights = analyzer.generate_insights_summary()
print(insights)
# Displays comprehensive analysis with emojis and formatting
```

## Functions

### get_comments_batch

```python
get_comments_batch(video_url: str, max_comments: Optional[int] = None,
                   output_format: str = 'json', output_file: Optional[str] = None,
                   api_key: Optional[str] = None, show_insights: bool = True) -> Tuple[List[Dict], Dict]
```

Convenience function to scrape comments and get video info in one call.

**Parameters:**
- `video_url` (str): YouTube video URL or ID
- `max_comments` (int, optional): Maximum comments to retrieve
- `output_format` (str): Output format ('json', 'csv', 'markdown'). Default: 'json'.
- `output_file` (str, optional): Output file path (auto-generated if None)
- `api_key` (str, optional): YouTube API key
- `show_insights` (bool): Whether to generate and display insights. Default: True.

**Returns:**
- `Tuple[List[Dict], Dict]`: (comments_list, video_info)

**Example:**
```python
from src.app.youtube_scraper import get_comments_batch

# Simple usage
comments, video_info = get_comments_batch('https://youtu.be/dQw4w9WgXcQ')

# Advanced usage
comments, video_info = get_comments_batch(
    video_url='dQw4w9WgXcQ',
    max_comments=200,
    output_format='csv',
    output_file='tmp/my_analysis.csv',
    show_insights=True
)
```

## Data Structures

### Comment Structure

Each comment is represented as a dictionary with the following keys:

```python
{
    'comment_id': str,           # Unique comment identifier
    'author': str,               # Author's display name  
    'author_channel_id': str,    # Author's channel ID
    'text': str,                 # Processed comment text
    'text_original': str,        # Original raw comment text
    'like_count': int,           # Number of likes
    'published_at': str,         # ISO timestamp when posted
    'updated_at': str,           # ISO timestamp when last modified
    'is_reply': bool,            # Whether this is a reply
    'parent_comment_id': str,    # Parent comment ID (if reply)
    'can_reply': bool            # Whether replies are allowed
}
```

### Video Info Structure

Video information is returned as:

```python
{
    'id': str,                   # Video ID
    'title': str,                # Video title
    'channel': str,              # Channel name
    'published_at': str,         # Publication timestamp
    'view_count': int,           # Number of views
    'like_count': int,           # Number of likes
    'comment_count': int,        # Number of comments
    'description': str,          # Video description
    'tags': List[str]            # Video tags
}
```

## Error Handling

### Common Exceptions

**ValueError**
- Invalid video URL or ID format
- Missing API key

**HttpError** (from Google API)
- Invalid API key
- Quota exceeded
- Video not found
- Comments disabled

**Exception** (Generic)
- Network connectivity issues
- API service unavailable

### Example Error Handling

```python
from googleapiclient.errors import HttpError

try:
    comments, video_info = get_comments_batch('invalid_video_id')
except ValueError as e:
    print(f"Invalid input: {e}")
except HttpError as e:
    if e.resp.status == 403:
        print("API quota exceeded or comments disabled")
    elif e.resp.status == 404:
        print("Video not found")
    else:
        print(f"API error: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
```

## Examples

### Basic Comment Scraping

```python
from src.app.youtube_scraper import YouTubeCommentScraper

# Initialize scraper
scraper = YouTubeCommentScraper()

# Get video info
video_info = scraper.get_video_info('dQw4w9WgXcQ')
print(f"Analyzing: {video_info['title']}")

# Scrape comments
comments = []
for comment in scraper.scrape_comments('dQw4w9WgXcQ', max_comments=100):
    comments.append(comment)
    if len(comments) % 25 == 0:
        print(f"Scraped {len(comments)} comments...")

print(f"Total comments scraped: {len(comments)}")
```

### Advanced Analysis

```python
from src.app.youtube_scraper import get_comments_batch, CommentAnalyzer

# Batch scraping with analysis
comments, video_info = get_comments_batch(
    'https://youtu.be/dQw4w9WgXcQ',
    max_comments=500,
    show_insights=False  # We'll do custom analysis
)

# Create analyzer
analyzer = CommentAnalyzer(comments)

# Get comprehensive insights
stats = analyzer.get_basic_stats()
keywords = analyzer.extract_keywords(top_n=20)
questions = analyzer.find_questions(10)
suggestions = analyzer.suggest_future_topics(8)
audience = analyzer.analyze_audience_level()

# Custom processing
print(f"📊 Analysis of '{video_info['title']}'")
print(f"Comments: {stats['total_comments']:,}")
print(f"Engagement: {stats['avg_likes']:.1f} avg likes")
print(f"Audience: {audience['dominant_level'].title()}")

print("\\n🎯 Top Topics:")
for word, count in keywords[:5]:
    print(f"  {word}: {count} mentions")

print("\\n🚀 Content Suggestions:")
for suggestion in suggestions[:3]:
    print(f"  • {suggestion['title']}")
```

### Custom Export with Analysis

```python
import json
from pathlib import Path
from src.app.youtube_scraper import YouTubeCommentScraper, CommentAnalyzer

def analyze_and_export(video_url, output_dir="tmp"):
    """Custom function to scrape, analyze, and export with metadata."""
    
    # Setup
    scraper = YouTubeCommentScraper()
    video_id = scraper.extract_video_id(video_url)
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    # Scrape data
    video_info = scraper.get_video_info(video_id)
    comments = list(scraper.scrape_comments(video_id, max_comments=300))
    
    # Analyze
    analyzer = CommentAnalyzer(comments)
    
    # Create comprehensive export
    export_data = {
        'metadata': {
            'scraped_at': datetime.now().isoformat(),
            'video_info': video_info,
            'total_comments_scraped': len(comments)
        },
        'comments': comments,
        'analysis': {
            'basic_stats': analyzer.get_basic_stats(),
            'keywords': analyzer.extract_keywords(),
            'questions': analyzer.find_questions(),
            'topic_suggestions': analyzer.suggest_future_topics(),
            'audience_level': analyzer.analyze_audience_level()
        },
        'insights_summary': analyzer.generate_insights_summary()
    }
    
    # Export
    filename = f"{video_info['title'].lower().replace(' ', '_')[:50]}_{datetime.now().strftime('%Y%m%d')}.json"
    output_file = output_path / filename
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(export_data, f, indent=2, ensure_ascii=False, default=str)
    
    print(f"✅ Complete analysis exported to: {output_file}")
    return export_data

# Usage
result = analyze_and_export('https://youtu.be/dQw4w9WgXcQ')
```

## Performance Notes

- **Rate Limiting**: Built-in 1-second delay between API requests
- **Memory Usage**: Comments are processed in batches for large datasets
- **API Quota**: Each comment thread costs 1 quota unit, replies cost additional units
- **Caching**: Consider implementing caching for repeated analysis of same videos

## See Also

- [User Guide](../user-guides/youtube-analytics.md) - Step-by-step usage instructions
- [Troubleshooting](../troubleshooting/api-issues.md) - Common issues and solutions
- [Examples](../tutorials/) - Hands-on tutorials

---

*API Reference last updated: 2024-01-27*