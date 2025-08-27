# API Issues Troubleshooting

## Overview

This guide covers common problems with YouTube Data API access, authentication issues, and quota management. Most YouTube comment scraper problems relate to API configuration or usage limits.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [API Key Issues](#api-key-issues)
- [Quota Problems](#quota-problems)
- [Authentication Errors](#authentication-errors)
- [Network Issues](#network-issues)
- [Video Access Problems](#video-access-problems)
- [Performance Issues](#performance-issues)

## Quick Diagnostics

### Step 1: Test Your API Key

```bash
# Check if API key is set
echo $YOUTUBE_API_KEY

# Test API access
python3 -c "
import os
from googleapiclient.discovery import build
youtube = build('youtube', 'v3', developerKey=os.environ['YOUTUBE_API_KEY'])
response = youtube.videos().list(part='snippet', id='dQw4w9WgXcQ').execute()
print('✅ API key works! Video title:', response['items'][0]['snippet']['title'])
"
```

### Step 2: Check Quota Usage

```bash
# Visit Google Cloud Console
# Navigate to: APIs & Services > YouTube Data API v3 > Quotas
# Check your daily usage and limits
```

### Step 3: Test with Known Working Video

```bash
# Test with Rick Roll (known working video)
make youtube-comments URL='https://youtu.be/dQw4w9WgXcQ' MAX=5
```

## API Key Issues

### Problem: "API key required" Error

**Symptoms:**
```
ValueError: YouTube API key required. Set YOUTUBE_API_KEY environment variable or pass api_key parameter.
```

**Solutions:**

**Option 1: Environment Variable**
```bash
# Set for current session
export YOUTUBE_API_KEY='your_api_key_here'

# Make permanent (choose your shell)
echo 'export YOUTUBE_API_KEY="your_api_key_here"' >> ~/.bashrc    # Bash
echo 'export YOUTUBE_API_KEY="your_api_key_here"' >> ~/.zshrc     # Zsh

# Reload shell configuration
source ~/.bashrc  # or ~/.zshrc
```

**Option 2: Interactive Setup**
```bash
make youtube-setup
```

**Option 3: Pass Key Directly**
```bash
python3 scripts/youtube-comment-scraper.py VIDEO_ID --api-key YOUR_KEY
```

### Problem: "Invalid API Key" Error

**Symptoms:**
```
HttpError 400: API key not valid. Please pass a valid API key.
```

**Diagnostic Steps:**
1. **Verify Key Format**: API keys are typically 39 characters long
2. **Check for Extra Characters**: Remove quotes, spaces, or line breaks
3. **Regenerate Key**: Create a new API key in Google Cloud Console

**Solutions:**
```bash
# Test key format
python3 -c "
import os
key = os.environ.get('YOUTUBE_API_KEY', '')
print(f'Key length: {len(key)}')
print(f'Key preview: {key[:8]}...{key[-8:]}')
print(f'Contains spaces: {\" \" in key}')
"

# Clean key (remove common issues)
export YOUTUBE_API_KEY=$(echo "$YOUTUBE_API_KEY" | tr -d '[:space:]"')
```

### Problem: "API Not Enabled" Error

**Symptoms:**
```
HttpError 403: YouTube Data API has not been used in project
```

**Solution:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to "APIs & Services" → "Library"
4. Search for "YouTube Data API v3"
5. Click "ENABLE"

## Quota Problems

### Problem: "Quota Exceeded" Error

**Symptoms:**
```
HttpError 403: The request cannot be completed because you have exceeded your quota.
```

**Understanding Quotas:**
- **Default Quota**: 10,000 units per day
- **Comment Scraping Cost**: ~1-3 units per comment thread
- **Reset Time**: Daily quota resets at midnight Pacific Time

**Immediate Solutions:**

**Option 1: Wait for Reset**
```bash
# Check current time vs reset time (midnight PT)
date
echo "Quota resets at midnight Pacific Time"
```

**Option 2: Reduce Comment Count**
```bash
# Instead of default 200 comments
make youtube-comments URL='https://youtu.be/VIDEO_ID' MAX=50

# For quick testing
make youtube-comments URL='https://youtu.be/VIDEO_ID' MAX=10
```

**Option 3: Request Quota Increase**
1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "APIs & Services" → "YouTube Data API v3" → "Quotas"
3. Click "EDIT QUOTAS" and request increase
4. Provide justification for your use case

**Long-term Solutions:**

**Monitor Quota Usage**
```python
# Create quota monitoring script
import os
from googleapiclient.discovery import build

def check_quota_usage():
    # This is an estimate - Google doesn't provide real-time quota info
    # Track your requests manually
    daily_requests = 0  # Track this yourself
    quota_limit = 10000
    remaining = quota_limit - daily_requests
    
    print(f"Estimated quota used: {daily_requests}")
    print(f"Estimated remaining: {remaining}")
    print(f"Percentage used: {(daily_requests/quota_limit)*100:.1f}%")
```

**Optimize API Usage**
```bash
# Use time-based ordering (more efficient)
python3 scripts/youtube-comment-scraper.py VIDEO_ID --order time

# Skip insights for faster processing
python3 scripts/youtube-comment-scraper.py VIDEO_ID --no-insights

# Cache results to avoid re-scraping
cp tmp/video_analysis.json cache/
```

### Problem: "Comments Disabled" Error

**Symptoms:**
```
Comments are disabled for this video or quota exceeded
```

**Diagnostic Steps:**
1. **Check Video Directly**: Visit YouTube and see if you can view comments
2. **Try Different Video**: Test with known working video
3. **Check Video Privacy**: Ensure video is public

**Solutions:**
```bash
# Test with known working videos
WORKING_VIDEOS=(
    "dQw4w9WgXcQ"  # Rick Roll
    "9bZkp7q19f0"  # Gangnam Style
    "kffacxfA7G4"  # Baby Shark
)

for video in "${WORKING_VIDEOS[@]}"; do
    echo "Testing: $video"
    make youtube-comments URL="$video" MAX=5
    break
done
```

## Authentication Errors

### Problem: "Access Denied" Error

**Symptoms:**
```
HttpError 403: Access denied. Check your API key and project settings.
```

**Solutions:**

**1. Verify Project Settings**
- Ensure API key belongs to correct Google Cloud project
- Check that YouTube Data API v3 is enabled for the project
- Verify billing is enabled (required for some quotas)

**2. Check API Key Restrictions**
```bash
# Remove API key restrictions temporarily for testing
# Go to Google Cloud Console > Credentials > Your API Key
# Under "API restrictions", select "Don't restrict key"
# Under "Application restrictions", select "None"
```

**3. Create New API Key**
If restrictions can't be modified:
1. Go to Google Cloud Console → Credentials
2. Click "CREATE CREDENTIALS" → "API key"
3. Copy the new key
4. Update your environment variable

## Network Issues

### Problem: Connection Timeouts

**Symptoms:**
```
requests.exceptions.ConnectTimeout: HTTPSConnectionPool
```

**Solutions:**

**1. Check Internet Connection**
```bash
# Test connectivity
ping google.com
curl -I https://youtube.googleapis.com/
```

**2. Configure Proxy (if needed)**
```bash
# Set proxy environment variables
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
```

**3. Increase Timeout**
```python
# Custom timeout in your scripts
import socket
socket.setdefaulttimeout(30)  # 30 seconds
```

### Problem: SSL Certificate Errors

**Symptoms:**
```
requests.exceptions.SSLError: [SSL: CERTIFICATE_VERIFY_FAILED]
```

**Solutions:**

**1. Update Certificates**
```bash
# macOS
/Applications/Python\ 3.x/Install\ Certificates.command

# Linux
sudo apt-get update && sudo apt-get install ca-certificates

# Python packages
pip install --upgrade certifi
```

**2. Corporate Network Issues**
```bash
# If behind corporate firewall, may need custom certificates
# Contact your IT department
```

## Video Access Problems

### Problem: "Video Not Found" Error

**Symptoms:**
```
ValueError: Video not found: VIDEO_ID
```

**Diagnostic Steps:**
```bash
# Test video ID extraction
python3 -c "
from src.app.youtube_scraper import YouTubeCommentScraper
scraper = YouTubeCommentScraper()
try:
    video_id = scraper.extract_video_id('YOUR_URL_HERE')
    print(f'Extracted ID: {video_id}')
except ValueError as e:
    print(f'Error: {e}')
"
```

**Solutions:**

**1. Verify URL Format**
```bash
# Supported formats
https://www.youtube.com/watch?v=dQw4w9WgXcQ  ✅
https://youtu.be/dQw4w9WgXcQ               ✅
https://youtube.com/embed/dQw4w9WgXcQ       ✅
dQw4w9WgXcQ                                ✅

# Unsupported formats
https://youtube.com/playlist?list=...       ❌
https://youtube.com/channel/...             ❌
```

**2. Check Video Availability**
- Ensure video is public (not private/unlisted)
- Video may be region-locked
- Video may have been deleted

### Problem: "Private Video" Error

**Symptoms:**
Video exists but scraper can't access it.

**Solutions:**
- Only public videos can be analyzed
- Ask video owner to make video public
- Use a different public video for testing

## Performance Issues

### Problem: Slow Comment Scraping

**Symptoms:**
Scraping takes much longer than expected.

**Solutions:**

**1. Optimize Request Parameters**
```bash
# Use time ordering (faster)
python3 scripts/youtube-comment-scraper.py VIDEO_ID --order time

# Limit comments for testing
python3 scripts/youtube-comment-scraper.py VIDEO_ID --max-comments 100
```

**2. Skip Heavy Analysis**
```bash
# Skip insights generation
python3 scripts/youtube-comment-scraper.py VIDEO_ID --no-insights

# Only export, no display
python3 scripts/youtube-comment-scraper.py VIDEO_ID --quiet
```

**3. Monitor Progress**
```python
# Add progress tracking to your scripts
for i, comment in enumerate(scraper.scrape_comments(video_id), 1):
    if i % 50 == 0:
        print(f"Scraped {i} comments...")
```

### Problem: Memory Usage Too High

**Symptoms:**
Script uses excessive memory with large comment sets.

**Solutions:**

**1. Process in Batches**
```python
# Instead of loading all comments at once
def process_comments_in_batches(video_id, batch_size=100):
    batch = []
    for comment in scraper.scrape_comments(video_id):
        batch.append(comment)
        if len(batch) >= batch_size:
            # Process batch
            analyzer = CommentAnalyzer(batch)
            # Do analysis...
            batch = []  # Clear memory
    
    # Process remaining
    if batch:
        analyzer = CommentAnalyzer(batch)
```

**2. Stream Processing**
```python
# Process comments one at a time
for comment in scraper.scrape_comments(video_id):
    # Process individual comment
    # Don't store all in memory
    process_single_comment(comment)
```

## Getting Help

### Debug Mode

Enable verbose output for debugging:

```bash
# Add debug output to your analysis
python3 -c "
import logging
logging.basicConfig(level=logging.DEBUG)

from src.app.youtube_scraper import get_comments_batch
comments, video_info = get_comments_batch('dQw4w9WgXcQ', max_comments=5)
"
```

### Common Error Codes

| Error Code | Meaning | Solution |
|------------|---------|----------|
| 400 | Bad Request | Check URL format and parameters |
| 401 | Unauthorized | Verify API key |
| 403 | Forbidden | Check quota, API enabled, permissions |
| 404 | Not Found | Video doesn't exist or is private |
| 429 | Too Many Requests | Rate limiting, wait and retry |
| 500 | Internal Server Error | YouTube API issue, try again later |

### Create Minimal Test Case

```python
#!/usr/bin/env python3
"""Minimal test case for debugging"""

import os
from src.app.youtube_scraper import YouTubeCommentScraper

def test_api_connection():
    try:
        # Test 1: API key
        api_key = os.environ.get('YOUTUBE_API_KEY')
        if not api_key:
            print("❌ No API key found")
            return False
        print(f"✅ API key found: {api_key[:8]}...")
        
        # Test 2: Scraper initialization
        scraper = YouTubeCommentScraper()
        print("✅ Scraper initialized")
        
        # Test 3: Video info
        video_info = scraper.get_video_info('dQw4w9WgXcQ')
        print(f"✅ Video info: {video_info['title']}")
        
        # Test 4: Single comment
        comments = list(scraper.scrape_comments('dQw4w9WgXcQ', max_comments=1))
        print(f"✅ Comments: {len(comments)} retrieved")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    test_api_connection()
```

### Report Issues

When reporting problems, include:

1. **Error Message**: Complete error text
2. **Command Used**: Exact command that failed
3. **Environment**: Python version, OS, package versions
4. **Video ID**: Specific video that fails (if relevant)
5. **API Key Status**: Whether key works with other tools

```bash
# Gather environment info
python3 --version
pip list | grep google
echo $YOUTUBE_API_KEY | cut -c1-8  # First 8 chars only
```

---

*For additional help, see [FAQ](../faq/youtube-analytics.md) or open an issue in the repository.*