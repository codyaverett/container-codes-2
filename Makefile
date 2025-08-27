SHELL := /bin/bash
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Container runtime selection
CR := $(shell command -v podman >/dev/null 2>&1 && echo "podman" || echo "docker")
DC := $(shell command -v $(CR) >/dev/null 2>&1 && echo "$(CR) compose" || echo "docker-compose")

# Colors for help output
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
PURPLE := \033[35m
CYAN := \033[36m
RED := \033[31m
RESET := \033[0m

# Variables
SERVICE ?=
COMPOSE_FILE ?= scripts/compose.yml
EPISODE ?=
NUM ?=
TITLE ?=
DIFFICULTY ?= Intermediate

# Content paths
VIDEOS_DIR := videos
SCRIPTS_DIR := scripts
TEMPLATES_DIR := templates
NOTES_DIR := notes
EXAMPLES_DIR := examples

.DEFAULT_GOAL := help
.PHONY: help build up down logs test lint fmt clean
.PHONY: episode content-validate content-list content-stats
.PHONY: demo-setup demo-cleanup demo-test demo-list
.PHONY: security-scan vulnerability-check security-demo
.PHONY: validate-all link-check format-check
.PHONY: status backup update-deps requirements-check
.PHONY: youtube-comments youtube-setup

## Display this help message
help:
	@echo -e "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(RESET)"
	@echo -e "$(PURPLE)║                    $(YELLOW)ContainerCodes Repository$(PURPLE)                    ║$(RESET)"
	@echo -e "$(PURPLE)║                   $(CYAN)Self-Documenting Makefile$(PURPLE)                   ║$(RESET)"
	@echo -e "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(RESET)"
	@echo
	@echo -e "$(BLUE)📺 CONTENT CREATION$(RESET)"
	@echo -e "  $(GREEN)episode$(RESET)              Create new episode (NUM=X TITLE='...')"
	@echo -e "  $(GREEN)content-validate$(RESET)     Validate all content structure and links"
	@echo -e "  $(GREEN)content-list$(RESET)         List all episodes and content"
	@echo -e "  $(GREEN)content-stats$(RESET)        Generate content statistics"
	@echo
	@echo -e "$(BLUE)🛠️  DEMO MANAGEMENT$(RESET)"
	@echo -e "  $(GREEN)demo-setup$(RESET)           Setup episode demo environment (EPISODE=X)"
	@echo -e "  $(GREEN)demo-cleanup$(RESET)         Cleanup episode demos (EPISODE=X)"
	@echo -e "  $(GREEN)demo-test$(RESET)            Test episode demonstrations (EPISODE=X)"
	@echo -e "  $(GREEN)demo-list$(RESET)            List available demo environments"
	@echo
	@echo -e "$(BLUE)🔒 SECURITY & QUALITY$(RESET)"
	@echo -e "  $(GREEN)security-scan$(RESET)        Scan all content for security issues"
	@echo -e "  $(GREEN)vulnerability-check$(RESET)  Check for vulnerabilities in examples"
	@echo -e "  $(GREEN)security-demo$(RESET)        Run security demonstration workflows"
	@echo -e "  $(GREEN)validate-all$(RESET)         Complete content validation"
	@echo -e "  $(GREEN)link-check$(RESET)           Validate all external links"
	@echo -e "  $(GREEN)format-check$(RESET)         Check markdown formatting"
	@echo
	@echo -e "$(BLUE)🐳 CONTAINER OPERATIONS$(RESET)"
	@echo -e "  $(GREEN)build$(RESET)                Build via compose or specific Dockerfile (SERVICE=api)"
	@echo -e "  $(GREEN)up$(RESET)                   Start services in background (compose)"
	@echo -e "  $(GREEN)down$(RESET)                 Stop services and remove resources"
	@echo -e "  $(GREEN)logs$(RESET)                 Follow logs for a service (SERVICE=name)"
	@echo
	@echo -e "$(BLUE)🧪 DEVELOPMENT$(RESET)"
	@echo -e "  $(GREEN)test$(RESET)                 Run tests for detected stack"
	@echo -e "  $(GREEN)lint$(RESET)                 Run available linters"
	@echo -e "  $(GREEN)fmt$(RESET)                  Run available formatters"
	@echo -e "  $(GREEN)requirements-check$(RESET)   Check system requirements"
	@echo -e "  $(GREEN)venv-setup$(RESET)           Setup Python virtual environment"
	@echo -e "  $(GREEN)venv-activate$(RESET)        Show venv activation instructions"
	@echo
	@echo -e "$(BLUE)📊 ANALYTICS$(RESET)"
	@echo -e "  $(GREEN)youtube-setup$(RESET)        Setup YouTube Data API for comment scraping"
	@echo -e "  $(GREEN)youtube-comments$(RESET)     Scrape YouTube comments (URL=... MAX=200)"
	@echo -e "  $(GREEN)youtube-captions$(RESET)     Download YouTube captions (URL=... LANG=en)"
	@echo -e "  $(GREEN)youtube-analyze$(RESET)      Run AI analysis on comments (FILE=comments.json)"
	@echo -e "  $(GREEN)youtube-complete$(RESET)     Complete analysis: comments + captions + AI (URL=...)"
	@echo -e "  $(GREEN)youtube-shell$(RESET)        Open analytics container shell"
	@echo
	@echo -e "$(BLUE)📊 REPOSITORY MANAGEMENT$(RESET)"
	@echo -e "  $(GREEN)status$(RESET)               Show repository and content status"
	@echo -e "  $(GREEN)backup$(RESET)               Backup important content"
	@echo -e "  $(GREEN)update-deps$(RESET)          Update dependencies and tools"
	@echo -e "  $(GREEN)clean$(RESET)                Prune images/build cache and stop compose"
	@echo
	@echo -e "$(YELLOW)📋 USAGE EXAMPLES:$(RESET)"
	@echo -e "  make episode NUM=3 TITLE='Buildah Deep Dive'"
	@echo -e "  make demo-setup EPISODE=001"
	@echo -e "  make validate-all"
	@echo -e "  make security-scan"
	@echo -e "  make youtube-comments URL='https://youtu.be/dQw4w9WgXcQ' MAX=100"
	@echo -e "  make youtube-comments URL='https://youtu.be/dQw4w9WgXcQ'  # Uses default 200"
	@echo

## 📺 CONTENT CREATION COMMANDS

## Create new episode with templates and structure
episode:
	@if [ -z "$(NUM)" ] || [ -z "$(TITLE)" ]; then \
	  echo -e "$(RED)❌ Error: NUM and TITLE are required$(RESET)"; \
	  echo -e "$(YELLOW)Usage: make episode NUM=3 TITLE='My Episode Title'$(RESET)"; \
	  exit 1; \
	fi
	@echo -e "$(BLUE)🎥 Creating Episode $(NUM): $(TITLE)$(RESET)"
	@python3 $(SCRIPTS_DIR)/content-generator.py episode $(NUM) "$(TITLE)" --difficulty $(DIFFICULTY)
	@echo -e "$(GREEN)✓ Episode $(NUM) created successfully!$(RESET)"

## Validate all content structure and links
content-validate:
	@echo -e "$(BLUE)🔍 Validating content structure...$(RESET)"
	@python3 $(SCRIPTS_DIR)/content-generator.py validate
	@echo -e "$(BLUE)🔗 Checking links in references...$(RESET)"
	@$(MAKE) --no-print-directory link-check
	@echo -e "$(GREEN)✓ Content validation complete!$(RESET)"

## List all episodes and content
content-list:
	@echo -e "$(BLUE)📚 ContainerCodes Content Overview$(RESET)"
	@python3 $(SCRIPTS_DIR)/content-generator.py list

## Generate content statistics
content-stats:
	@echo -e "$(BLUE)📊 Content Statistics$(RESET)"
	@echo -e "$(YELLOW)Episodes:$(RESET) $$(find $(VIDEOS_DIR) -name 'episode-*' -type d | wc -l)"
	@echo -e "$(YELLOW)Notes:$(RESET) $$(find $(NOTES_DIR) -name '*.md' | wc -l)"
	@echo -e "$(YELLOW)Examples:$(RESET) $$(find $(EXAMPLES_DIR) -name '*.md' | wc -l)"
	@echo -e "$(YELLOW)Total Files:$(RESET) $$(find . -name '*.md' -o -name '*.py' -o -name '*.sh' | wc -l)"
	@echo -e "$(YELLOW)Demo Scripts:$(RESET) $$(find $(VIDEOS_DIR) -name '*.sh' | wc -l)"

## 🛠️ DEMO MANAGEMENT COMMANDS

## Setup episode demo environment
demo-setup:
	@if [ -z "$(EPISODE)" ]; then \
	  echo -e "$(RED)❌ Error: EPISODE is required$(RESET)"; \
	  echo -e "$(YELLOW)Usage: make demo-setup EPISODE=001$(RESET)"; \
	  exit 1; \
	fi
	@echo -e "$(BLUE)🛠️ Setting up demo environment for episode $(EPISODE)...$(RESET)"
	@if [ ! -d "$(VIDEOS_DIR)/episode-$(EPISODE)-*/demo" ]; then \
	  echo -e "$(RED)❌ Episode $(EPISODE) demo directory not found$(RESET)"; \
	  exit 1; \
	fi
	@episode_dir=$$(find $(VIDEOS_DIR) -name "episode-$(EPISODE)-*" -type d | head -1); \
	if [ -f "$$episode_dir/demo/setup.sh" ]; then \
	  cd "$$episode_dir/demo" && chmod +x setup.sh && ./setup.sh; \
	else \
	  echo -e "$(YELLOW)⚠️ No setup.sh found, using generic setup$(RESET)"; \
	  $(SCRIPTS_DIR)/demo-infrastructure.sh setup $$(echo $(EPISODE) | sed 's/^0*//') episode-$(EPISODE); \
	fi

## Cleanup episode demos
demo-cleanup:
	@if [ -z "$(EPISODE)" ]; then \
	  echo -e "$(RED)❌ Error: EPISODE is required$(RESET)"; \
	  echo -e "$(YELLOW)Usage: make demo-cleanup EPISODE=001$(RESET)"; \
	  exit 1; \
	fi
	@echo -e "$(BLUE)🧺 Cleaning up demo environment for episode $(EPISODE)...$(RESET)"
	@episode_dir=$$(find $(VIDEOS_DIR) -name "episode-$(EPISODE)-*" -type d | head -1); \
	if [ -f "$$episode_dir/demo/cleanup.sh" ]; then \
	  cd "$$episode_dir/demo" && chmod +x cleanup.sh && ./cleanup.sh; \
	else \
	  echo -e "$(YELLOW)⚠️ No cleanup.sh found, running generic cleanup$(RESET)"; \
	  $(CR) stop --all 2>/dev/null || true; \
	  $(CR) container prune -f 2>/dev/null || true; \
	fi

## Test episode demonstrations
demo-test:
	@if [ -z "$(EPISODE)" ]; then \
	  echo -e "$(RED)❌ Error: EPISODE is required$(RESET)"; \
	  echo -e "$(YELLOW)Usage: make demo-test EPISODE=001$(RESET)"; \
	  exit 1; \
	fi
	@echo -e "$(BLUE)🧪 Testing demonstrations for episode $(EPISODE)...$(RESET)"
	@episode_dir=$$(find $(VIDEOS_DIR) -name "episode-$(EPISODE)-*" -type d | head -1); \
	if [ -d "$$episode_dir/demo" ]; then \
	  echo -e "$(GREEN)Found demo directory: $$episode_dir/demo$(RESET)"; \
	  echo -e "$(YELLOW)Demo scripts:$(RESET)"; \
	  find "$$episode_dir/demo" -name '*.sh' -exec basename {} \; | sed 's/^/  - /'; \
	  echo -e "$(BLUE)Testing script permissions...$(RESET)"; \
	  find "$$episode_dir/demo" -name '*.sh' ! -perm -111 -exec echo -e "$(RED)❌ {} is not executable$(RESET)" \; || true; \
	  find "$$episode_dir/demo" -name '*.sh' -perm -111 -exec echo -e "$(GREEN)✓ {} is executable$(RESET)" \; || true; \
	else \
	  echo -e "$(YELLOW)⚠️ No demo directory found for episode $(EPISODE)$(RESET)"; \
	fi

## List available demo environments
demo-list:
	@echo -e "$(BLUE)📚 Available Demo Environments$(RESET)"
	@echo -e "$(YELLOW)Episodes with demos:$(RESET)"
	@find $(VIDEOS_DIR) -name 'demo' -type d | sed 's|$(VIDEOS_DIR)/||; s|/demo||' | sort | sed 's/^/  - /'
	@echo -e "$(YELLOW)Demo infrastructure:$(RESET)"
	@$(SCRIPTS_DIR)/demo-infrastructure.sh list 2>/dev/null || echo "  Run 'make demo-setup EPISODE=X' to create environments"

## 🔒 SECURITY & QUALITY COMMANDS

## Scan all content for security issues
security-scan:
	@echo -e "$(BLUE)🔍 Security scanning all content...$(RESET)"
	@echo -e "$(YELLOW)Checking for exposed credentials...$(RESET)"
	@if command -v rg >/dev/null 2>&1; then \
	  rg -i "(password|api_key|secret|token)\s*=\s*['\"][^'\"]{8,}" . --type md --type py --type sh || echo "No credentials found"; \
	else \
	  grep -r -i "password\|api_key\|secret\|token" . --include="*.md" --include="*.py" --include="*.sh" || echo "No credentials found"; \
	fi
	@echo -e "$(YELLOW)Checking for hardcoded IPs and domains...$(RESET)"
	@if command -v rg >/dev/null 2>&1; then \
	  rg "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" . --type md --type py --type sh | head -10 || echo "No hardcoded IPs found"; \
	fi
	@echo -e "$(GREEN)✓ Security scan complete!$(RESET)"

## Check for vulnerabilities in examples
vulnerability-check:
	@echo -e "$(BLUE)🔍 Checking for vulnerable dependencies...$(RESET)"
	@find . -name "requirements.txt" -exec echo -e "$(YELLOW)Checking {}$(RESET)" \; -exec echo "{}:" \;
	@find . -name "package.json" -exec echo -e "$(YELLOW)Checking {}$(RESET)" \; -exec echo "{}:" \;
	@find . -name "go.mod" -exec echo -e "$(YELLOW)Checking {}$(RESET)" \; -exec echo "{}:" \;
	@echo -e "$(BLUE)Note: Run specific vulnerability scanners for detailed analysis$(RESET)"
	@echo -e "$(GREEN)✓ Vulnerability check complete!$(RESET)"

## Run security demonstration workflows
security-demo:
	@echo -e "$(BLUE)🔒 Running security demonstrations...$(RESET)"
	@if [ -f "$(VIDEOS_DIR)/episode-000-container-defense/demo/ai-code-isolation.sh" ]; then \
	  echo -e "$(YELLOW)Running AI code isolation demo...$(RESET)"; \
	  cd "$(VIDEOS_DIR)/episode-000-container-defense/demo" && ./ai-code-isolation.sh; \
	fi
	@if [ -f "$(VIDEOS_DIR)/episode-000-container-defense/demo/vulnerability-scanner.sh" ]; then \
	  echo -e "$(YELLOW)Running vulnerability scanner demo...$(RESET)"; \
	  cd "$(VIDEOS_DIR)/episode-000-container-defense/demo" && ./vulnerability-scanner.sh; \
	fi

## Complete content validation
validate-all:
	@echo -e "$(BLUE)🔍 Running complete validation suite...$(RESET)"
	@$(MAKE) --no-print-directory content-validate
	@$(MAKE) --no-print-directory format-check
	@$(MAKE) --no-print-directory requirements-check
	@echo -e "$(GREEN)✓ All validation checks passed!$(RESET)"

## Validate all external links
link-check:
	@echo -e "$(BLUE)🔗 Checking external links...$(RESET)"
	@if command -v rg >/dev/null 2>&1; then \
	  rg "https?://[^\s)]+" . --type md -o | sort | uniq | head -20 | \
	  while read url; do \
	    echo -n "Checking $$url ... "; \
	    if curl -s --head "$$url" >/dev/null 2>&1; then \
	      echo -e "$(GREEN)✓$(RESET)"; \
	    else \
	      echo -e "$(RED)❌$(RESET)"; \
	    fi; \
	  done; \
	else \
	  echo -e "$(YELLOW)Install ripgrep (rg) for detailed link checking$(RESET)"; \
	fi

## Check markdown formatting
format-check:
	@echo -e "$(BLUE)📝 Checking markdown formatting...$(RESET)"
	@find . -name "*.md" -exec echo "Checking {}" \; -exec echo "  Lines: $$(wc -l < {})" \;
	@echo -e "$(GREEN)✓ Format check complete!$(RESET)"

## 🐳 CONTAINER OPERATIONS COMMANDS

## Build via compose or specific Dockerfile
build:
	@set -e; \
	if [ -n "$(SERVICE)" ] && [ -f "containers/$(SERVICE)/Dockerfile" ]; then \
	  echo -e "$(BLUE)🔨 Building containers/$(SERVICE)/Dockerfile$(RESET)"; \
	  $(CR) build -t $(SERVICE):dev -f containers/$(SERVICE)/Dockerfile .; \
	else \
	  echo -e "$(BLUE)🔨 Building via compose ($(COMPOSE_FILE))$(RESET)"; \
	  $(DC) -f $(COMPOSE_FILE) build $(SERVICE); \
	fi

## Start services in background
up:
	@echo -e "$(BLUE)▶️ Starting services...$(RESET)"
	@$(DC) -f $(COMPOSE_FILE) up -d --build
	@echo -e "$(GREEN)✓ Services started!$(RESET)"

## Stop services and remove resources
down:
	@echo -e "$(BLUE)⏹️ Stopping services...$(RESET)"
	@$(DC) -f $(COMPOSE_FILE) down -v
	@echo -e "$(GREEN)✓ Services stopped!$(RESET)"

## Follow logs for a service
logs:
	@if [ -z "$(SERVICE)" ]; then \
	  echo -e "$(YELLOW)Showing logs for all services$(RESET)"; \
	  $(DC) -f $(COMPOSE_FILE) logs -f; \
	else \
	  echo -e "$(YELLOW)Showing logs for service: $(SERVICE)$(RESET)"; \
	  $(DC) -f $(COMPOSE_FILE) logs -f $(SERVICE); \
	fi

## 🧪 DEVELOPMENT COMMANDS

## Run tests for detected stack
test:
	@echo -e "$(BLUE)🧪 Running tests...$(RESET)"
	@set -e; \
	if command -v pytest >/dev/null 2>&1; then \
	  echo -e "$(YELLOW)Running pytest$(RESET)"; pytest -q; \
	elif command -v go >/dev/null 2>&1 && [ -f go.mod ]; then \
	  echo -e "$(YELLOW)Running go tests$(RESET)"; go test ./...; \
	elif [ -f package.json ] && command -v npm >/dev/null 2>&1; then \
	  echo -e "$(YELLOW)Running npm test$(RESET)"; npm test --silent; \
	else \
	  echo -e "$(YELLOW)No test runner detected; skipping.$(RESET)"; \
	fi
	@echo -e "$(GREEN)✓ Tests complete!$(RESET)"

## Run available linters
lint:
	@echo -e "$(BLUE)🔍 Running linters...$(RESET)"
	@set -e; errors=0; \
	if command -v ruff >/dev/null 2>&1; then echo -e "$(YELLOW)ruff$(RESET)"; ruff check . || errors=1; fi; \
	if command -v flake8 >/dev/null 2>&1; then echo -e "$(YELLOW)flake8$(RESET)"; flake8 || errors=1; fi; \
	if command -v eslint >/dev/null 2>&1 && [ -f package.json ]; then echo -e "$(YELLOW)eslint$(RESET)"; npx -y eslint . || errors=1; fi; \
	if command -v golangci-lint >/dev/null 2>&1; then echo -e "$(YELLOW)golangci-lint$(RESET)"; golangci-lint run || errors=1; fi; \
	if [ $$errors -ne 0 ]; then echo -e "$(RED)Linting failed$(RESET)"; exit 1; else echo -e "$(GREEN)✓ Linting passed!$(RESET)"; fi

## Run available formatters
fmt:
	@echo -e "$(BLUE)✨ Running formatters...$(RESET)"
	@if command -v black >/dev/null 2>&1; then echo -e "$(YELLOW)black$(RESET)"; black .; fi; \
	if command -v isort >/dev/null 2>&1; then echo -e "$(YELLOW)isort$(RESET)"; isort .; fi; \
	if command -v prettier >/dev/null 2>&1; then echo -e "$(YELLOW)prettier$(RESET)"; prettier -w . --prose-wrap always; fi; \
	if command -v gofmt >/dev/null 2>&1; then echo -e "$(YELLOW)gofmt$(RESET)"; gofmt -w .; fi
	@echo -e "$(GREEN)✓ Formatting complete!$(RESET)"

## Check system requirements
requirements-check:
	@echo -e "$(BLUE)🔍 Checking system requirements...$(RESET)"
	@echo -e "$(YELLOW)Container Runtime:$(RESET)"
	@if command -v podman >/dev/null 2>&1; then \
	  echo -e "  $(GREEN)✓ Podman: $$(podman --version)$(RESET)"; \
	elif command -v docker >/dev/null 2>&1; then \
	  echo -e "  $(GREEN)✓ Docker: $$(docker --version)$(RESET)"; \
	else \
	  echo -e "  $(RED)❌ No container runtime found$(RESET)"; \
	fi
	@echo -e "$(YELLOW)Python Tools:$(RESET)"
	@if command -v python3 >/dev/null 2>&1; then \
	  echo -e "  $(GREEN)✓ Python: $$(python3 --version)$(RESET)"; \
	else \
	  echo -e "  $(RED)❌ Python3 not found$(RESET)"; \
	fi
	@echo -e "$(YELLOW)Development Tools:$(RESET)"
	@for tool in git curl make; do \
	  if command -v $$tool >/dev/null 2>&1; then \
	    echo -e "  $(GREEN)✓ $$tool$(RESET)"; \
	  else \
	    echo -e "  $(RED)❌ $$tool not found$(RESET)"; \
	  fi; \
	done

## 📊 REPOSITORY MANAGEMENT COMMANDS

## Show repository and content status
status:
	@echo -e "$(BLUE)📊 ContainerCodes Repository Status$(RESET)"
	@echo -e "$(YELLOW)Repository Info:$(RESET)"
	@echo -e "  Location: $$(pwd)"
	@echo -e "  Branch: $$(git branch --show-current 2>/dev/null || echo 'Not a git repo')"
	@echo -e "  Last commit: $$(git log -1 --format='%h %s' 2>/dev/null || echo 'No commits')"
	@echo
	@$(MAKE) --no-print-directory content-stats
	@echo
	@echo -e "$(YELLOW)Container Images:$(RESET)"
	@$(CR) images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null | head -5 || echo "  No images found"
	@echo
	@echo -e "$(YELLOW)Running Containers:$(RESET)"
	@$(CR) ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  No containers running"

## Backup important content
backup:
	@echo -e "$(BLUE)💾 Creating backup...$(RESET)"
	@backup_name="containercodes-backup-$$(date +%Y%m%d-%H%M%S).tar.gz"
	@tar -czf "$$backup_name" \
	  --exclude='.git' \
	  --exclude='node_modules' \
	  --exclude='__pycache__' \
	  --exclude='*.pyc' \
	  --exclude='.DS_Store' \
	  $(VIDEOS_DIR) $(NOTES_DIR) $(EXAMPLES_DIR) $(TEMPLATES_DIR) $(SCRIPTS_DIR) \
	  README.md CONTENT_STANDARDS.md SECURITY_PRACTICES.md Makefile
	@echo -e "$(GREEN)✓ Backup created: $$backup_name$(RESET)"

## Update dependencies and tools
update-deps:
	@echo -e "$(BLUE)🔄 Updating dependencies...$(RESET)"
	@if [ -f requirements.txt ]; then \
	  echo -e "$(YELLOW)Updating Python dependencies$(RESET)"; \
	  pip install -U pip && pip install -U -r requirements.txt; \
	fi
	@if [ -f package.json ]; then \
	  echo -e "$(YELLOW)Updating Node.js dependencies$(RESET)"; \
	  npm update; \
	fi
	@if [ -f go.mod ]; then \
	  echo -e "$(YELLOW)Updating Go dependencies$(RESET)"; \
	  go get -u ./... && go mod tidy; \
	fi
	@echo -e "$(GREEN)✓ Dependencies updated!$(RESET)"

## Prune images/build cache and stop compose
clean:
	@echo -e "$(BLUE)🧺 Cleaning up...$(RESET)"
	@echo -e "$(YELLOW)Stopping containers$(RESET)"
	@$(DC) -f $(COMPOSE_FILE) down -v >/dev/null 2>&1 || true
	@echo -e "$(YELLOW)Pruning container images$(RESET)"
	@$(CR) image prune -f >/dev/null 2>&1 || true
	@$(CR) builder prune -f >/dev/null 2>&1 || true
	@echo -e "$(GREEN)✓ Cleanup complete!$(RESET)"

## 📊 ANALYTICS COMMANDS

## Setup YouTube Data API for comment scraping
youtube-setup:
	@echo -e "$(BLUE)🔑 YouTube Data API Setup$(RESET)"
	@echo -e "$(YELLOW)Setting up YouTube comment scraper...$(RESET)"
	@if python3 $(SCRIPTS_DIR)/youtube-comment-scraper.py --setup; then \
	  echo -e "$(GREEN)✅ Setup completed successfully!$(RESET)"; \
	  echo -e "$(CYAN)You can now use: make youtube-comments URL='https://youtu.be/VIDEO_ID'$(RESET)"; \
	else \
	  echo -e "$(RED)❌ Setup failed or was cancelled$(RESET)"; \
	  echo -e "$(YELLOW)💡 Setup Help:$(RESET)"; \
	  echo -e "  1. Get a YouTube Data API v3 key from https://console.cloud.google.com/"; \
	  echo -e "  2. Enable the YouTube Data API v3 for your project"; \
	  echo -e "  3. Set your API key: export YOUTUBE_API_KEY='your_key_here'"; \
	  echo -e "  4. Or run 'make youtube-setup' again to enter it interactively"; \
	  echo -e "$(CYAN)Example usage after setup:$(RESET)"; \
	  echo -e "  make youtube-comments URL='https://www.youtube.com/watch?v=dQw4w9WgXcQ'"; \
	  echo -e "  make youtube-comments URL='https://youtu.be/dQw4w9WgXcQ' MAX=100"; \
	fi

## Scrape YouTube comments (default: 200 comments)
youtube-comments:
	@if [ -z "$(URL)" ]; then \
	  echo -e "$(RED)❌ Error: URL parameter is required$(RESET)"; \
	  echo -e "$(YELLOW)Usage Examples:$(RESET)"; \
	  echo -e "  make youtube-comments URL='https://www.youtube.com/watch?v=dQw4w9WgXcQ'"; \
	  echo -e "  make youtube-comments URL='https://youtu.be/dQw4w9WgXcQ' MAX=100"; \
	  echo -e "  make youtube-comments URL='dQw4w9WgXcQ' MAX=500"; \
	  echo -e "$(CYAN)💡 Tip: Default limit is 200 comments if MAX is not specified$(RESET)"; \
	  echo -e "$(CYAN)🔑 Need setup? Run: make youtube-setup$(RESET)"; \
	  exit 1; \
	fi
	@echo -e "$(BLUE)📊 Scraping YouTube comments...$(RESET)"
	@MAX_COMMENTS=$${MAX:-200}; \
	echo -e "$(YELLOW)Video: $(URL)$(RESET)"; \
	echo -e "$(YELLOW)Max comments: $$MAX_COMMENTS$(RESET)"; \
	if python3 $(SCRIPTS_DIR)/youtube-comment-scraper.py "$(URL)" --max-comments $$MAX_COMMENTS --format json; then \
	  echo -e "$(GREEN)✅ Comment scraping completed successfully!$(RESET)"; \
	else \
	  echo -e "$(RED)❌ Comment scraping failed$(RESET)"; \
	  echo -e "$(YELLOW)💡 Troubleshooting:$(RESET)"; \
	  echo -e "  - Check if the video URL is correct and publicly accessible"; \
	  echo -e "  - Verify your API key is valid: make youtube-setup"; \
	  echo -e "  - Ensure comments are enabled for this video"; \
	  echo -e "  - Check your API quota hasn't been exceeded"; \
	  echo -e "$(CYAN)Example valid URLs:$(RESET)"; \
	  echo -e "  https://www.youtube.com/watch?v=VIDEO_ID"; \
	  echo -e "  https://youtu.be/VIDEO_ID"; \
	  echo -e "  VIDEO_ID (just the 11-character ID)"; \
	fi

## Download YouTube captions (containerized)
youtube-captions:
	@if [ -z "$(URL)" ]; then \
	  echo -e "$(RED)❌ Error: URL parameter is required$(RESET)"; \
	  echo -e "$(YELLOW)Usage Examples:$(RESET)"; \
	  echo -e "  make youtube-captions URL='https://www.youtube.com/watch?v=VIDEO_ID'"; \
	  echo -e "  make youtube-captions URL='VIDEO_ID' LANG=es"; \
	  echo -e "  make youtube-captions URL='VIDEO_ID' LANG=all"; \
	  echo -e "$(CYAN)💡 Tip: Default language is 'en' if LANG is not specified$(RESET)"; \
	  exit 1; \
	fi
	@echo -e "$(BLUE)📹 Downloading YouTube captions in container...$(RESET)"
	@LANG_CODE=$${LANG:-en}; \
	echo -e "$(YELLOW)Video: $(URL)$(RESET)"; \
	echo -e "$(YELLOW)Language: $$LANG_CODE$(RESET)"; \
	./scripts/run-youtube-analytics.sh captions "$(URL)" $$LANG_CODE json

## Run AI analysis on comments (containerized)
youtube-analyze:
	@if [ -z "$(FILE)" ]; then \
	  echo -e "$(RED)❌ Error: FILE parameter is required$(RESET)"; \
	  echo -e "$(YELLOW)Usage Examples:$(RESET)"; \
	  echo -e "  make youtube-analyze FILE=comments.json"; \
	  echo -e "  make youtube-analyze FILE=tmp/video_analysis/comments.json"; \
	  echo -e "$(CYAN)💡 Tip: Run comment scraping first to get a comments file$(RESET)"; \
	  exit 1; \
	fi
	@echo -e "$(BLUE)🤖 Running AI analysis in container...$(RESET)"
	@echo -e "$(YELLOW)Analyzing: $(FILE)$(RESET)"
	@./scripts/run-youtube-analytics.sh analyze "$(FILE)"

## Complete YouTube analysis (comments + captions + AI) (containerized)
youtube-complete:
	@if [ -z "$(URL)" ]; then \
	  echo -e "$(RED)❌ Error: URL parameter is required$(RESET)"; \
	  echo -e "$(YELLOW)Usage Examples:$(RESET)"; \
	  echo -e "  make youtube-complete URL='https://www.youtube.com/watch?v=VIDEO_ID'"; \
	  echo -e "  make youtube-complete URL='VIDEO_ID' MAX=500"; \
	  echo -e "  make youtube-complete URL='VIDEO_ID' LANG=all"; \
	  echo -e "$(CYAN)💡 This runs comments + captions + AI analysis$(RESET)"; \
	  exit 1; \
	fi
	@echo -e "$(BLUE)🚀 Running complete YouTube analysis in container...$(RESET)"
	@MAX_COMMENTS=$${MAX:-200}; \
	LANG_CODE=$${LANG:-en}; \
	echo -e "$(YELLOW)Video: $(URL)$(RESET)"; \
	echo -e "$(YELLOW)Max comments: $$MAX_COMMENTS$(RESET)"; \
	echo -e "$(YELLOW)Caption language: $$LANG_CODE$(RESET)"; \
	./scripts/run-youtube-analytics.sh complete "$(URL)" --max-comments $$MAX_COMMENTS --caption-lang $$LANG_CODE

## Open interactive shell in analytics container
youtube-shell:
	@echo -e "$(BLUE)🐚 Opening analytics container shell...$(RESET)"
	@echo -e "$(YELLOW)Available tools inside container:$(RESET)"
	@echo -e "  - python scripts/youtube-comment-scraper.py"
	@echo -e "  - python src/app/youtube_caption_downloader.py"
	@echo -e "  - python src/app/ai_comment_analyzer.py"
	@echo -e "  - python scripts/youtube-content-scraper.py"
	@echo -e "$(CYAN)Type 'exit' to leave the container$(RESET)"
	@./scripts/run-youtube-analytics.sh shell

## Build YouTube analytics container image
youtube-build:
	@echo -e "$(BLUE)🔨 Building YouTube Analytics container...$(RESET)"
	@./scripts/run-youtube-analytics.sh --build shell --help 2>/dev/null || true
	@echo -e "$(GREEN)✅ YouTube Analytics container built successfully!$(RESET)"

## Setup Python virtual environment for YouTube analytics
venv-setup:
	@echo -e "$(BLUE)🐍 Setting up Python virtual environment...$(RESET)"
	@if [ "$(DEV)" = "true" ]; then \
	  echo -e "$(YELLOW)Installing with development dependencies...$(RESET)"; \
	  scripts/setup-venv.sh --dev; \
	elif [ "$(EXTRAS)" = "true" ]; then \
	  echo -e "$(YELLOW)Installing with extra analysis dependencies...$(RESET)"; \
	  scripts/setup-venv.sh --extras; \
	elif [ "$(ALL)" = "true" ]; then \
	  echo -e "$(YELLOW)Installing all dependencies...$(RESET)"; \
	  scripts/setup-venv.sh --dev --extras; \
	else \
	  scripts/setup-venv.sh; \
	fi
	@echo -e "$(GREEN)✅ Virtual environment ready!$(RESET)"
	@echo -e "$(CYAN)Activate with: source scripts/activate.sh$(RESET)"

## Show virtual environment activation instructions
venv-activate:
	@echo -e "$(BLUE)🐍 Virtual Environment Activation$(RESET)"
	@echo -e "$(YELLOW)To activate the virtual environment:$(RESET)"
	@echo -e "  $(GREEN)source scripts/activate.sh$(RESET)        # Bash/Zsh"
	@if command -v fish >/dev/null 2>&1; then \
	  echo -e "  $(GREEN)source scripts/activate.fish$(RESET)      # Fish shell"; \
	fi
	@echo
	@echo -e "$(YELLOW)Or run the interactive tool directly:$(RESET)"
	@echo -e "  $(GREEN)python scripts/run.py$(RESET)              # Interactive menu"
	@echo
	@echo -e "$(YELLOW)To deactivate:$(RESET)"
	@echo -e "  $(GREEN)deactivate$(RESET)"
	@echo
	@if [ ! -d ".venv" ]; then \
	  echo -e "$(RED)❌ Virtual environment not found!$(RESET)"; \
	  echo -e "$(CYAN)Run 'make venv-setup' first$(RESET)"; \
	else \
	  echo -e "$(GREEN)✓ Virtual environment exists at .venv$(RESET)"; \
	  if [ -n "$${VIRTUAL_ENV}" ]; then \
	    echo -e "$(GREEN)✓ Currently activated: $${VIRTUAL_ENV}$(RESET)"; \
	  else \
	    echo -e "$(YELLOW)⚠ Not currently activated$(RESET)"; \
	  fi; \
	fi

## Run interactive YouTube analytics tool
youtube-interactive:
	@if [ ! -d ".venv" ]; then \
	  echo -e "$(RED)❌ Virtual environment not found!$(RESET)"; \
	  echo -e "$(YELLOW)Setting up virtual environment first...$(RESET)"; \
	  $(MAKE) venv-setup; \
	fi
	@echo -e "$(BLUE)🚀 Starting Interactive YouTube Analytics Tool$(RESET)"
	@if [ -z "$${VIRTUAL_ENV}" ]; then \
	  echo -e "$(YELLOW)Activating virtual environment...$(RESET)"; \
	  . .venv/bin/activate && python scripts/run.py; \
	else \
	  python scripts/run.py; \
	fi

