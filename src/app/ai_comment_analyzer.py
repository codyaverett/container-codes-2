"""
AI-Powered YouTube Comment Analyzer
Enhanced comment analysis using Anthropic's Claude AI for deeper insights
"""

import os
import json
import sys
from typing import Dict, List, Optional, Tuple
from datetime import datetime

try:
    import anthropic
except ImportError:
    raise ImportError(
        "Anthropic SDK not installed. Run: pip install anthropic>=0.40.0"
    )


class AICommentAnalyzer:
    """
    AI-powered YouTube comment analyzer using Anthropic's Claude.
    
    Provides advanced sentiment analysis, content categorization,
    and actionable insights for video creators.
    """
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize the AI comment analyzer.
        
        Args:
            api_key: Anthropic API key. If None, will try to get from environment.
        """
        self.api_key = api_key or os.environ.get('ANTHROPIC_API_KEY')
        if not self.api_key:
            raise ValueError(
                "Anthropic API key required. Set ANTHROPIC_API_KEY environment variable "
                "or pass api_key parameter."
            )
        
        self.client = anthropic.Anthropic(api_key=self.api_key)
        self.model = "claude-3-5-sonnet-20241022"
    
    def analyze_sentiment_and_themes(self, comments: List[Dict]) -> Dict:
        """
        Analyze sentiment and extract themes from comments using Claude.
        
        Args:
            comments: List of comment dictionaries
            
        Returns:
            Dictionary with sentiment analysis and themes
        """
        if not comments:
            return {"error": "No comments to analyze"}
        
        # Prepare comment text for analysis (limit to prevent token overflow)
        comment_texts = []
        for comment in comments[:100]:  # Analyze top 100 comments
            text = comment.get('text', '').strip()
            likes = comment.get('like_count', 0)
            if text and len(text) > 10:  # Filter out very short comments
                comment_texts.append(f"[{likes} likes] {text}")
        
        if not comment_texts:
            return {"error": "No substantial comments found"}
        
        # Create the analysis prompt
        prompt = f"""
Analyze these YouTube comments for a technical container/DevOps education channel called "ContainerCodes". 

Comments to analyze:
{chr(10).join(comment_texts[:50])}  

Please provide:

1. **Sentiment Analysis**: Overall sentiment distribution (positive/neutral/negative percentages)

2. **Key Themes**: Top 5-7 themes or topics mentioned by viewers

3. **Learning Indicators**: Evidence of learning, understanding, or confusion

4. **Content Requests**: Any specific requests for future content or topics

5. **Technical Depth**: Assessment of audience technical level and interests

6. **Engagement Quality**: Quality of engagement (thoughtful vs. superficial)

7. **Actionable Insights**: 3-5 specific recommendations for the content creator

Format your response as a structured analysis that would be useful for a technical educator planning future content.
"""
        
        try:
            response = self.client.messages.create(
                model=self.model,
                max_tokens=2000,
                messages=[{
                    "role": "user", 
                    "content": prompt
                }]
            )
            
            return {
                "analysis": response.content[0].text,
                "comments_analyzed": len(comment_texts),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {"error": f"AI analysis failed: {str(e)}"}
    
    def categorize_comments(self, comments: List[Dict]) -> Dict:
        """
        Categorize comments into different types using Claude.
        
        Args:
            comments: List of comment dictionaries
            
        Returns:
            Dictionary with categorized comments
        """
        if not comments:
            return {"error": "No comments to categorize"}
        
        # Sample comments for categorization (limit for API efficiency)
        sample_comments = []
        for comment in comments[:50]:
            text = comment.get('text', '').strip()
            if text and len(text) > 15:
                sample_comments.append({
                    'text': text,
                    'author': comment.get('author', 'Unknown'),
                    'likes': comment.get('like_count', 0)
                })
        
        if not sample_comments:
            return {"error": "No substantial comments found"}
        
        # Create categorization prompt
        comment_list = []
        for i, comment in enumerate(sample_comments, 1):
            comment_list.append(f"{i}. [{comment['likes']} likes] {comment['text']}")
        
        prompt = f"""
Categorize these YouTube comments from a technical container/DevOps education channel into the following categories:

**Categories:**
- Questions: Comments asking specific questions
- Feedback: Positive or constructive feedback on the content  
- Requests: Requests for future content or topics
- Technical Discussion: Comments showing technical understanding or adding insights
- Appreciation: Simple thanks or praise
- Suggestions: Suggestions for improvements
- Troubleshooting: Comments about problems or issues
- Other: Comments that don't fit other categories

**Comments to categorize:**
{chr(10).join(comment_list)}

For each category that has comments, list:
1. The comment numbers that belong to that category
2. A brief summary of what those comments indicate
3. Any patterns you notice

Focus on actionable insights for the content creator.
"""
        
        try:
            response = self.client.messages.create(
                model=self.model,
                max_tokens=1500,
                messages=[{
                    "role": "user",
                    "content": prompt
                }]
            )
            
            return {
                "categorization": response.content[0].text,
                "comments_categorized": len(sample_comments),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {"error": f"Categorization failed: {str(e)}"}
    
    def generate_content_recommendations(self, comments: List[Dict], video_info: Optional[Dict] = None) -> Dict:
        """
        Generate content recommendations based on comment analysis.
        
        Args:
            comments: List of comment dictionaries
            video_info: Optional video information
            
        Returns:
            Dictionary with content recommendations
        """
        if not comments:
            return {"error": "No comments to analyze for recommendations"}
        
        # Extract key comments for analysis
        high_engagement_comments = [
            c for c in comments 
            if c.get('like_count', 0) > 1 and len(c.get('text', '')) > 20
        ]
        
        # Sort by engagement
        high_engagement_comments.sort(key=lambda x: x.get('like_count', 0), reverse=True)
        
        # Prepare context
        video_context = ""
        if video_info:
            video_context = f"""
**Current Video Context:**
- Title: {video_info.get('title', 'Unknown')}
- Views: {video_info.get('view_count', 0):,}
- Comments: {video_info.get('comment_count', 0):,}
- Likes: {video_info.get('like_count', 0):,}
"""
        
        # Prepare comment sample
        comment_sample = []
        for comment in high_engagement_comments[:30]:
            text = comment.get('text', '').strip()
            likes = comment.get('like_count', 0)
            comment_sample.append(f"[{likes} likes] {text}")
        
        prompt = f"""
Based on these high-engagement comments from a technical container/DevOps education YouTube channel, generate specific content recommendations.

{video_context}

**High-Engagement Comments:**
{chr(10).join(comment_sample)}

Please provide:

1. **Next Video Topics**: 3-5 specific video topics based on viewer requests and interests

2. **Content Gaps**: Areas where viewers seem confused or need more explanation  

3. **Format Suggestions**: Recommended content formats (tutorials, deep-dives, comparisons, etc.)

4. **Technical Level Adjustment**: Should content be more beginner-friendly or more advanced?

5. **Follow-up Opportunities**: Questions or topics that warrant dedicated follow-up content

6. **Community Engagement Ideas**: Ways to better engage this specific audience

Focus on actionable, specific recommendations that align with the channel's mission of technical container education.
"""
        
        try:
            response = self.client.messages.create(
                model=self.model,
                max_tokens=1800,
                messages=[{
                    "role": "user",
                    "content": prompt
                }]
            )
            
            return {
                "recommendations": response.content[0].text,
                "based_on_comments": len(comment_sample),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {"error": f"Recommendation generation failed: {str(e)}"}
    
    def analyze_questions_for_faq(self, comments: List[Dict]) -> Dict:
        """
        Extract and analyze questions for FAQ creation using Claude.
        
        Args:
            comments: List of comment dictionaries
            
        Returns:
            Dictionary with FAQ analysis
        """
        if not comments:
            return {"error": "No comments to analyze for FAQ"}
        
        # Extract potential questions
        question_comments = []
        for comment in comments:
            text = comment.get('text', '').strip()
            if ('?' in text or 
                any(word in text.lower() for word in ['how', 'what', 'why', 'when', 'where', 'which', 'can you'])):
                question_comments.append({
                    'text': text,
                    'author': comment.get('author', 'Unknown'),
                    'likes': comment.get('like_count', 0)
                })
        
        # Sort by engagement
        question_comments.sort(key=lambda x: x.get('likes', 0), reverse=True)
        
        if not question_comments:
            return {"error": "No questions found in comments"}
        
        # Prepare question list
        question_list = []
        for i, comment in enumerate(question_comments[:25], 1):
            question_list.append(f"{i}. [{comment['likes']} likes] {comment['text']}")
        
        prompt = f"""
Analyze these questions from YouTube comments on a technical container/DevOps education channel to create FAQ content.

**Questions from viewers:**
{chr(10).join(question_list)}

Please provide:

1. **Top Questions**: The 5-7 most important questions that should be answered in an FAQ

2. **Question Categories**: Group similar questions together (e.g., "Getting Started", "Troubleshooting", "Best Practices")

3. **Priority Ranking**: Which questions are most urgent to address based on engagement and frequency

4. **Answer Complexity**: For each key question, indicate if it needs a simple answer, detailed explanation, or dedicated video

5. **Common Misconceptions**: Any incorrect assumptions or misunderstandings revealed in the questions

6. **Educational Opportunities**: Questions that reveal good teaching moments or content gaps

Format the output as actionable FAQ content that could be used in video descriptions, community posts, or dedicated FAQ videos.
"""
        
        try:
            response = self.client.messages.create(
                model=self.model,
                max_tokens=1800,
                messages=[{
                    "role": "user",
                    "content": prompt
                }]
            )
            
            return {
                "faq_analysis": response.content[0].text,
                "questions_analyzed": len(question_comments),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {"error": f"FAQ analysis failed: {str(e)}"}
    
    def generate_complete_ai_report(self, comments: List[Dict], video_info: Optional[Dict] = None) -> Dict:
        """
        Generate a complete AI-powered analysis report.
        
        Args:
            comments: List of comment dictionaries
            video_info: Optional video information
            
        Returns:
            Dictionary with complete analysis report
        """
        print("🤖 Generating AI-powered analysis report...")
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "comments_count": len(comments),
            "video_info": video_info
        }
        
        # Run all analyses
        print("   🔍 Analyzing sentiment and themes...")
        report["sentiment_analysis"] = self.analyze_sentiment_and_themes(comments)
        
        print("   📂 Categorizing comments...")
        report["categorization"] = self.categorize_comments(comments)
        
        print("   💡 Generating content recommendations...")
        report["recommendations"] = self.generate_content_recommendations(comments, video_info)
        
        print("   ❓ Analyzing questions for FAQ...")
        report["faq_analysis"] = self.analyze_questions_for_faq(comments)
        
        return report


def enhance_existing_analysis(comments_file: str, api_key: Optional[str] = None) -> None:
    """
    Enhance existing comment analysis with AI insights.
    
    Args:
        comments_file: Path to JSON file with comments
        api_key: Optional Anthropic API key
    """
    try:
        # Load comments
        with open(comments_file, 'r', encoding='utf-8') as f:
            comments = json.load(f)
    except FileNotFoundError:
        print(f"❌ Error: File '{comments_file}' not found.")
        return
    except json.JSONDecodeError:
        print(f"❌ Error: Invalid JSON in file '{comments_file}'.")
        return
    
    if not comments:
        print("❌ No comments found in the file.")
        return
    
    # Initialize AI analyzer
    try:
        analyzer = AICommentAnalyzer(api_key)
    except ValueError as e:
        print(f"❌ {e}")
        print("\nTo get an Anthropic API key:")
        print("1. Go to https://console.anthropic.com/")
        print("2. Create an account or sign in")
        print("3. Generate an API key")
        print("4. Set the ANTHROPIC_API_KEY environment variable")
        return
    except Exception as e:
        print(f"❌ Failed to initialize AI analyzer: {e}")
        return
    
    # Generate complete AI report
    try:
        report = analyzer.generate_complete_ai_report(comments)
        
        # Display results
        print("\n" + "="*60)
        print("🤖 AI-POWERED COMMENT ANALYSIS REPORT")
        print("="*60)
        
        # Sentiment Analysis
        if "error" not in report["sentiment_analysis"]:
            print("\n📊 SENTIMENT & THEMES ANALYSIS")
            print("-" * 40)
            print(report["sentiment_analysis"]["analysis"])
        
        # Categorization
        if "error" not in report["categorization"]:
            print("\n📂 COMMENT CATEGORIZATION")
            print("-" * 40)
            print(report["categorization"]["categorization"])
        
        # Recommendations  
        if "error" not in report["recommendations"]:
            print("\n💡 CONTENT RECOMMENDATIONS")
            print("-" * 40)
            print(report["recommendations"]["recommendations"])
        
        # FAQ Analysis
        if "error" not in report["faq_analysis"]:
            print("\n❓ FAQ ANALYSIS")
            print("-" * 40)
            print(report["faq_analysis"]["faq_analysis"])
        
        # Save enhanced report
        output_file = comments_file.replace('.json', '_ai_analysis.json')
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\n✅ Complete AI analysis saved to: {output_file}")
        print(f"🎯 Based on {len(comments)} comments")
        
    except Exception as e:
        print(f"❌ AI analysis failed: {e}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 ai_comment_analyzer.py <comments.json>")
        print("\nExample:")
        print("  python3 ai_comment_analyzer.py episode_comments.json")
        print("\nThis will generate an AI-powered analysis using Anthropic's Claude.")
        print("Make sure to set your ANTHROPIC_API_KEY environment variable.")
        sys.exit(1)
    
    enhance_existing_analysis(sys.argv[1])