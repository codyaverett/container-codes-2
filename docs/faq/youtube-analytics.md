# YouTube Analytics FAQ

## General Questions

### Q: What does the YouTube comment scraper do?

**A:** The scraper extracts comments from YouTube videos using the official YouTube Data API v3, then provides intelligent analysis including:
- Basic engagement statistics
- Keyword and topic extraction
- Question identification for FAQs
- Future content suggestions based on audience interests
- Audience technical level analysis

### Q: Is this tool free to use?

**A:** The tool itself is free, but you need:
- **YouTube Data API v3 key**: Free with daily quotas (10,000 units/day)
- **Anthropic API key**: Optional, for enhanced AI analysis (pay-per-use)

### Q: How many comments can I analyze per day?

**A:** With the free YouTube API quota (10,000 units), you can typically analyze:
- ~3,000-5,000 individual comments
- ~10-20 videos with 200 comments each
- The exact number depends on reply threads and API efficiency

## Setup & Installation

### Q: How do I get a YouTube API key?

**A:** Follow these steps:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project (or select existing)
3. Enable "YouTube Data API v3"
4. Navigate to Credentials → Create Credentials → API Key
5. Copy your key and set: `export YOUTUBE_API_KEY='your_key'`

### Q: The installation fails with "GoogleAPI client not found"

**A:** Install the required dependencies:
```bash
pip install -r requirements.txt
```

If you don't have the requirements file:
```bash
pip install google-api-python-client>=2.0.0
```

### Q: How do I know if my API key is working?

**A:** Test it quickly:
```bash
# Test with make command
make youtube-setup

# Or test directly
python3 -c "
import os
from googleapiclient.discovery import build
youtube = build('youtube', 'v3', developerKey=os.environ['YOUTUBE_API_KEY'])
print('✅ API key works!')
"
```

## Usage Questions

### Q: What video URL formats are supported?

**A:** All common YouTube URL formats work:
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://youtube.com/embed/VIDEO_ID`
- `VIDEO_ID` (just the 11-character ID)

### Q: Can I analyze private or unlisted videos?

**A:** No, only public videos can be analyzed. The YouTube Data API only provides access to public content.

### Q: How do I analyze multiple videos at once?

**A:** Use a batch script:
```bash
#!/bin/bash
VIDEOS=("VIDEO_ID_1" "VIDEO_ID_2" "VIDEO_ID_3")

for video in "${VIDEOS[@]}"; do
  echo "Analyzing: $video"
  make youtube-comments URL="$video" MAX=200
  sleep 2  # Rate limiting
done
```

### Q: Why are my comment counts different from what I see on YouTube?

**A:** Several reasons:
- **API vs Display**: YouTube's display count may include private/deleted comments
- **Threading**: YouTube groups replies differently than the API
- **Pagination**: You might be hitting the comment limit before all comments are retrieved
- **Time Difference**: Comments may have been added/removed since your analysis

### Q: Can I get comments from a specific time period?

**A:** The API doesn't directly support date filtering, but you can:
- Use `--order time` to get chronological comments
- Filter results post-processing by `published_at` timestamp
- Set reasonable `max_comments` limits to focus on recent comments

## Analysis Features

### Q: What does the "Engagement Health" score mean?

**A:** It's based on average likes per comment:
- 🟢 **Excellent** (>5 avg likes): High audience engagement
- 🟡 **Good** (2-5 avg likes): Moderate engagement
- 🔴 **Needs Improvement** (<2 avg likes): Low engagement

### Q: How accurate are the topic suggestions?

**A:** The suggestions are based on:
- **Keyword frequency** in comments
- **Engagement levels** (likes on relevant comments)  
- **Question patterns** from viewers
- **Container technology mapping** specific to your niche

They provide good directional guidance but should be combined with your content strategy expertise.

### Q: What's the difference between "High", "Medium", and "Emerging" priority topics?

**A:**
- 🔥 **High**: Many mentions + high engagement
- ⭐ **Medium**: Solid interest but moderate engagement
- 💡 **Emerging**: New trends identified from questions
- 📹 **Standard**: General topic suggestions

### Q: Can I customize the topic suggestions?

**A:** Yes, you can modify the topic mapping in the code:
1. Edit `src/app/youtube_scraper.py`
2. Find the `container_topics` dictionary in `suggest_future_topics()`
3. Add your own keywords and suggested titles
4. Modify `tech_patterns` for emerging topic detection

## Technical Issues

### Q: I'm getting "Quota exceeded" errors

**A:** Solutions:
- **Wait**: Quota resets at midnight Pacific Time
- **Reduce comments**: Use `MAX=50` instead of default 200
- **Request increase**: Apply for higher quota in Google Cloud Console
- **Monitor usage**: Track your daily API calls

### Q: The scraper is very slow

**A:** Speed optimization:
```bash
# Skip detailed insights
python3 scripts/youtube-comment-scraper.py VIDEO_ID --no-insights

# Reduce comment count
make youtube-comments URL='https://youtu.be/VIDEO_ID' MAX=100

# Use quiet mode
python3 scripts/youtube-comment-scraper.py VIDEO_ID --quiet
```

### Q: Comments are disabled error, but I see comments on YouTube

**A:** This can happen when:
- Comments were recently disabled
- Video is in a restricted category
- Geographic restrictions apply
- API quota is actually exceeded (misleading error message)

Try a different video to confirm your setup works.

### Q: Where are my output files saved?

**A:** All files are automatically saved to the `tmp/` directory:
- `tmp/video_title_timestamp.json` (comment data)
- `tmp/video_title_timestamp_insights.txt` (analysis)

The `tmp/` directory is ignored by git, so files won't be committed accidentally.

## Advanced Usage

### Q: Can I integrate this with other tools?

**A:** Yes, the Python module can be imported:
```python
from src.app.youtube_scraper import get_comments_batch, CommentAnalyzer

# Get data
comments, video_info = get_comments_batch('VIDEO_ID')

# Custom analysis
analyzer = CommentAnalyzer(comments)
insights = analyzer.generate_insights_summary()

# Integration with your tools
send_to_slack(insights)
update_content_calendar(analyzer.suggest_future_topics())
```

### Q: How do I automate daily comment analysis?

**A:** Set up a cron job:
```bash
# Edit crontab
crontab -e

# Add daily analysis at 9 AM
0 9 * * * cd /path/to/container-codes && make youtube-comments URL='LATEST_VIDEO_URL'
```

For dynamic latest video detection, you'll need additional scripting to get your channel's latest video ID.

### Q: Can I export data to other formats?

**A:** Built-in formats:
- JSON (structured data)
- CSV (spreadsheet-friendly)
- Markdown (human-readable reports)

For other formats, process the JSON output:
```python
import json
import pandas as pd

# Load JSON
with open('tmp/comments.json', 'r') as f:
    comments = json.load(f)

# Convert to DataFrame
df = pd.DataFrame(comments)

# Export to other formats
df.to_excel('comments.xlsx')
df.to_parquet('comments.parquet')
```

### Q: How do I analyze comments in other languages?

**A:** The tool works with any language YouTube supports:
- Keyword extraction works with Unicode text
- Stop words are currently English-focused
- Consider customizing the `stop_words` set in `extract_keywords()` for your language

## Legal & Ethics

### Q: Is it legal to scrape YouTube comments?

**A:** Yes, when done properly:
- ✅ Uses official YouTube Data API v3
- ✅ Respects rate limits and terms of service
- ✅ Only accesses publicly available data
- ✅ No circumvention of access controls

### Q: What about privacy concerns?

**A:** Best practices:
- Only analyze public comments
- Don't store personal information longer than necessary
- Consider anonymizing data for sharing
- Respect commenter privacy in your analysis reports

### Q: Can I use this data commercially?

**A:** Generally yes, but:
- Follow YouTube's Terms of Service
- Respect individual privacy
- Consider your local data protection laws
- Use data ethically for legitimate business purposes

### Q: Should I inform viewers that I analyze comments?

**A:** While not required for public data, it's good practice:
- Mention in video descriptions that you analyze feedback
- Use insights to improve content for your audience
- Be transparent about how you use community feedback

## Performance & Scaling

### Q: How do I handle large channels with thousands of comments?

**A:** Strategies:
- **Sample recent comments**: Use time ordering and reasonable limits
- **Focus on top videos**: Analyze your most popular content
- **Batch processing**: Process multiple videos overnight
- **Summary reports**: Focus on key insights rather than all data

### Q: Can I run this on a server?

**A:** Yes, the tool is server-friendly:
- No GUI dependencies
- Uses environment variables for configuration
- Supports quiet mode for automated runs
- Outputs to files for automated processing

### Q: How much does it cost to analyze comments regularly?

**A:** Costs:
- **YouTube API**: Free up to 10,000 units/day
- **Server resources**: Minimal (Python script)
- **Storage**: Very low (text data)
- **Anthropic AI**: Optional, ~$0.01-0.05 per analysis

Most users stay within free tiers for regular analysis.

---

## Still Have Questions?

- Check [Troubleshooting Guide](../troubleshooting/api-issues.md)
- Review [API Reference](../api-reference/youtube-scraper.md)
- Open an issue in the repository
- Ask in the YouTube video comments!