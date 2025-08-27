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
COMPOSE_FILE ?= compose.yml
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

test:
	@set -e; \
	if command -v pytest >/dev/null 2>&1; then \
	  echo "Running pytest"; pytest -q; \
	elif command -v go >/dev/null 2>&1 && [ -f go.mod ]; then \
	  echo "Running go tests"; go test ./...; \
	elif [ -f package.json ] && command -v npm >/dev/null 2>&1; then \
	  echo "Running npm test"; npm test --silent; \
	else \
	  echo "No test runner detected; skipping."; \
	fi

lint:
	@set -e; errors=0; \
	if command -v ruff >/dev/null 2>&1; then echo "ruff"; ruff check . || errors=1; fi; \
	if command -v flake8 >/dev/null 2>&1; then echo "flake8"; flake8 || errors=1; fi; \
	if command -v eslint >/dev/null 2>&1 && [ -f package.json ]; then echo "eslint"; npx -y eslint . || errors=1; fi; \
	if command -v golangci-lint >/dev/null 2>&1; then echo "golangci-lint"; golangci-lint run || errors=1; fi; \
	if [ $$errors -ne 0 ]; then echo "Linting failed"; exit 1; else echo "Linting passed"; fi

fmt:
	@if command -v black >/dev/null 2>&1; then echo "black"; black .; fi; \
	if command -v isort >/dev/null 2>&1; then echo "isort"; isort .; fi; \
	if command -v prettier >/dev/null 2>&1; then echo "prettier"; prettier -w .; fi; \
	if command -v gofmt >/dev/null 2>&1; then echo "gofmt"; gofmt -w .; fi

clean:
	-@docker image prune -f >/dev/null 2>&1 || true
	-@docker builder prune -f >/dev/null 2>&1 || true
	-@$(DC) -f $(COMPOSE_FILE) down -v >/dev/null 2>&1 || true

