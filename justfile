# justfile for python-tool CLI application

# Load environment variables from .env file if it exists
set dotenv-load := true

SERVICE_NAME := env_var("SERVICE_NAME")
ARGS_TEST := env("_UV_RUN_ARGS_TEST", "")
ARGS_RUN := env("_UV_RUN_ARGS_CLI", "")

# Show available commands
@_:
    @just --list --unsorted

# Run tests
[group('qa')]
test *args:
    uv run {{ ARGS_TEST }} -m pytest {{ args }}

_cov *args:
    uv run -m coverage {{ args }}

# Run tests and measure coverage
[group('qa')]
@cov *args:
    just _cov erase
    just _cov run -m pytest tests
    just _cov report
    just _cov html

# Run linters
[group('qa')]
lint:
    uv run ruff check
    uv run ruff format

# Check types
[group('qa')]
typing:
    uv run ty check src .venv

# Perform all checks
[group('qa')]
check-all: lint cov typing

# Setup development environment (start database)
[group('run')]
dev:
    #!/usr/bin/env bash
    # Start Docker Compose services if compose.yml exists
    if [ -f compose.yml ]; then
        echo "Starting Docker Compose services..."
        docker compose -f compose.yml up --remove-orphans -d
        echo "Waiting for services to be ready..."
        sleep 3
    fi
    echo "Database services started. You can now run CLI commands."
    echo "Examples:"
    echo "  just run status --save-db"
    echo "  just run echo 'hello world' --reverse"
    echo "  just run health"

# Run CLI tool commands
[group('run')]
run *args:
    PYTHON_ENV=development uv run {{ ARGS_RUN }} python-tool {{ args }}

# Run CLI tool in production mode  
[group('run')]
prod *args:
    PYTHON_ENV=production uv run {{ ARGS_RUN }} python-tool {{ args }}

# Quick CLI command shortcuts
[group('run')]
status:
    @just run status --save-db --json

[group('run')]
health:
    @just run health

[group('run')]
demo:
    #!/usr/bin/env bash
    echo "Running CLI tool demo..."
    echo ""
    echo "1. Health check:"
    just run health
    echo ""
    echo "2. Echo command:"
    just run echo '"Hello World"' --reverse --json
    echo ""
    echo "3. Status with database:"
    just run status --save-db --json

# Update dependencies
[group('lifecycle')]
update:
    uv sync --upgrade

# Ensure project virtualenv is up to date
[group('lifecycle')]
install:
    uv sync

# Remove temporary files
[group('lifecycle')]
clear:
    rm -rf .venv .pytest_cache .mypy_cache .ruff_cache .coverage htmlcov
    find . -type d -name "__pycache__" -exec rm -r {} +

# Recreate project virtualenv from nothing
[group('lifecycle')]
fresh: clear install

# Build Docker image if not exists or if dependencies changed (defaults to host platform for speed)
[group('lifecycle')]
build-container:
    docker buildx build --platform linux/amd64,linux/arm64 -t {{SERVICE_NAME}}:latest .