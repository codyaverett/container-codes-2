"""
YouTube Caption Downloader Module
Download and analyze YouTube video captions using the YouTube Transcript API
"""

import os
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple, Union
from pathlib import Path
from urllib.parse import urlparse, parse_qs
import re

try:
    from youtube_transcript_api import YouTubeTranscriptApi, TranscriptsApi, Transcript
    from youtube_transcript_api.transcripts import TranscriptListFetcher
    from youtube_transcript_api._errors import (
        TranscriptsDisabled, NoTranscriptFound, VideoUnavailable,
        TooManyRequests, YouTubeRequestFailed, NotTranslatable,
        TranslationLanguageNotAvailable, CookiePathInvalid, CookiesInvalid,
        FailedToCreateConsentCookie, NoTranscriptAvailable, CouldNotRetrieveTranscript
    )
except ImportError:
    raise ImportError(
        "YouTube Transcript API not installed. Run: pip install youtube-transcript-api>=0.6.0"
    )


class YouTubeCaptionDownloader:
    """
    YouTube caption downloader using the YouTube Transcript API.
    
    This tool downloads captions/transcripts from YouTube videos for content analysis,
    supporting multiple languages and both auto-generated and manual captions.
    """
    
    def __init__(self, proxies: Optional[Dict] = None):
        """
        Initialize the YouTube caption downloader.
        
        Args:
            proxies: Optional proxy configuration for requests
        """
        self.proxies = proxies
        self.rate_limit_delay = 0.5  # Seconds between requests to be respectful
        
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
    
    def get_available_transcripts(self, video_id: str) -> Dict:
        """
        Get information about available transcripts for a video.
        
        Args:
            video_id: YouTube video ID
            
        Returns:
            Dictionary with available transcript information
        """
        try:
            transcript_list = YouTubeTranscriptApi.list_transcripts(video_id, proxies=self.proxies)
            
            available = {
                'manual_captions': [],
                'auto_generated': [],
                'translatable_languages': [],
                'total_count': 0
            }
            
            for transcript in transcript_list:
                transcript_info = {
                    'language': transcript.language,
                    'language_code': transcript.language_code,
                    'is_generated': transcript.is_generated,
                    'is_translatable': transcript.is_translatable
                }
                
                if transcript.is_generated:
                    available['auto_generated'].append(transcript_info)
                else:
                    available['manual_captions'].append(transcript_info)
                
                # Get translatable languages if available
                if transcript.is_translatable:
                    try:
                        translatable = transcript.translation_languages
                        available['translatable_languages'].extend([
                            {'code': lang['language_code'], 'name': lang['language']}
                            for lang in translatable
                        ])
                    except:
                        pass
            
            available['total_count'] = len(available['manual_captions']) + len(available['auto_generated'])
            
            # Remove duplicate translatable languages
            seen_codes = set()
            unique_translatable = []
            for lang in available['translatable_languages']:
                if lang['code'] not in seen_codes:
                    unique_translatable.append(lang)
                    seen_codes.add(lang['code'])
            available['translatable_languages'] = unique_translatable
            
            self._rate_limit()
            return available
            
        except TranscriptsDisabled:
            return {'error': 'Transcripts are disabled for this video'}
        except NoTranscriptFound:
            return {'error': 'No transcripts found for this video'}
        except VideoUnavailable:
            return {'error': 'Video is unavailable'}
        except Exception as e:
            return {'error': f'Failed to get transcript list: {str(e)}'}
    
    def download_caption(self, video_id: str, language_code: str = 'en', 
                        auto_generated: bool = True, preserve_formatting: bool = True) -> Dict:
        """
        Download captions for a specific language.
        
        Args:
            video_id: YouTube video ID
            language_code: Language code (e.g., 'en', 'es', 'fr')
            auto_generated: Whether to accept auto-generated captions
            preserve_formatting: Whether to preserve original formatting
            
        Returns:
            Dictionary with caption data and metadata
        """
        try:
            # Try to get the specific transcript
            transcript = YouTubeTranscriptApi.get_transcript(
                video_id, 
                languages=[language_code],
                proxies=self.proxies
            )
            
            # Get transcript metadata
            transcript_list = YouTubeTranscriptApi.list_transcripts(video_id, proxies=self.proxies)
            transcript_info = None
            
            for t in transcript_list:
                if t.language_code == language_code:
                    transcript_info = {
                        'language': t.language,
                        'language_code': t.language_code,
                        'is_generated': t.is_generated,
                        'is_translatable': t.is_translatable
                    }
                    break
            
            # Process transcript data
            processed_transcript = self._process_transcript(transcript, preserve_formatting)
            
            result = {
                'video_id': video_id,
                'language_code': language_code,
                'transcript_info': transcript_info,
                'caption_data': transcript,
                'processed_text': processed_transcript['full_text'],
                'segments': processed_transcript['segments'],
                'statistics': processed_transcript['statistics'],
                'downloaded_at': datetime.now().isoformat()
            }
            
            self._rate_limit()
            return result
            
        except NoTranscriptFound:
            return {'error': f'No transcript found for language: {language_code}'}
        except TranscriptsDisabled:
            return {'error': 'Transcripts are disabled for this video'}
        except Exception as e:
            return {'error': f'Failed to download captions: {str(e)}'}
    
    def download_all_captions(self, video_id: str, include_auto_generated: bool = True) -> Dict:
        """
        Download all available captions for a video.
        
        Args:
            video_id: YouTube video ID
            include_auto_generated: Whether to include auto-generated captions
            
        Returns:
            Dictionary with all caption data
        """
        available = self.get_available_transcripts(video_id)
        
        if 'error' in available:
            return available
        
        all_captions = {
            'video_id': video_id,
            'downloaded_at': datetime.now().isoformat(),
            'available_transcripts': available,
            'captions': {},
            'download_summary': {
                'successful': 0,
                'failed': 0,
                'errors': []
            }
        }
        
        # Download manual captions first (higher priority)
        for transcript_info in available['manual_captions']:
            lang_code = transcript_info['language_code']
            print(f"  📝 Downloading manual captions: {transcript_info['language']} ({lang_code})")
            
            result = self.download_caption(video_id, lang_code, auto_generated=False)
            
            if 'error' not in result:
                all_captions['captions'][lang_code] = result
                all_captions['download_summary']['successful'] += 1
            else:
                all_captions['download_summary']['failed'] += 1
                all_captions['download_summary']['errors'].append({
                    'language': lang_code,
                    'error': result['error']
                })
        
        # Download auto-generated captions if requested and no manual version exists
        if include_auto_generated:
            for transcript_info in available['auto_generated']:
                lang_code = transcript_info['language_code']
                
                # Skip if we already have manual captions for this language
                if lang_code in all_captions['captions']:
                    continue
                
                print(f"  🤖 Downloading auto-generated captions: {transcript_info['language']} ({lang_code})")
                
                result = self.download_caption(video_id, lang_code, auto_generated=True)
                
                if 'error' not in result:
                    all_captions['captions'][lang_code] = result
                    all_captions['download_summary']['successful'] += 1
                else:
                    all_captions['download_summary']['failed'] += 1
                    all_captions['download_summary']['errors'].append({
                        'language': lang_code,
                        'error': result['error']
                    })
        
        return all_captions
    
    def _process_transcript(self, transcript: List[Dict], preserve_formatting: bool = True) -> Dict:
        """
        Process raw transcript data into more usable formats.
        
        Args:
            transcript: Raw transcript data from YouTube API
            preserve_formatting: Whether to preserve timing information
            
        Returns:
            Dictionary with processed transcript data
        """
        if not transcript:
            return {
                'full_text': '',
                'segments': [],
                'statistics': {
                    'total_duration': 0,
                    'total_segments': 0,
                    'average_segment_length': 0,
                    'words_per_minute': 0
                }
            }
        
        # Create formatted segments
        segments = []
        full_text_parts = []
        
        for entry in transcript:
            start_time = entry.get('start', 0)
            duration = entry.get('duration', 0)
            text = entry.get('text', '').strip()
            
            if text:
                # Clean up text
                cleaned_text = self._clean_caption_text(text)
                
                segment = {
                    'start': start_time,
                    'duration': duration,
                    'end': start_time + duration,
                    'text': cleaned_text,
                    'original_text': text,
                    'timestamp': self._seconds_to_timestamp(start_time)
                }
                
                segments.append(segment)
                full_text_parts.append(cleaned_text)
        
        full_text = ' '.join(full_text_parts)
        
        # Calculate statistics
        total_duration = max([seg['end'] for seg in segments]) if segments else 0
        total_words = len(full_text.split()) if full_text else 0
        words_per_minute = (total_words / (total_duration / 60)) if total_duration > 0 else 0
        
        statistics = {
            'total_duration': total_duration,
            'total_segments': len(segments),
            'total_words': total_words,
            'total_characters': len(full_text),
            'average_segment_length': len(segments) / len(segments) if segments else 0,
            'words_per_minute': words_per_minute,
            'duration_formatted': self._seconds_to_timestamp(total_duration)
        }
        
        return {
            'full_text': full_text,
            'segments': segments,
            'statistics': statistics
        }
    
    def _clean_caption_text(self, text: str) -> str:
        """Clean up caption text by removing artifacts and formatting issues."""
        # Remove or fix common caption artifacts
        text = re.sub(r'\[.*?\]', '', text)  # Remove [Music], [Applause] etc.
        text = re.sub(r'\(.*?\)', '', text)  # Remove (inaudible) etc.
        text = re.sub(r'>>.*?<<', '', text)  # Remove speaker indicators
        text = re.sub(r'\s+', ' ', text)     # Normalize whitespace
        text = text.strip()
        
        return text
    
    def _seconds_to_timestamp(self, seconds: float) -> str:
        """Convert seconds to HH:MM:SS format."""
        td = timedelta(seconds=seconds)
        total_seconds = int(td.total_seconds())
        hours, remainder = divmod(total_seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}"
    
    def _rate_limit(self):
        """Implement rate limiting to be respectful to YouTube's servers."""
        time.sleep(self.rate_limit_delay)
    
    def export_captions_to_txt(self, caption_data: Dict, output_file: str, 
                              include_timestamps: bool = False) -> None:
        """Export captions to plain text file."""
        with open(output_file, 'w', encoding='utf-8') as f:
            if include_timestamps:
                # Write with timestamps
                f.write(f"YouTube Video Captions\n")
                f.write(f"Video ID: {caption_data.get('video_id', 'Unknown')}\n")
                f.write(f"Language: {caption_data.get('language_code', 'Unknown')}\n")
                f.write(f"Downloaded: {caption_data.get('downloaded_at', 'Unknown')}\n")
                f.write(f"\n{'='*60}\n\n")
                
                for segment in caption_data.get('segments', []):
                    timestamp = segment.get('timestamp', '00:00:00')
                    text = segment.get('text', '')
                    f.write(f"[{timestamp}] {text}\n")
            else:
                # Write just the text
                f.write(caption_data.get('processed_text', ''))
    
    def export_captions_to_srt(self, caption_data: Dict, output_file: str) -> None:
        """Export captions to SRT subtitle format."""
        with open(output_file, 'w', encoding='utf-8') as f:
            segments = caption_data.get('segments', [])
            
            for i, segment in enumerate(segments, 1):
                start_time = self._seconds_to_srt_timestamp(segment.get('start', 0))
                end_time = self._seconds_to_srt_timestamp(segment.get('end', 0))
                text = segment.get('text', '')
                
                f.write(f"{i}\n")
                f.write(f"{start_time} --> {end_time}\n")
                f.write(f"{text}\n\n")
    
    def export_captions_to_vtt(self, caption_data: Dict, output_file: str) -> None:
        """Export captions to WebVTT format."""
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("WEBVTT\n\n")
            
            segments = caption_data.get('segments', [])
            
            for segment in segments:
                start_time = self._seconds_to_vtt_timestamp(segment.get('start', 0))
                end_time = self._seconds_to_vtt_timestamp(segment.get('end', 0))
                text = segment.get('text', '')
                
                f.write(f"{start_time} --> {end_time}\n")
                f.write(f"{text}\n\n")
    
    def export_captions_to_json(self, caption_data: Dict, output_file: str) -> None:
        """Export captions to JSON format with full metadata."""
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(caption_data, f, indent=2, ensure_ascii=False)
    
    def _seconds_to_srt_timestamp(self, seconds: float) -> str:
        """Convert seconds to SRT timestamp format (HH:MM:SS,mmm)."""
        total_seconds = int(seconds)
        milliseconds = int((seconds - total_seconds) * 1000)
        hours, remainder = divmod(total_seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        return f"{hours:02d}:{minutes:02d}:{seconds:02d},{milliseconds:03d}"
    
    def _seconds_to_vtt_timestamp(self, seconds: float) -> str:
        """Convert seconds to WebVTT timestamp format (HH:MM:SS.mmm)."""
        total_seconds = int(seconds)
        milliseconds = int((seconds - total_seconds) * 1000)
        hours, remainder = divmod(total_seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}.{milliseconds:03d}"


class CaptionAnalyzer:
    """Analyze downloaded YouTube captions for content insights."""
    
    def __init__(self, caption_data: Dict):
        """
        Initialize caption analyzer.
        
        Args:
            caption_data: Caption data from YouTubeCaptionDownloader
        """
        self.caption_data = caption_data
        self.full_text = caption_data.get('processed_text', '')
        self.segments = caption_data.get('segments', [])
        self.statistics = caption_data.get('statistics', {})
    
    def extract_key_topics(self, min_word_length: int = 4, top_n: int = 20) -> List[Tuple[str, int]]:
        """Extract key topics and terms from the captions."""
        if not self.full_text:
            return []
        
        # Simple keyword extraction
        words = re.findall(rf'\b\w{{{min_word_length},}}\b', self.full_text.lower())
        
        # Filter out common stop words
        stop_words = {
            'this', 'that', 'with', 'have', 'will', 'from', 'they', 'been', 
            'were', 'said', 'each', 'which', 'their', 'time', 'would', 'there',
            'what', 'when', 'where', 'your', 'just', 'like', 'dont', 'really',
            'think', 'know', 'good', 'great', 'going', 'want', 'need', 'make',
            'right', 'here', 'come', 'well', 'also', 'look', 'now'
        }
        
        from collections import Counter
        filtered_words = [w for w in words if w not in stop_words]
        return Counter(filtered_words).most_common(top_n)
    
    def find_technical_terms(self) -> List[str]:
        """Find technical terms related to containers and DevOps."""
        technical_patterns = [
            r'\b(?:docker|podman|kubernetes|k8s)\b',
            r'\b(?:container|containers|containerized?)\b',
            r'\b(?:image|images|registry|registries)\b',
            r'\b(?:pod|pods|deployment|deployments)\b',
            r'\b(?:volume|volumes|mount|mounts)\b',
            r'\b(?:network|networking|port|ports)\b',
            r'\b(?:security|privilege|rootless|namespaces?)\b',
            r'\b(?:orchestration|scaling|monitoring)\b',
            r'\b(?:ci/cd|pipeline|build|dockerfile)\b',
            r'\b(?:microservices?|service|services)\b'
        ]
        
        technical_terms = set()
        text_lower = self.full_text.lower()
        
        for pattern in technical_patterns:
            matches = re.findall(pattern, text_lower)
            technical_terms.update(matches)
        
        return sorted(list(technical_terms))
    
    def analyze_content_structure(self) -> Dict:
        """Analyze the structure and flow of the video content."""
        if not self.segments:
            return {}
        
        # Identify potential sections/topics
        segment_texts = [seg.get('text', '') for seg in self.segments]
        
        # Look for transition words/phrases
        transition_patterns = [
            r'\b(?:first|second|third|next|then|finally|lastly)\b',
            r'\b(?:now|so|however|but|therefore|because)\b',
            r'\b(?:let\'s|we\'ll|we\'re going to)\b'
        ]
        
        transitions = []
        for i, segment in enumerate(self.segments):
            text = segment.get('text', '').lower()
            for pattern in transition_patterns:
                if re.search(pattern, text):
                    transitions.append({
                        'timestamp': segment.get('timestamp', '00:00:00'),
                        'text': segment.get('text', '')[:100] + '...',
                        'segment_index': i
                    })
        
        # Calculate speaking rate variations
        rates = []
        for segment in self.segments:
            duration = segment.get('duration', 0)
            words = len(segment.get('text', '').split())
            if duration > 0:
                rate = (words / duration) * 60  # Words per minute
                rates.append(rate)
        
        avg_rate = sum(rates) / len(rates) if rates else 0
        
        return {
            'total_segments': len(self.segments),
            'transitions_found': len(transitions),
            'transition_points': transitions[:10],  # Top 10 transitions
            'average_speaking_rate': avg_rate,
            'content_density': len(self.full_text.split()) / self.statistics.get('total_duration', 1)
        }
    
    def generate_summary(self) -> str:
        """Generate a comprehensive summary of the caption analysis."""
        if not self.full_text:
            return "No caption data available for analysis."
        
        key_topics = self.extract_key_topics(top_n=10)
        technical_terms = self.find_technical_terms()
        structure = self.analyze_content_structure()
        
        summary = []
        summary.append("📹 CAPTION CONTENT ANALYSIS")
        summary.append("=" * 50)
        
        # Basic statistics
        stats = self.statistics
        summary.append(f"📊 Video Duration: {stats.get('duration_formatted', 'Unknown')}")
        summary.append(f"📝 Total Words: {stats.get('total_words', 0):,}")
        summary.append(f"⚡ Speaking Rate: {stats.get('words_per_minute', 0):.1f} words/minute")
        summary.append(f"📋 Caption Segments: {stats.get('total_segments', 0):,}")
        
        # Key topics
        if key_topics:
            summary.append(f"\n🎯 MOST MENTIONED TOPICS:")
            for i, (topic, count) in enumerate(key_topics[:8], 1):
                summary.append(f"   {i:2d}. {topic} ({count} mentions)")
        
        # Technical terms
        if technical_terms:
            summary.append(f"\n🔧 TECHNICAL TERMS COVERED:")
            summary.append(f"   {', '.join(technical_terms[:15])}")
            if len(technical_terms) > 15:
                summary.append(f"   ... and {len(technical_terms) - 15} more")
        
        # Content structure insights
        if structure:
            summary.append(f"\n📐 CONTENT STRUCTURE:")
            summary.append(f"   • Transitions identified: {structure.get('transitions_found', 0)}")
            summary.append(f"   • Average speaking rate: {structure.get('average_speaking_rate', 0):.1f} WPM")
            summary.append(f"   • Content density: {structure.get('content_density', 0):.1f} words/second")
        
        return '\n'.join(summary)


def download_captions_for_video(video_url: str, language_code: str = 'en',
                               output_format: str = 'json', output_dir: Optional[str] = None,
                               include_auto_generated: bool = True) -> Dict:
    """
    Convenience function to download captions for a video.
    
    Args:
        video_url: YouTube video URL or ID
        language_code: Language code to download ('en', 'all' for all languages)
        output_format: Output format ('json', 'txt', 'srt', 'vtt')
        output_dir: Output directory (auto-generated if None)
        include_auto_generated: Include auto-generated captions
        
    Returns:
        Dictionary with download results
    """
    downloader = YouTubeCaptionDownloader()
    video_id = downloader.extract_video_id(video_url)
    
    print(f"📹 Downloading captions for video: {video_id}")
    
    # Check available transcripts
    available = downloader.get_available_transcripts(video_id)
    if 'error' in available:
        return available
    
    print(f"   ✅ Found {available['total_count']} available transcripts")
    
    # Download captions
    if language_code.lower() == 'all':
        # Download all available captions
        results = downloader.download_all_captions(video_id, include_auto_generated)
    else:
        # Download specific language
        results = downloader.download_caption(video_id, language_code)
        if 'error' not in results:
            results = {'captions': {language_code: results}}
    
    # Export to files if requested
    if output_format and 'error' not in results:
        if not output_dir:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_dir = Path("tmp") / f"captions_{video_id}_{timestamp}"
        else:
            output_dir = Path(output_dir)
        
        output_dir.mkdir(parents=True, exist_ok=True)
        
        exported_files = []
        
        if 'captions' in results:
            for lang_code, caption_data in results['captions'].items():
                # Determine output filename
                base_filename = f"captions_{video_id}_{lang_code}"
                
                if output_format == 'json':
                    output_file = output_dir / f"{base_filename}.json"
                    downloader.export_captions_to_json(caption_data, output_file)
                elif output_format == 'txt':
                    output_file = output_dir / f"{base_filename}.txt"
                    downloader.export_captions_to_txt(caption_data, output_file)
                elif output_format == 'srt':
                    output_file = output_dir / f"{base_filename}.srt"
                    downloader.export_captions_to_srt(caption_data, output_file)
                elif output_format == 'vtt':
                    output_file = output_dir / f"{base_filename}.vtt"
                    downloader.export_captions_to_vtt(caption_data, output_file)
                
                exported_files.append(str(output_file))
                
                # Generate analysis for first caption set
                if lang_code == language_code or language_code.lower() == 'all':
                    analyzer = CaptionAnalyzer(caption_data)
                    analysis = analyzer.generate_summary()
                    
                    analysis_file = output_dir / f"analysis_{lang_code}.txt"
                    with open(analysis_file, 'w', encoding='utf-8') as f:
                        f.write(f"YouTube Caption Analysis\n")
                        f.write(f"Video ID: {video_id}\n")
                        f.write(f"Language: {lang_code}\n")
                        f.write(f"Generated: {datetime.now().isoformat()}\n\n")
                        f.write("=" * 60 + "\n\n")
                        f.write(analysis)
                    
                    exported_files.append(str(analysis_file))
                    print(f"   💡 Analysis saved to: {analysis_file}")
        
        results['exported_files'] = exported_files
        print(f"   📁 Files saved to: {output_dir}")
        
    return results


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python3 youtube_caption_downloader.py <video_url> [language_code] [format]")
        print("\nExamples:")
        print("  python3 youtube_caption_downloader.py 'https://youtube.com/watch?v=VIDEO_ID'")
        print("  python3 youtube_caption_downloader.py VIDEO_ID en txt")
        print("  python3 youtube_caption_downloader.py VIDEO_ID all json")
        print("\nFormats: json, txt, srt, vtt")
        print("Languages: en, es, fr, de, or 'all' for all available")
        sys.exit(1)
    
    video_url = sys.argv[1]
    language = sys.argv[2] if len(sys.argv) > 2 else 'en'
    format_type = sys.argv[3] if len(sys.argv) > 3 else 'json'
    
    results = download_captions_for_video(video_url, language, format_type)
    
    if 'error' in results:
        print(f"❌ Error: {results['error']}")
        sys.exit(1)
    
    print("✅ Caption download completed successfully!")