SHELL := /bin/bash

# Select docker compose command
DC := $(shell command -v docker >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

# Variables
SERVICE ?=
COMPOSE_FILE ?= compose.yml

.PHONY: help build up down logs test lint fmt clean

help:
	@echo "Targets:"
	@echo "  build       Build via compose or a specific Dockerfile (SERVICE=api)"
	@echo "  up          Start services in background (compose)"
	@echo "  down        Stop services and remove resources"
	@echo "  logs        Follow logs for a service (SERVICE=name)"
	@echo "  test        Run tests for detected stack (pytest/go/npm)"
	@echo "  lint        Run available linters (ruff/flake8/eslint/golangci-lint)"
	@echo "  fmt         Run available formatters (black/isort/prettier/gofmt)"
	@echo "  clean       Prune images/build cache and stop compose"

build:
	@set -e; \
	if [ -n "$(SERVICE)" ] && [ -f "containers/$(SERVICE)/Dockerfile" ]; then \
	  echo "Building containers/$(SERVICE)/Dockerfile"; \
	  docker build -t $(SERVICE):dev -f containers/$(SERVICE)/Dockerfile .; \
	else \
	  echo "Building via compose ($(COMPOSE_FILE))"; \
	  $(DC) -f $(COMPOSE_FILE) build $(SERVICE); \
	fi

up:
	$(DC) -f $(COMPOSE_FILE) up -d --build

down:
	-$(DC) -f $(COMPOSE_FILE) down -v

logs:
	$(DC) -f $(COMPOSE_FILE) logs -f $(SERVICE)

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

