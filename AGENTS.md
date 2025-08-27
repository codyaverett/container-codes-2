# Repository Guidelines

## Project Structure & Module Organization

- `src/`: Application code for each service/module.
- `tests/`: Automated tests mirroring `src/` layout.
- `containers/`: Dockerfiles and container-specific assets per service (e.g.,
  `containers/api/Dockerfile`).
- `scripts/`: Dev/CI helper scripts (bash/py). Keep them idempotent.
- `assets/`: Static files (sample data, diagrams).
- `compose.yml`: Local multi-service orchestration (if applicable).

Example:

```
containers/
  api/Dockerfile
src/
  api/
    __init__.py
    main.py
tests/
  api/test_main.py
scripts/
  dev-up.sh
```

## Build, Test, and Development Commands

- Build image: `docker build -t <name> -f containers/<svc>/Dockerfile .`
- Run locally: `docker compose up --build` (uses `compose.yml` if present).
- Unit tests: `make test` or run language-native runner (e.g., `pytest`,
  `npm test`, `go test ./...`).
- Lint/format: `make lint` / `make fmt` when available.

## Coding Style & Naming Conventions

- Indentation: 2 spaces (JS/TS), 4 spaces (Python); use tabs for Go.
- Python: `black`, `isort`, `flake8` (or `ruff`).
- JS/TS: `eslint` + `prettier` with project config.
- Go: `gofmt`, `go vet`, `golangci-lint`.
- Names: kebab-case for files, snake_case for Python, camelCase for
  vars/functions in JS/TS, PascalCase for types/classes.

## Testing Guidelines

- Place tests under `tests/` with mirrored paths.
- Naming: `test_*.py` (Py), `*.test.ts`/`*.spec.ts` (JS/TS), `*_test.go` (Go).
- Aim for ≥80% line coverage on changed code.
- Run tests in containers where possible to match prod parity.

## Commit & Pull Request Guidelines

- Commits: follow Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`,
  `refactor:`). Keep scope small; include rationale.
- PRs: clear description, linked issues, testing notes, and screenshots/logs
  when relevant. One feature/fix per PR. Passing CI required.

## Security & Configuration

- Never commit secrets. Use `ENV` vars and provide `.env.example` with safe
  defaults.
- Pin base images and dependencies; update regularly.
- Add minimal, non-root containers; expose only required ports.
