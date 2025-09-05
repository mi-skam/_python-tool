# justfile for python-tool CLI application

# Load environment variables from .env file if it exists
set dotenv-load := true

SERVICE_NAME := env_var("SERVICE_NAME")
GIT_USER := env_var("GIT_USER")
GIT_REGISTRY := env_var("GIT_REGISTRY")
GIT_HASH := `git rev-parse --short HEAD`
GIT_REPO := `basename $(git rev-parse --show-toplevel)`

GITHUB_TOKEN := env_var_or_default("GITHUB_TOKEN", `gh auth token 2>/dev/null || echo ""`)

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

# Setup development environment (start database)
[group('run')]
dev:
    ./scripts/dev.sh

# Run CLI tool commands via SSH to cloud infrastructure
[group('run')]
ssh *args:
    ./scripts/ssh.sh {{args}}

# Update dependencies
[group('lifecycle')]
update:
    uv sync --upgrade

# Initialize template with project-specific values
[group('lifecycle')]
setup:
    @./scripts/init-template.sh

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

# Build Docker image if not exists or if dependencies changed
[group('deploy')]
build:
    docker buildx build --platform linux/amd64,linux/arm64 -t {{GIT_REPO}}:latest .

# Push Docker image to Container Registry
[group('deploy')]
push: build
    #!/usr/bin/env bash
    export GIT_REPO="{{GIT_REPO}}"
    export GIT_HASH="{{GIT_HASH}}"
    export GIT_REGISTRY="{{GIT_REGISTRY}}"
    export GIT_USER="{{GIT_USER}}"
    export GITHUB_TOKEN="{{GITHUB_TOKEN}}"
    ./scripts/push-container.sh

# Deploy to cloud infrastructure
[group('deploy')]
deploy:
    #!/usr/bin/env bash
    export GIT_REPO="{{GIT_REPO}}"
    export GIT_HASH="{{GIT_HASH}}"
    export GIT_REGISTRY="{{GIT_REGISTRY}}"
    export GIT_USER="{{GIT_USER}}"
    export GITHUB_TOKEN="{{GITHUB_TOKEN}}"
    ./scripts/terraform.sh deploy
    ./scripts/ansible.sh

# Destroy deployment
[group('deploy')]
teardown:
    #!/usr/bin/env bash
    export GIT_REPO="{{GIT_REPO}}"
    export GIT_HASH="{{GIT_HASH}}"
    export GIT_REGISTRY="{{GIT_REGISTRY}}"
    export GIT_USER="{{GIT_USER}}"
    export GITHUB_TOKEN="{{GITHUB_TOKEN}}"
    
    cd infrastructure && tofu destroy -auto-approve \
            -var="project_name=${GIT_REPO}" \
            -var="deployment_id=${GIT_HASH}" \
            -var="image_tag=${GIT_REGISTRY}/${GIT_USER}/${GIT_REPO}:${GIT_HASH}" \
            -var="github_user=${GIT_USER}" \
            -var="github_token=${GITHUB_TOKEN}"
