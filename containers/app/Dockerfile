# YouTube Analytics Tools Container
# Multi-stage build for optimal security and size
FROM python:3.11-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements first for better caching
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# Production stage
FROM python:3.11-slim AS production

# Create non-root user for security
RUN groupadd -r analytics && useradd -r -g analytics -s /bin/bash analytics

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy application code with proper ownership
COPY --chown=analytics:analytics . .

# Create output directories with proper permissions
RUN mkdir -p /app/tmp /app/data /app/output && \
    chown -R analytics:analytics /app/tmp /app/data /app/output

# Switch to non-root user
USER analytics

# Set environment variables for container operation
ENV PYTHONPATH=/app/src
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Health check to verify dependencies are working
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import googleapiclient.discovery, anthropic, youtube_transcript_api; print('Dependencies OK')" || exit 1

# Default command shows help
CMD ["python", "-c", "print('YouTube Analytics Tools Container\\n'); print('Available commands:'); print('  podman run --rm -e YOUTUBE_API_KEY=key youtube-analytics python scripts/youtube-comment-scraper.py --help'); print('  podman run --rm -e ANTHROPIC_API_KEY=key youtube-analytics python src/app/ai_comment_analyzer.py --help'); print('  podman run --rm youtube-analytics python src/app/youtube_caption_downloader.py --help'); print('  podman run --rm -e YOUTUBE_API_KEY=key -e ANTHROPIC_API_KEY=key youtube-analytics python scripts/youtube-content-scraper.py --help')"]
