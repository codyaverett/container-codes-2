"""
YouTube Comment Scraper Module
Defensive tool for extracting YouTube comments using the official YouTube Data API v3
"""

import os
import re
import json
import csv
import time
from datetime import datetime, timezone
from typing import Dict, List, Optional, Iterator, Tuple
from urllib.parse import urlparse, parse_qs
from pathlib import Path
from collections import Counter

try:
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
except ImportError:
    raise ImportError(
        "Google API client not installed. Run: pip install google-api-python-client"
    )


class YouTubeCommentScraper:
    """
    YouTube comment scraper using the official YouTube Data API v3.
    
    This tool respects YouTube's Terms of Service and implements proper
    rate limiting and error handling for defensive data collection.
    """
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize the YouTube comment scraper.
        
        Args:
            api_key: YouTube Data API v3 key. If None, will try to get from environment.
        """
        self.api_key = api_key or os.environ.get('YOUTUBE_API_KEY')
        if not self.api_key:
            raise ValueError(
                "YouTube API key required. Set YOUTUBE_API_KEY environment variable "
                "or pass api_key parameter."
            )
        
        self.youtube = build('youtube', 'v3', developerKey=self.api_key)
        self.request_count = 0
        self.rate_limit_delay = 1.0  # Seconds between requests
    
    def extract_video_id(self, url: str) -> str:
        """
        Extract video ID from various YouTube URL formats.
        
        Args:
            url: YouTube video URL or video ID
            
        Returns:
            Video ID string
            
        Raises:
            ValueError: If URL format is invalid or video ID cannot be extracted
        """
        # If it's already just a video ID (11 characters, alphanumeric + - _)
        if re.match(r'^[a-zA-Z0-9_-]{11}$', url):
            return url
        
        # Parse different YouTube URL formats
        patterns = [
            r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([a-zA-Z0-9_-]{11})',
            r'youtube\.com/v/([a-zA-Z0-9_-]{11})',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1)
        
        # Try parsing as URL with query parameters
        try:
            parsed = urlparse(url)
            if 'v' in parse_qs(parsed.query):
                video_id = parse_qs(parsed.query)['v'][0]
                if re.match(r'^[a-zA-Z0-9_-]{11}$', video_id):
                    return video_id
        except Exception:
            pass
        
        raise ValueError(f"Could not extract video ID from: {url}")
    
    def get_video_info(self, video_id: str) -> Dict:
        """
        Get basic video information.
        
        Args:
            video_id: YouTube video ID
            
        Returns:
            Dictionary with video information
        """
        try:
            response = self.youtube.videos().list(
                part='snippet,statistics',
                id=video_id
            ).execute()
            
            self._rate_limit()
            
            if not response['items']:
                raise ValueError(f"Video not found: {video_id}")
            
            video = response['items'][0]
            snippet = video['snippet']
            stats = video['statistics']
            
            return {
                'id': video_id,
                'title': snippet['title'],
                'channel': snippet['channelTitle'],
                'published_at': snippet['publishedAt'],
                'view_count': int(stats.get('viewCount', 0)),
                'like_count': int(stats.get('likeCount', 0)),
                'comment_count': int(stats.get('commentCount', 0)),
                'description': snippet.get('description', ''),
                'tags': snippet.get('tags', [])
            }
            
        except HttpError as e:
            raise Exception(f"YouTube API error: {e}")
    
    def scrape_comments(self, video_id: str, max_comments: Optional[int] = None,
                       order: str = 'time') -> Iterator[Dict]:
        """
        Scrape comments from a YouTube video.
        
        Args:
            video_id: YouTube video ID
            max_comments: Maximum number of comments to retrieve (None for all)
            order: Comment order ('time', 'relevance')
            
        Yields:
            Dictionary containing comment data
        """
        next_page_token = None
        comments_retrieved = 0
        
        while True:
            try:
                # Get comment threads
                response = self.youtube.commentThreads().list(
                    part='snippet,replies',
                    videoId=video_id,
                    order=order,
                    maxResults=min(100, max_comments - comments_retrieved if max_comments else 100),
                    pageToken=next_page_token
                ).execute()
                
                self._rate_limit()
                
                for item in response['items']:
                    comment = self._parse_comment(item['snippet']['topLevelComment'])
                    yield comment
                    comments_retrieved += 1
                    
                    if max_comments and comments_retrieved >= max_comments:
                        return
                    
                    # Process replies if they exist
                    if 'replies' in item:
                        for reply_item in item['replies']['comments']:
                            if max_comments and comments_retrieved >= max_comments:
                                return
                            reply = self._parse_comment(reply_item)
                            reply['is_reply'] = True
                            reply['parent_comment_id'] = comment['comment_id']
                            yield reply
                            comments_retrieved += 1
                
                next_page_token = response.get('nextPageToken')
                if not next_page_token:
                    break
                    
            except HttpError as e:
                if e.resp.status == 403:
                    print("Comments are disabled for this video or quota exceeded")
                    break
                else:
                    raise Exception(f"YouTube API error: {e}")
    
    def _parse_comment(self, comment_data: Dict) -> Dict:
        """Parse comment data from YouTube API response."""
        snippet = comment_data['snippet']
        
        return {
            'comment_id': comment_data['id'],
            'author': snippet['authorDisplayName'],
            'author_channel_id': snippet.get('authorChannelId', {}).get('value', ''),
            'text': snippet['textDisplay'],
            'text_original': snippet['textOriginal'],
            'like_count': snippet['likeCount'],
            'published_at': snippet['publishedAt'],
            'updated_at': snippet['updatedAt'],
            'is_reply': False,
            'parent_comment_id': None,
            'can_reply': snippet['canReply'] if 'canReply' in snippet else False
        }
    
    def _rate_limit(self):
        """Implement rate limiting to respect YouTube API quotas."""
        self.request_count += 1
        time.sleep(self.rate_limit_delay)
    
    def export_to_json(self, comments: List[Dict], output_file: str, 
                      video_info: Optional[Dict] = None, command_info: Optional[Dict] = None) -> None:
        """Export comments to JSON file with metadata header."""
        export_data = {
            'metadata': {
                'exported_at': datetime.now().isoformat(),
                'total_comments': len(comments),
            },
            'comments': comments
        }
        
        # Add video information
        if video_info:
            export_data['metadata']['video'] = {
                'id': video_info['id'],
                'title': video_info['title'],
                'url': f"https://www.youtube.com/watch?v={video_info['id']}",
                'channel': video_info['channel'],
                'published_at': video_info['published_at']
            }
        
        # Add command information
        if command_info:
            export_data['metadata']['command'] = command_info
            
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(export_data, f, indent=2, ensure_ascii=False, default=str)
    
    def export_to_csv(self, comments: List[Dict], output_file: str,
                     video_info: Optional[Dict] = None, command_info: Optional[Dict] = None) -> None:
        """Export comments to CSV file with metadata header."""
        if not comments:
            return
            
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            # Write metadata header as comments
            f.write(f"# YouTube Comment Export\n")
            f.write(f"# Exported: {datetime.now().isoformat()}\n")
            f.write(f"# Total Comments: {len(comments)}\n")
            
            if video_info:
                f.write(f"# Video: {video_info['title']}\n")
                f.write(f"# URL: https://www.youtube.com/watch?v={video_info['id']}\n")
                f.write(f"# Channel: {video_info['channel']}\n")
                
            if command_info:
                f.write(f"# Command: {command_info.get('original_command', 'N/A')}\n")
                f.write(f"# Max Comments: {command_info.get('max_comments', 'N/A')}\n")
                
            f.write("#\n")  # Separator
            
            # Write CSV data
            fieldnames = comments[0].keys()
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(comments)
    
    def export_to_markdown(self, comments: List[Dict], output_file: str, 
                          video_info: Optional[Dict] = None, command_info: Optional[Dict] = None) -> None:
        """Export comments to Markdown file with metadata header."""
        with open(output_file, 'w', encoding='utf-8') as f:
            # Write header with video and command information
            if video_info:
                f.write(f"# YouTube Comments: {video_info['title']}\n\n")
                f.write(f"**🔗 Video URL:** [Watch on YouTube](https://www.youtube.com/watch?v={video_info['id']})\n")
                f.write(f"**📺 Channel:** {video_info['channel']}\n")
                f.write(f"**📅 Published:** {video_info['published_at']}\n")
                f.write(f"**👁️ View Count:** {video_info['view_count']:,}\n")
                f.write(f"**💬 Total Comments:** {video_info['comment_count']:,}\n")
                f.write(f"**🆔 Video ID:** {video_info['id']}\n\n")
                
                if command_info:
                    f.write("## Analysis Details\n\n")
                    f.write(f"**📊 Exported:** {datetime.now().isoformat()}\n")
                    f.write(f"**💻 Command:** `{command_info.get('original_command', 'N/A')}`\n")
                    f.write(f"**🔢 Comments Analyzed:** {len(comments):,}\n")
                    f.write(f"**⚙️ Max Comments:** {command_info.get('max_comments', 'All')}\n")
                    f.write(f"**📋 Format:** {command_info.get('format', 'markdown')}\n\n")
                
                f.write("---\n\n")
            
            f.write(f"## Comments ({len(comments):,} total)\n\n")
            
            for i, comment in enumerate(comments, 1):
                prefix = "  > " if comment.get('is_reply') else ""
                f.write(f"### Comment {i}\n\n")
                f.write(f"**👤 Author:** {comment['author']}\n")
                f.write(f"**📅 Posted:** {comment['published_at']}\n")
                f.write(f"**👍 Likes:** {comment['like_count']}\n\n")
                f.write(f"{prefix}{comment['text']}\n\n")
                f.write("---\n\n")


class CommentAnalyzer:
    """Analyze scraped YouTube comments for insights."""
    
    def __init__(self, comments: List[Dict]):
        self.comments = comments
        self.total_comments = len(comments)
        self.top_level_comments = [c for c in comments if not c.get('is_reply', False)]
        self.replies = [c for c in comments if c.get('is_reply', False)]
    
    def get_basic_stats(self) -> Dict:
        """Get basic statistics about the comments."""
        if not self.comments:
            return {}
        
        total_likes = sum(c['like_count'] for c in self.comments)
        avg_likes = total_likes / self.total_comments
        
        # Comment length statistics
        lengths = [len(c['text']) for c in self.comments]
        avg_length = sum(lengths) / len(lengths)
        
        # Most active authors
        authors = Counter(c['author'] for c in self.comments)
        
        # Engagement distribution
        high_engagement = len([c for c in self.comments if c['like_count'] > avg_likes * 2])
        
        return {
            'total_comments': self.total_comments,
            'top_level_comments': len(self.top_level_comments),
            'replies': len(self.replies),
            'total_likes': total_likes,
            'avg_likes': avg_likes,
            'avg_comment_length': avg_length,
            'high_engagement_count': high_engagement,
            'most_active_authors': authors.most_common(5),
            'reply_ratio': len(self.replies) / self.total_comments if self.total_comments > 0 else 0
        }
    
    def extract_keywords(self, min_word_length: int = 4, top_n: int = 15) -> List[Tuple[str, int]]:
        """Extract common keywords and themes from comments."""
        # Combine all comment text
        all_text = ' '.join(c['text'].lower() for c in self.comments)
        
        # Simple word extraction (could be enhanced with NLP libraries)
        words = re.findall(rf'\b\w{{{min_word_length},}}\b', all_text)
        
        # Filter out common stop words
        stop_words = {
            'this', 'that', 'with', 'have', 'will', 'from', 'they', 'been', 
            'were', 'said', 'each', 'which', 'their', 'time', 'would', 'there',
            'what', 'when', 'where', 'your', 'just', 'like', 'dont', 'really',
            'think', 'know', 'good', 'great', 'thanks', 'thank', 'video', 
            'youtube', 'channel', 'subscribe', 'comment', 'comments'
        }
        
        filtered_words = [w for w in words if w not in stop_words and len(w) > min_word_length]
        return Counter(filtered_words).most_common(top_n)
    
    def find_questions(self, top_n: int = 10) -> List[Dict]:
        """Find questions in comments for FAQ insights."""
        questions = []
        question_indicators = ['?', 'how', 'what', 'why', 'when', 'where', 'which', 'can you', 'could you']
        
        for comment in self.comments:
            text = comment['text'].strip()
            text_lower = text.lower()
            
            # Check for question patterns
            if ('?' in text and 
                any(indicator in text_lower for indicator in question_indicators)):
                questions.append({
                    'text': text[:200] + '...' if len(text) > 200 else text,
                    'author': comment['author'],
                    'likes': comment['like_count'],
                    'is_reply': comment.get('is_reply', False)
                })
        
        # Sort by engagement and return top questions
        questions.sort(key=lambda x: x['likes'], reverse=True)
        return questions[:top_n]
    
    def analyze_engagement_patterns(self) -> Dict:
        """Analyze engagement patterns in comments."""
        if not self.comments:
            return {}
        
        # Engagement distribution
        likes_data = [c['like_count'] for c in self.comments]
        likes_data.sort(reverse=True)
        
        # Top engaging comments
        top_comments = sorted(self.comments, key=lambda x: x['like_count'], reverse=True)[:5]
        
        # Time-based patterns (if timestamps available)
        hourly_distribution = Counter()
        for comment in self.comments:
            try:
                dt = datetime.fromisoformat(comment['published_at'].replace('Z', '+00:00'))
                hourly_distribution[dt.hour] += 1
            except (ValueError, KeyError):
                continue
        
        return {
            'max_likes': max(likes_data) if likes_data else 0,
            'median_likes': likes_data[len(likes_data)//2] if likes_data else 0,
            'top_comments': [{
                'author': c['author'],
                'likes': c['like_count'],
                'text_preview': c['text'][:100] + '...' if len(c['text']) > 100 else c['text']
            } for c in top_comments],
            'peak_hours': hourly_distribution.most_common(3) if hourly_distribution else []
        }
    
    def identify_content_requests(self, top_n: int = 10) -> List[Dict]:
        """Identify content requests and suggestions."""
        request_keywords = [
            'tutorial', 'explain', 'show how', 'guide', 'demo', 'example',
            'walkthrough', 'deep dive', 'comparison', 'please', 'would love',
            'can you do', 'next video', 'cover', 'topic', 'about'
        ]
        
        requests = []
        for comment in self.comments:
            text_lower = comment['text'].lower()
            if any(keyword in text_lower for keyword in request_keywords):
                requests.append({
                    'text': comment['text'][:150] + '...' if len(comment['text']) > 150 else comment['text'],
                    'author': comment['author'],
                    'likes': comment['like_count'],
                    'matched_keywords': [kw for kw in request_keywords if kw in text_lower]
                })
        
        # Sort by engagement
        requests.sort(key=lambda x: x['likes'], reverse=True)
        return requests[:top_n]
    
    def suggest_future_topics(self, top_n: int = 8) -> List[Dict]:
        """Suggest specific future video topics based on comment analysis."""
        # Container technology keywords and their related topics
        container_topics = {
            'kubernetes': ['Kubernetes networking deep dive', 'K8s security best practices', 'Helm chart optimization', 'Kubernetes troubleshooting'],
            'docker': ['Docker vs Podman migration guide', 'Docker security hardening', 'Multi-stage Docker builds', 'Docker networking explained'],
            'podman': ['Podman rootless containers', 'Podman pods vs containers', 'Podman systemd integration', 'Podman desktop vs CLI'],
            'security': ['Container security scanning', 'Runtime security with Falco', 'Image vulnerability management', 'Zero-trust containers'],
            'networking': ['Container networking fundamentals', 'Service mesh with Istio', 'Load balancing containers', 'CNI plugins comparison'],
            'buildah': ['Buildah vs Docker build', 'Scriptable container builds', 'Multi-arch builds with Buildah', 'OCI image creation'],
            'skopeo': ['Image registry management', 'Container image signing', 'Air-gapped image workflows', 'Image inspection tools'],
            'production': ['Production container deployment', 'Container monitoring setup', 'Logging best practices', 'Auto-scaling containers'],
            'performance': ['Container performance tuning', 'Resource optimization', 'Memory management in containers', 'Container benchmarking'],
            'orchestration': ['Container orchestration comparison', 'Docker Swarm vs Kubernetes', 'Nomad for containers', 'Container scheduling'],
            'monitoring': ['Prometheus for containers', 'Grafana dashboards', 'Container metrics collection', 'Alerting strategies'],
            'storage': ['Container persistent storage', 'Volume management', 'Storage drivers comparison', 'Data backup strategies'],
            'cicd': ['Container CI/CD pipelines', 'GitOps workflows', 'Automated testing', 'Deployment strategies'],
            'compose': ['Docker Compose advanced features', 'Multi-environment setups', 'Compose vs Kubernetes', 'Development workflows']
        }
        
        # Extract topics mentioned in comments
        all_text = ' '.join(c['text'].lower() for c in self.comments)
        mentioned_topics = []
        
        for topic, suggestions in container_topics.items():
            # Count mentions of this topic
            mentions = len(re.findall(rf'\b{topic}\b', all_text))
            if mentions > 0:
                # Find comments that mention this topic
                relevant_comments = [c for c in self.comments if topic in c['text'].lower()]
                avg_engagement = sum(c['like_count'] for c in relevant_comments) / len(relevant_comments) if relevant_comments else 0
                
                mentioned_topics.append({
                    'topic': topic,
                    'mentions': mentions,
                    'avg_engagement': avg_engagement,
                    'suggestions': suggestions,
                    'interest_score': mentions * (1 + avg_engagement)  # Combined score
                })
        
        # Sort by interest score and return top suggestions
        mentioned_topics.sort(key=lambda x: x['interest_score'], reverse=True)
        
        # Generate specific video suggestions
        video_suggestions = []
        for topic_data in mentioned_topics[:top_n//2]:  # Take top half of topics
            for suggestion in topic_data['suggestions'][:2]:  # Top 2 suggestions per topic
                video_suggestions.append({
                    'title': suggestion,
                    'based_on_topic': topic_data['topic'],
                    'mentions': topic_data['mentions'],
                    'avg_engagement': topic_data['avg_engagement'],
                    'priority': 'High' if topic_data['interest_score'] > 10 else 'Medium'
                })
        
        # Add trending/emerging topics based on question patterns
        questions = self.find_questions(20)
        emerging_topics = []
        
        # Look for specific technology mentions in questions
        tech_patterns = {
            'ai': 'AI and Machine Learning in Containers',
            'serverless': 'Serverless Containers with Knative',
            'wasm': 'WebAssembly and Container Runtime',
            'edge': 'Edge Computing with Containers',
            'arm': 'ARM/M1 Container Development',
            'windows': 'Windows Container Development',
            'microservices': 'Microservices Architecture Patterns',
            'observability': 'Container Observability Stack',
            'gitops': 'GitOps Deployment Workflows',
            'helm': 'Advanced Helm Chart Development'
        }
        
        for question in questions:
            text_lower = question['text'].lower()
            for tech, topic_title in tech_patterns.items():
                if tech in text_lower and topic_title not in [v['title'] for v in video_suggestions]:
                    emerging_topics.append({
                        'title': topic_title,
                        'based_on_topic': tech,
                        'mentions': 1,
                        'avg_engagement': question['likes'],
                        'priority': 'Emerging',
                        'source_question': question['text'][:100] + '...'
                    })
        
        # Combine and prioritize
        all_suggestions = video_suggestions + emerging_topics
        all_suggestions.sort(key=lambda x: (
            x['priority'] == 'High',
            x['priority'] == 'Emerging', 
            x['avg_engagement']
        ), reverse=True)
        
        return all_suggestions[:top_n]
    
    def analyze_audience_level(self) -> Dict:
        """Analyze the technical level and interests of the audience."""
        if not self.comments:
            return {}
        
        # Technical complexity indicators
        beginner_indicators = ['beginner', 'new to', 'just started', 'tutorial', 'how to', 'basic', 'simple']
        intermediate_indicators = ['implement', 'production', 'best practice', 'experience', 'recommend', 'migrate']
        advanced_indicators = ['architecture', 'performance', 'optimize', 'scale', 'enterprise', 'custom', 'extend']
        
        levels = {'beginner': 0, 'intermediate': 0, 'advanced': 0}
        
        for comment in self.comments:
            text_lower = comment['text'].lower()
            
            if any(indicator in text_lower for indicator in beginner_indicators):
                levels['beginner'] += 1
            elif any(indicator in text_lower for indicator in advanced_indicators):
                levels['advanced'] += 1
            elif any(indicator in text_lower for indicator in intermediate_indicators):
                levels['intermediate'] += 1
        
        total = sum(levels.values())
        if total == 0:
            return {'dominant_level': 'intermediate', 'distribution': levels}
        
        percentages = {k: (v/total)*100 for k, v in levels.items()}
        dominant_level = max(percentages.keys(), key=lambda k: percentages[k])
        
        return {
            'dominant_level': dominant_level,
            'distribution': percentages,
            'total_classified': total
        }
    
    def generate_insights_summary(self) -> str:
        """Generate a comprehensive insights summary."""
        stats = self.get_basic_stats()
        keywords = self.extract_keywords()
        questions = self.find_questions(5)
        engagement = self.analyze_engagement_patterns()
        requests = self.identify_content_requests(5)
        topic_suggestions = self.suggest_future_topics(8)
        audience_level = self.analyze_audience_level()
        
        if not stats:
            return "No comments available for analysis."
        
        summary = []
        summary.append("📊 COMMENT ANALYSIS INSIGHTS")
        summary.append("=" * 50)
        
        # Basic Statistics
        summary.append(f"💬 Total Comments: {stats['total_comments']:,}")
        summary.append(f"   ├─ Top-level: {stats['top_level_comments']:,}")
        summary.append(f"   └─ Replies: {stats['replies']:,} ({stats['reply_ratio']:.1%})")
        
        summary.append(f"👍 Engagement: {stats['total_likes']:,} total likes")
        summary.append(f"   ├─ Average: {stats['avg_likes']:.1f} likes per comment")
        summary.append(f"   └─ High engagement: {stats['high_engagement_count']} comments")
        
        summary.append(f"📝 Average comment length: {stats['avg_comment_length']:.0f} characters")
        
        # Top Keywords/Topics
        if keywords:
            summary.append(f"\n🎯 TOP DISCUSSION TOPICS:")
            for i, (word, count) in enumerate(keywords[:8], 1):
                summary.append(f"   {i:2d}. {word} ({count} mentions)")
        
        # Top Questions
        if questions:
            summary.append(f"\n❓ MOST ENGAGING QUESTIONS:")
            for i, q in enumerate(questions[:3], 1):
                summary.append(f"   {i}. {q['text'][:80]}{'...' if len(q['text']) > 80 else ''}")
                summary.append(f"      └─ {q['author']} ({q['likes']} likes)")
        
        # Content Requests
        if requests:
            summary.append(f"\n💡 TOP CONTENT REQUESTS:")
            for i, req in enumerate(requests[:3], 1):
                summary.append(f"   {i}. {req['text'][:80]}{'...' if len(req['text']) > 80 else ''}")
                summary.append(f"      └─ {req['author']} ({req['likes']} likes)")
        
        # Engagement Leaders
        if stats['most_active_authors']:
            summary.append(f"\n🏆 MOST ACTIVE COMMENTERS:")
            for i, (author, count) in enumerate(stats['most_active_authors'][:3], 1):
                summary.append(f"   {i}. {author} ({count} comments)")
        
        # Peak Activity
        if engagement.get('peak_hours'):
            summary.append(f"\n⏰ PEAK ACTIVITY HOURS:")
            for hour, count in engagement['peak_hours']:
                summary.append(f"   • {hour:02d}:00 - {count} comments")
        
        # Suggested Future Topics (NEW)
        if topic_suggestions:
            summary.append(f"\n🚀 SUGGESTED FUTURE VIDEO TOPICS:")
            for i, suggestion in enumerate(topic_suggestions[:6], 1):
                priority_emoji = {"High": "🔥", "Medium": "⭐", "Emerging": "💡"}.get(suggestion['priority'], "📹")
                summary.append(f"   {i}. {priority_emoji} {suggestion['title']}")
                if suggestion.get('mentions', 0) > 0:
                    summary.append(f"      └─ Based on {suggestion['mentions']} mentions of '{suggestion['based_on_topic']}'")
                elif suggestion.get('source_question'):
                    summary.append(f"      └─ From question: {suggestion['source_question'][:60]}...")
        
        # Audience Level Analysis (NEW)
        if audience_level.get('total_classified', 0) > 0:
            summary.append(f"\n👥 AUDIENCE TECHNICAL LEVEL:")
            dist = audience_level['distribution']
            dominant = audience_level['dominant_level'].title()
            summary.append(f"   Primary audience: {dominant}")
            summary.append(f"   Distribution: Beginner {dist['beginner']:.0f}% | Intermediate {dist['intermediate']:.0f}% | Advanced {dist['advanced']:.0f}%")
            
            # Content recommendation based on audience level
            if audience_level['dominant_level'] == 'beginner':
                summary.append(f"   💡 Focus on: Step-by-step tutorials, basic concepts, getting started guides")
            elif audience_level['dominant_level'] == 'advanced':
                summary.append(f"   💡 Focus on: Architecture deep-dives, performance optimization, enterprise use cases")
            else:
                summary.append(f"   💡 Focus on: Best practices, real-world examples, practical implementations")
        
        # Engagement Health Score
        if stats['avg_likes'] > 5:
            health_emoji = "🟢"
            health_status = "Excellent"
        elif stats['avg_likes'] > 2:
            health_emoji = "🟡"
            health_status = "Good"
        else:
            health_emoji = "🔴"
            health_status = "Needs Improvement"
        
        summary.append(f"\n{health_emoji} ENGAGEMENT HEALTH: {health_status}")
        
        return '\n'.join(summary)


def get_comments_batch(video_url: str, max_comments: Optional[int] = None,
                      output_format: str = 'json', output_file: Optional[str] = None,
                      api_key: Optional[str] = None, show_insights: bool = True,
                      command_info: Optional[Dict] = None) -> Tuple[List[Dict], Dict]:
    """
    Convenience function to scrape comments and get video info in one call.
    
    Args:
        video_url: YouTube video URL or ID
        max_comments: Maximum number of comments to retrieve
        output_format: Output format ('json', 'csv', 'markdown')
        output_file: Output file path (auto-generated if None)
        api_key: YouTube API key
        show_insights: Whether to generate and display insights analysis
        command_info: Dictionary with command information for output headers
        
    Returns:
        Tuple of (comments_list, video_info)
    """
    scraper = YouTubeCommentScraper(api_key)
    video_id = scraper.extract_video_id(video_url)
    
    # Get video information
    video_info = scraper.get_video_info(video_id)
    
    # Scrape comments
    comments = list(scraper.scrape_comments(video_id, max_comments))
    
    # Export if requested
    if output_file or output_format:
        if not output_file:
            # Create organized subdirectory structure
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Create video-specific directory
            safe_title = re.sub(r'[^\w\-_]', '_', video_info['title'].lower())
            safe_title = re.sub(r'_+', '_', safe_title)  # Replace multiple underscores
            safe_title = safe_title.strip('_')[:40]  # Shorter for directory name
            
            video_dir = Path("tmp") / f"{safe_title}_{video_id}_{timestamp}"
            video_dir.mkdir(parents=True, exist_ok=True)
            
            ext = 'md' if output_format == 'markdown' else output_format
            output_file = video_dir / f"comments.{ext}"
        else:
            # Ensure user-provided path has proper organization
            output_path = Path(output_file)
            if len(output_path.parts) == 1:  # Just filename, no directory
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                safe_title = re.sub(r'[^\w\-_]', '_', video_info['title'].lower())
                safe_title = re.sub(r'_+', '_', safe_title).strip('_')[:40]
                
                video_dir = Path("tmp") / f"{safe_title}_{video_id}_{timestamp}"
                video_dir.mkdir(parents=True, exist_ok=True)
                output_file = video_dir / output_file
        
        if output_format == 'json':
            scraper.export_to_json(comments, output_file, video_info, command_info)
        elif output_format == 'csv':
            scraper.export_to_csv(comments, output_file, video_info, command_info)
        elif output_format == 'markdown':
            scraper.export_to_markdown(comments, output_file, video_info, command_info)
        
        print(f"Exported {len(comments)} comments to {output_file}")
    
    # Generate insights summary
    if comments and show_insights:
        analyzer = CommentAnalyzer(comments)
        insights = analyzer.generate_insights_summary()
        print(f"\n{insights}")
        
        # Save insights to separate file if exporting
        if output_file:
            # Put insights file in same directory as output file
            output_path = Path(output_file)
            insights_file = output_path.parent / "insights.txt"
            
            # Create insights with header
            insights_with_header = ""
            if video_info:
                insights_with_header += f"YouTube Comment Analysis Report\n"
                insights_with_header += f"Video: {video_info['title']}\n"
                insights_with_header += f"URL: https://www.youtube.com/watch?v={video_info['id']}\n"
                insights_with_header += f"Channel: {video_info['channel']}\n"
                insights_with_header += f"Analyzed: {datetime.now().isoformat()}\n"
                if command_info:
                    insights_with_header += f"Command: {command_info.get('original_command', 'N/A')}\n"
                    insights_with_header += f"Max Comments: {command_info.get('max_comments', 'All')}\n"
                insights_with_header += f"\n{'='*60}\n\n"
            
            insights_with_header += insights
            
            with open(insights_file, 'w', encoding='utf-8') as f:
                f.write(insights_with_header)
            print(f"\n💡 Detailed insights saved to: {insights_file}")
            
            # Create a README file in the directory
            readme_file = output_path.parent / "README.md"
            with open(readme_file, 'w', encoding='utf-8') as f:
                f.write(f"# YouTube Comment Analysis\n\n")
                f.write(f"**🔗 Video:** [Watch on YouTube](https://www.youtube.com/watch?v={video_info['id']})\n")
                f.write(f"**📺 Title:** {video_info['title']}\n")
                f.write(f"**🏷️ Channel:** {video_info['channel']}\n")
                f.write(f"**📅 Analysis Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
                
                if command_info:
                    f.write(f"## Command Used\n\n")
                    f.write(f"```bash\n{command_info.get('original_command', 'N/A')}\n```\n\n")
                
                f.write(f"## Files in this Analysis\n\n")
                f.write(f"- `comments.{output_format}` - Raw comment data ({len(comments):,} comments)\n")
                f.write(f"- `insights.txt` - Detailed analysis and topic suggestions\n")
                f.write(f"- `README.md` - This overview file\n\n")
                f.write(f"## Quick Stats\n\n")
                f.write(f"- **Comments Analyzed:** {len(comments):,}\n")
                f.write(f"- **Total Video Comments:** {video_info.get('comment_count', 'N/A'):,}\n")
                f.write(f"- **Video Views:** {video_info.get('view_count', 'N/A'):,}\n")
                f.write(f"- **Video Likes:** {video_info.get('like_count', 'N/A'):,}\n\n")
                f.write(f"View the `insights.txt` file for detailed analysis and content suggestions.\n")
            
            print(f"📁 Analysis directory created: {output_path.parent}")
            print(f"📄 Directory overview: {readme_file}")
    
    return comments, video_info