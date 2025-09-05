# justfile for python-tool CLI application

# Load environment variables from .env file if it exists
set dotenv-load := true

SERVICE_NAME := env_var("SERVICE_NAME")
GIT_USER := env_var("GIT_USER")
GIT_REGISTRY := env_var("GIT_REGISTRY")
GIT_HASH := `git rev-parse --short HEAD`
GIT_REPO := `basename $(git rev-parse --show-toplevel)`

HOST := env("HOST", "127.0.0.1")
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

# Test deployment locally with git hash
[group('qa')]
test-deploy: push-container
    IMAGE_TAG={{GIT_HASH}} GIT_REGISTRY={{GIT_REGISTRY}} GIT_USER={{GIT_USER}} GIT_REPO={{GIT_REPO}} docker compose -f compose.prod.yml up --remove-orphans -d
    echo "Check the health endpoint at http://{{HOST}}:8098/health"
    docker compose -f compose.prod.yml logs

# Setup development environment (start database)
[group('run')]
dev:
    ./scripts/dev.sh

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
[group('deploy')]
build-container:
    docker buildx build --platform linux/amd64,linux/arm64 -t {{GIT_REPO}}:latest .

[group('deploy')]
push-container: build-container
    ./scripts/push-container.sh

# Make GitHub package public (one-time setup)
[group('deploy')]
make-package-public:
    ./scripts/make-package-public.sh

# Plan deployment changes
[group('deploy')]
plan:
    #!/usr/bin/env bash
    export GIT_REPO="{{GIT_REPO}}"
    export GIT_HASH="{{GIT_HASH}}"
    export GIT_REGISTRY="{{GIT_REGISTRY}}"
    export GIT_USER="{{GIT_USER}}"
    ./scripts/plan.sh

# Deploy to cloud infrastructure
[group('deploy')]
deploy: plan
    #!/usr/bin/env bash
    export GIT_REPO="{{GIT_REPO}}"
    export GIT_HASH="{{GIT_HASH}}"
    export GIT_REGISTRY="{{GIT_REGISTRY}}"
    export GIT_USER="{{GIT_USER}}"
    ./scripts/deploy.sh

# SSH to cloud infrastructure
[group('deploy')]
ssh:
    ./scripts/ssh.sh

# Run python-tool command on deployed VM
[group('deploy')]
ssh-run *args:
    ./scripts/ssh-run.sh {{args}}

# Destroy deployment
[group('deploy')]
teardown:
    #!/usr/bin/env bash
    echo "🧨 Destroying deployment..."
    read -p "Are you sure? (y/N): " -n 1 -r && echo
    [[ $REPLY =~ ^[Yy]$ ]] && cd infrastructure && tofu destroy -auto-approve
