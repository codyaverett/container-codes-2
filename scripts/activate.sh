#!/bin/bash
# Quick activation script for YouTube Analytics virtual environment

VENV_NAME=".venv"

if [[ -z "${VIRTUAL_ENV}" ]]; then
    if [[ -f "$VENV_NAME/bin/activate" ]]; then
        source "$VENV_NAME/bin/activate"
        echo "✓ Virtual environment activated"
        echo "Python: $(which python)"
        echo "Version: $(python --version)"
        echo ""
        echo "Available commands:"
        echo "  python scripts/youtube-comment-scraper.py"
        echo "  python scripts/youtube-content-scraper.py"
        echo "  python src/app/youtube_caption_downloader.py"
        echo "  python src/app/ai_comment_analyzer.py"
        echo ""
        echo "Type 'deactivate' to exit the virtual environment"
    else
        echo "❌ Virtual environment not found!"
        echo "Run './setup-venv.sh' first to create it"
    fi
else
    echo "Virtual environment is already activated: $VIRTUAL_ENV"
fi
