#!/usr/bin/env python3
"""
ContainerCodes Content Generation Tool
Automated content creation and management for YouTube episodes
"""

import os
import sys
import json
import argparse
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

class ContentGenerator:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.videos_dir = self.project_root / "videos"
        self.templates_dir = self.project_root / "templates"
        self.notes_dir = self.project_root / "notes"
        
    def create_episode(self, episode_num: int, title: str, difficulty: str = "Intermediate", 
                      duration: str = "18-22 minutes") -> Path:
        """Create a new episode structure with templates."""
        episode_name = self._sanitize_filename(title)
        episode_dir = self.videos_dir / f"episode-{episode_num:03d}-{episode_name}"
        
        # Create directory structure
        episode_dir.mkdir(exist_ok=True)
        (episode_dir / "demo").mkdir(exist_ok=True)
        
        # Load episode template
        template_path = self.templates_dir / "episode-template.md"
        if template_path.exists():
            template_content = template_path.read_text()
            
            # Replace template variables
            content = template_content.replace("[NUMBER]", f"{episode_num:03d}")
            content = content.replace("[TITLE]", title)
            content = content.replace("[Estimated time]", duration)
            content = content.replace("[Beginner/Intermediate/Advanced]", difficulty)
            
            # Write script
            script_path = episode_dir / "script.md"
            script_path.write_text(content)
            
            print(f"✅ Created episode script: {script_path}")
        
        # Create placeholder files
        files_to_create = {
            "references.md": f"# Episode {episode_num:03d} References: {title}\n\n## Documentation Links\n\nTBD\n",
            "viewer-questions.md": f"# Episode {episode_num:03d} Viewer Questions: {title}\n\n## Common Questions\n\nTBD\n",
            "demo/README.md": f"# Episode {episode_num:03d} Demo Files\n\nDemo code and scripts for {title}\n"
        }
        
        for filename, content in files_to_create.items():
            file_path = episode_dir / filename
            if not file_path.exists():
                file_path.write_text(content)
                print(f"✅ Created: {file_path}")
        
        return episode_dir
    
    def generate_content_calendar(self, weeks: int = 12) -> Dict:
        """Generate a content calendar for planning."""
        calendar = {
            "generated": datetime.now().isoformat(),
            "weeks": weeks,
            "episodes": []
        }
        
        # Episode planning template
        episode_topics = [
            {"title": "Container Internals Deep Dive", "difficulty": "Intermediate", "category": "fundamentals"},
            {"title": "Podman vs Docker: Security Revolution", "difficulty": "Intermediate", "category": "security"},
            {"title": "Building Without Docker: Buildah Mastery", "difficulty": "Advanced", "category": "building"},
            {"title": "Container Image Surgery with Skopeo", "difficulty": "Intermediate", "category": "management"},
            {"title": "Kubernetes Pod Deep Dive", "difficulty": "Advanced", "category": "orchestration"},
            {"title": "Container Security Hardening", "difficulty": "Intermediate", "category": "security"},
            {"title": "AI Workloads on Kubernetes", "difficulty": "Advanced", "category": "specialized"},
            {"title": "Multi-Cloud Container Orchestration", "difficulty": "Advanced", "category": "orchestration"},
            {"title": "Container Performance Optimization", "difficulty": "Intermediate", "category": "performance"},
            {"title": "Systemd + Containers: The Perfect Marriage", "difficulty": "Intermediate", "category": "integration"},
            {"title": "Container Networking Deep Dive", "difficulty": "Advanced", "category": "networking"},
            {"title": "GitOps with Containers", "difficulty": "Advanced", "category": "deployment"}
        ]
        
        for i, topic in enumerate(episode_topics[:weeks], 1):
            episode = {
                "episode_number": i,
                "title": topic["title"],
                "difficulty": topic["difficulty"],
                "category": topic["category"],
                "planned_date": f"Week {i}",
                "duration": "18-22 minutes",
                "status": "planned"
            }
            calendar["episodes"].append(episode)
        
        return calendar
    
    def create_note_structure(self, topic: str, category: str) -> Path:
        """Create note structure for a specific topic."""
        topic_name = self._sanitize_filename(topic)
        category_dir = self.notes_dir / category
        topic_dir = category_dir / topic_name
        
        # Create directories
        topic_dir.mkdir(parents=True, exist_ok=True)
        
        # Load notes template
        template_path = self.templates_dir / "notes-template.md"
        if template_path.exists():
            template_content = template_path.read_text()
            content = template_content.replace("[Topic Title]", topic)
            content = content.replace("[Date]", datetime.now().strftime("%Y-%m-%d"))
            
            readme_path = topic_dir / "README.md"
            readme_path.write_text(content)
            print(f"✅ Created notes: {readme_path}")
        
        return topic_dir
    
    def generate_example_structure(self, name: str, category: str, 
                                 difficulty: str = "Intermediate") -> Path:
        """Create example project structure."""
        example_name = self._sanitize_filename(name)
        category_dir = self.project_root / "examples" / category
        example_dir = category_dir / example_name
        
        # Create directories
        example_dir.mkdir(parents=True, exist_ok=True)
        
        # Load example template
        template_path = self.templates_dir / "example-template.md"
        if template_path.exists():
            template_content = template_path.read_text()
            content = template_content.replace("[Example Title]", name)
            content = content.replace("[Development/Testing/Production]", category.title())
            content = content.replace("[Beginner/Intermediate/Advanced]", difficulty)
            
            readme_path = example_dir / "README.md"
            readme_path.write_text(content)
            print(f"✅ Created example: {readme_path}")
        
        # Create basic structure
        (example_dir / "scripts").mkdir(exist_ok=True)
        (example_dir / "config").mkdir(exist_ok=True)
        
        return example_dir
    
    def validate_content(self) -> List[str]:
        """Validate existing content structure."""
        issues = []
        
        # Check episode structure
        for episode_dir in self.videos_dir.glob("episode-*"):
            if episode_dir.is_dir():
                required_files = ["script.md", "references.md", "viewer-questions.md"]
                for required_file in required_files:
                    if not (episode_dir / required_file).exists():
                        issues.append(f"Missing {required_file} in {episode_dir.name}")
        
        # Check templates
        required_templates = ["episode-template.md", "notes-template.md", "example-template.md"]
        for template in required_templates:
            if not (self.templates_dir / template).exists():
                issues.append(f"Missing template: {template}")
        
        return issues
    
    def _sanitize_filename(self, name: str) -> str:
        """Convert title to filesystem-safe name."""
        # Replace spaces and special characters
        safe_name = name.lower().replace(" ", "-")
        safe_name = "".join(c for c in safe_name if c.isalnum() or c in "-_")
        return safe_name
    
    def list_content(self) -> Dict:
        """List all existing content."""
        content = {
            "episodes": [],
            "notes": [],
            "examples": []
        }
        
        # List episodes
        for episode_dir in sorted(self.videos_dir.glob("episode-*")):
            if episode_dir.is_dir():
                script_file = episode_dir / "script.md"
                title = "Unknown Title"
                if script_file.exists():
                    # Try to extract title from script
                    lines = script_file.read_text().split('\n')
                    for line in lines:
                        if line.startswith("# Episode"):
                            title = line.replace("# Episode", "").strip()
                            break
                
                content["episodes"].append({
                    "directory": episode_dir.name,
                    "title": title,
                    "files": [f.name for f in episode_dir.iterdir() if f.is_file()]
                })
        
        # List notes
        for category_dir in self.notes_dir.iterdir():
            if category_dir.is_dir() and category_dir.name != "__pycache__":
                for topic_dir in category_dir.iterdir():
                    if topic_dir.is_dir():
                        content["notes"].append({
                            "category": category_dir.name,
                            "topic": topic_dir.name,
                            "path": str(topic_dir.relative_to(self.project_root))
                        })
        
        # List examples
        examples_dir = self.project_root / "examples"
        if examples_dir.exists():
            for category_dir in examples_dir.iterdir():
                if category_dir.is_dir() and category_dir.name != "__pycache__":
                    for example_dir in category_dir.iterdir():
                        if example_dir.is_dir():
                            content["examples"].append({
                                "category": category_dir.name,
                                "name": example_dir.name,
                                "path": str(example_dir.relative_to(self.project_root))
                            })
        
        return content

def main():
    parser = argparse.ArgumentParser(description="ContainerCodes Content Generator")
    parser.add_argument("--project-root", default=".", help="Project root directory")
    
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Episode creation
    episode_parser = subparsers.add_parser("episode", help="Create new episode")
    episode_parser.add_argument("number", type=int, help="Episode number")
    episode_parser.add_argument("title", help="Episode title")
    episode_parser.add_argument("--difficulty", choices=["Beginner", "Intermediate", "Advanced"], 
                               default="Intermediate", help="Episode difficulty")
    episode_parser.add_argument("--duration", default="18-22 minutes", help="Episode duration")
    
    # Notes creation
    notes_parser = subparsers.add_parser("notes", help="Create notes structure")
    notes_parser.add_argument("topic", help="Topic name")
    notes_parser.add_argument("category", help="Category (e.g., podman, buildah)")
    
    # Example creation
    example_parser = subparsers.add_parser("example", help="Create example project")
    example_parser.add_argument("name", help="Example name")
    example_parser.add_argument("category", help="Category (development-workflows, etc.)")
    example_parser.add_argument("--difficulty", choices=["Beginner", "Intermediate", "Advanced"], 
                               default="Intermediate", help="Example difficulty")
    
    # Content management
    subparsers.add_parser("list", help="List all content")
    subparsers.add_parser("validate", help="Validate content structure")
    
    # Calendar generation
    calendar_parser = subparsers.add_parser("calendar", help="Generate content calendar")
    calendar_parser.add_argument("--weeks", type=int, default=12, help="Number of weeks to plan")
    calendar_parser.add_argument("--output", help="Output file for calendar")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    generator = ContentGenerator(args.project_root)
    
    try:
        if args.command == "episode":
            episode_dir = generator.create_episode(args.number, args.title, 
                                                 args.difficulty, args.duration)
            print(f"🎬 Episode {args.number:03d} created at: {episode_dir}")
        
        elif args.command == "notes":
            notes_dir = generator.create_note_structure(args.topic, args.category)
            print(f"📝 Notes created at: {notes_dir}")
        
        elif args.command == "example":
            example_dir = generator.generate_example_structure(args.name, args.category, 
                                                             args.difficulty)
            print(f"💻 Example created at: {example_dir}")
        
        elif args.command == "list":
            content = generator.list_content()
            print("📚 ContainerCodes Content Overview")
            print(f"\n🎬 Episodes ({len(content['episodes'])})")
            for episode in content["episodes"]:
                print(f"  - {episode['directory']}: {episode['title']}")
            
            print(f"\n📝 Notes ({len(content['notes'])})")
            for note in content["notes"]:
                print(f"  - {note['category']}/{note['topic']}")
            
            print(f"\n💻 Examples ({len(content['examples'])})")
            for example in content["examples"]:
                print(f"  - {example['category']}/{example['name']}")
        
        elif args.command == "validate":
            issues = generator.validate_content()
            if issues:
                print("❌ Content validation issues found:")
                for issue in issues:
                    print(f"  - {issue}")
                sys.exit(1)
            else:
                print("✅ Content validation passed!")
        
        elif args.command == "calendar":
            calendar = generator.generate_content_calendar(args.weeks)
            if args.output:
                with open(args.output, 'w') as f:
                    json.dump(calendar, f, indent=2)
                print(f"📅 Content calendar saved to: {args.output}")
            else:
                print("📅 Content Calendar")
                for episode in calendar["episodes"]:
                    print(f"Episode {episode['episode_number']:02d}: {episode['title']} "
                          f"({episode['difficulty']}) - {episode['planned_date']}")
    
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()