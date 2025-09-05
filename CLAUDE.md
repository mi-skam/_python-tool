# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Python CLI tool template demonstrating modern development practices with:
- **CLI application** with argument parsing and command structure
- **uv dependency management** for fast package handling
- **Docker containerization** with multi-stage builds
- **just task automation** for streamlined workflows  
- **SQLAlchemy ORM** with optional database integration
- **Comprehensive testing** with pytest and coverage
- **Quality assurance** with ruff linting and mypy type checking

## Environment Setup

1. **Copy environment template**: `cp .env.example .env`
2. **Configure settings** in `.env` (required - fail-fast approach)
3. **Python version**: 3.12 (specified in pyproject.toml)

## Key Commands

### Development Workflow
```bash
just install          # Install dependencies using uv
just dev              # Setup development environment (start database)
just run <command>    # Run CLI tool commands
just demo             # Run demonstration commands
```

### Quality Assurance
```bash
just test             # Run tests with pytest
just cov              # Run tests with coverage reporting  
just lint             # Run ruff linter and formatter
just typing           # Run mypy type checking
just check-all        # Run all quality checks (lint + coverage + typing)
```

### Production & Deployment  
```bash
just prod <command>   # Run CLI tool in production mode
just build-container  # Build multi-platform Docker image
```

### Lifecycle Management
```bash
just update           # Update Python dependencies
just fresh            # Clean install from scratch  
just clear            # Remove temporary files and caches
```

## Configuration

Required environment variables in `.env`:
- **SERVICE_NAME**: python-tool (application identifier)
- **PYTHON_ENV**: development or production
- **POSTGRES_USER/PASSWORD/DB/HOST/PORT**: Database connection settings (optional)

## Project Structure

```
.
├── src/
│   └── python_tool/
│       ├── __init__.py
│       ├── main.py         # CLI application with argument parsing
│       └── models.py       # SQLAlchemy database models (optional)
├── tests/
│   ├── __init__.py
│   └── test_main.py        # Test suite
├── .github/
│   └── workflows/
│       └── ci.yml          # CI/CD pipeline
├── .env.example            # Environment template
├── compose.yml             # Docker Compose config
├── compose.prod.yml        # Production Docker config
├── Dockerfile              # Container definition
├── docker-entrypoint.sh    # Container entry point
├── justfile                # Task automation
├── pyproject.toml          # Dependencies and config
├── ruff.toml               # Linter config
├── mypy.ini                # Type checker config
└── uv.lock                 # Locked dependencies
```

## CLI Application

The CLI tool (`src/python_tool/main.py`) demonstrates:
- **`health`** - Health check command
- **`echo <text>`** - Echo service with optional text transformations
- **`status`** - System info with optional database logging

**Key Features:**
- **Argument parsing** - Using argparse for command structure
- **Database persistence** - Optional execution logging to PostgreSQL
- **JSON output** - Structured output format option
- **Error handling** - Graceful degradation if database unavailable

## CLI Usage Examples

```bash
# Basic commands
python-tool health
python-tool echo "hello world" --reverse --json
python-tool status --json

# With database integration
python-tool status --save-db --json
```

## Testing

```bash
just test         # Run all tests
just cov          # Run tests with coverage report
just check-all    # Run all checks (lint, coverage, typing)
```

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`):
- Runs on push/PR to main branch
- Uses Python 3.12
- Executes `just check-all` for quality gates
- Builds and tests Docker container with CLI commands

## Common Issues

### Missing Environment Variables
```
error: environment variable `VARIABLE_NAME` not present
```
**Solution**: Ensure `.env` file exists with all required variables from `.env.example`

### Database Connection Issues (Optional)
```bash
# Restart database container
docker compose down
just dev  # Will restart PostgreSQL automatically

# Clear database volumes if needed
docker compose down -v
just dev  # Creates fresh database
```

### CLI Command Issues
```bash
# If python-tool command not found
just install  # Reinstall CLI tool

# Or run via module
uv run python -m src.python_tool.main health
```

## Best Practices

1. **Always use `.env`**: No hardcoded configuration (fail-fast approach)
2. **Test locally first**: Use `just run health` for quick testing
3. **Run checks**: Use `just check-all` before committing
4. **CI/CD**: All PRs must pass `just check-all` to merge

## Docker

### Build and Run
```bash
just build-container                    # Build Docker image
docker run -e SERVICE_NAME=python-tool python-tool:latest python-tool health
```

### Container Registry (GitHub Container Registry)

**First-time setup**: After pushing your first container, make the package public:

1. **Push container**: `just push-container`
2. **Make public**: Go to https://github.com/mi-skam/python-tool/pkgs/container/python-tool
3. Click **Package settings** → **Change visibility** → **Public**

Or use the helper command: `just make-package-public`

Once public, deployments can pull without authentication:
```bash
docker pull ghcr.io/mi-skam/python-tool:latest
```

### Production Deployment
```bash
docker compose -f compose.prod.yml up   # Run with production config
```

## Development Workflow

1. Make changes to code
2. Run `just test` to verify tests pass
3. Run `just check-all` to ensure code quality
4. Test CLI commands with `just run <command>`
5. Commit changes (CI will run automatically)

## Adding New CLI Commands

1. **Add subparser** in `main.py`:
```python
new_parser = subparsers.add_parser("new-command", help="Description")
new_parser.add_argument("--option", help="Option help")
```

2. **Add command handler**:
```python
elif args.command == "new-command":
    result = handle_new_command(args.option)
    print(result)
```

3. **Write tests**:
```python
def test_new_command():
    result = handle_new_command("test-input")
    assert result == "expected-output"
```

## Database Integration (Optional)

The template includes optional PostgreSQL integration:
- **Models**: Defined in `models.py`
- **Usage**: Commands with `--save-db` flag store execution logs
- **Setup**: `just dev` starts database automatically
- **Testing**: Mocked database sessions in tests

## Justfile Syntax Reference

**IMPORTANT**: Always use proper justfile syntax to avoid errors:

```just
# Variables (at top of file)
var := "value"
var := `command`
var := env_var("VAR_NAME")

# Simple recipe (single command)
target:
    command args

# Recipe with parameters
target param="default":
    command {{param}}

# Recipe with environment variable
target:
    VAR=value command

# Recipe with bash script (for complex logic)
target:
    #!/usr/bin/env bash
    if [ condition ]; then
        command
    fi
```

**Common Mistakes to Avoid:**
- ❌ `target: command` (missing indentation)
- ❌ `target: VAR=value command` (env var on same line)
- ❌ Single-line conditionals with `{{ if }}`
- ✅ Always indent recipe bodies with 4 spaces
- ✅ Put environment variables on separate line
- ✅ Use bash scripts for conditionals