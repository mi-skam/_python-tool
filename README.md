# Python CLI Tool Template with uv & Docker

A production-ready CLI application template demonstrating modern Python development practices with containerization, dependency management, and database integration.

## Template Overview

- **CLI application** with argument parsing and command structure
- **PostgreSQL database integration** for optional data persistence
- **uv dependency management** for fast, reliable package handling  
- **Docker containerization** with multi-stage builds for production deployment
- **just task automation** for streamlined development workflows
- **Database models & migrations** using SQLAlchemy ORM
- **Quality assurance tools** including linting, testing, and type checking
- **GitHub Actions CI/CD** pipeline ready for deployment

## Architecture Components

### Core Application (`src/python_tool/`)
- **`main.py`** - Main CLI application with argument parsing and command handlers
- **`models.py`** - SQLAlchemy models for optional data persistence 

### Development Infrastructure
- **`justfile`** - Task automation (like `npm scripts` but more powerful)
- **`pyproject.toml`** - Project dependencies and Python package configuration
- **`uv.lock`** - Locked dependency versions for reproducible builds
- **`compose.yml`** - PostgreSQL database for local development (optional)

### Production Infrastructure  
- **`Dockerfile`** - Multi-stage build optimized for production
- **`compose.prod.yml`** - Production container orchestration
- **`docker-entrypoint.sh`** - Container startup script

### Quality Assurance
- **`ruff.toml`** - Modern Python linter and formatter configuration
- **`ty`** - Static type checking configuration
- **`tests/`** - Comprehensive test suite with coverage

## Prerequisites

- Docker (optional - only needed for database features)
- [just](https://github.com/casey/just) task runner
- [uv](https://docs.astral.sh/uv/) Python Package manager

## Quick Start

### 1. Setup Environment
```bash
cp .env.example .env
# Edit .env with your preferred settings
```

### 2. Install Dependencies
```bash
just install  # Install dependencies
```

### 3. Run CLI Tool
```bash
# Basic commands (no database required)
just run health
just run echo "Hello World" --reverse

# With database (starts PostgreSQL automatically)
just dev  # Setup database
just run status --save-db
```

### 4. Verify Everything Works
```bash
just test     # Run test suite
just demo     # Run demo commands
```

## Available Commands

### Development Workflow
| Command | Description |
|---------|-------------|
| `just install` | Install dependencies using uv |
| `just dev` | Setup development environment (start database) |
| `just run <command>` | Run CLI tool commands in development mode |
| `just demo` | Run demonstration of CLI features |

### CLI Tool Commands
| Command | Description |
|---------|-------------|
| `python-tool health` | Health check - returns OK |
| `python-tool echo <text>` | Echo text with optional transformations |
| `python-tool status` | Show application status and system info |

### CLI Options
| Option | Description |
|--------|-------------|
| `--json` | Output results in JSON format |
| `--reverse` | (echo command) Also return reversed text |
| `--save-db` | (status command) Save execution to database |

### Quality Assurance  
| Command | Description |
|---------|-------------|
| `just test` | Run test suite with pytest |
| `just cov` | Run tests with coverage reporting |
| `just lint` | Run ruff linter and formatter |
| `just typing` | Run mypy type checking |
| `just check-all` | Run all quality checks (lint + coverage + typing) |

### Production & Deployment
| Command | Description |
|---------|-------------|
| `just prod <command>` | Run CLI tool in production mode |
| `just build-container` | Build multi-platform Docker image |

### Lifecycle Management
| Command | Description |
|---------|-------------|
| `just update` | Update Python dependencies |
| `just fresh` | Clean install from scratch |
| `just clear` | Remove temporary files and caches |

## Configuration

Required environment variables in `.env`:

```bash
# Application settings
SERVICE_NAME=python-tool
PYTHON_ENV=development

# Database connection (optional - only needed for --save-db features)
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=app_db
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
```

## Building Your CLI Tool

### 1. Add New Commands
Start by modifying `src/python_tool/main.py`:

```python
# Add new subparser
my_parser = subparsers.add_parser("my-command", help="My custom command")
my_parser.add_argument("--option", help="Custom option")

# Add handler in main()
elif args.command == "my-command":
    result = my_custom_function(args.option)
    print(result)
```

### 2. Create Database Models  
Add new models to `src/python_tool/models.py`:

```python
class MyModel(Base):
    __tablename__ = "my_table"
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
```

### 3. Add Dependencies
Add new packages to `pyproject.toml`:

```toml
dependencies = [
    "python-dotenv",
    "psycopg2-binary",
    "sqlalchemy",
    "your-new-package",  # Add here
]
```

Then run: `just update`

### 4. Write Tests
Add tests to `tests/test_main.py`:

```python
def test_my_command():
    result = my_custom_function("test-input")
    assert result == "expected-output"
```

### 5. Configure Production
Update `compose.prod.yml` for your deployment needs:
- Environment variables
- Command to run
- Resource limits

## CLI Examples

The template includes a demo CLI tool with database integration:

### Basic Commands
```bash
# Health check
$ python-tool health
OK

# Echo with transformations
$ python-tool echo "hello world" --reverse --json
{
  "original": "hello world",
  "length": 11,
  "reversed": "dlrow olleh"
}
```

### Status with Database
```bash
$ python-tool status --save-db --json
{
  "python_version": "3.12.0 (main, ...)",
  "environment": "development",
  "service_name": "python-tool",
  "timestamp": "2024-01-01T12:00:00.000000",
  "database_status": "connected",
  "recent_executions": [
    {
      "id": 1,
      "timestamp": "2024-01-01T11:59:55.123456",
      "command": "status",
      "environment": "development"
    }
  ]
}
```

## Testing Strategy

```bash
just test      # Run pytest test suite
just cov       # Generate coverage report  
just typing    # Check static types
just check-all # Run all quality checks
```

**Test coverage includes:**
- All CLI command functions (success & error cases)
- Database model operations
- Error handling and edge cases
- Command-line argument parsing
- Subprocess execution of CLI commands

## Deployment Patterns

### Local Development
```bash
just install    # Install dependencies
just dev        # Setup database (optional)
just run health # Test CLI quickly  
just demo       # See all features
just check-all  # Verify code quality
```

### Production Container
```bash
just build-container     # Build optimized image
docker run python-tool:latest python-tool health
```

### Container with Database
```bash
docker compose -f compose.prod.yml up
# Runs CLI tool with database connection
```

## Troubleshooting

### Environment Issues
**Missing `.env` file:**
```bash
cp .env.example .env
# Edit .env with your settings
```

**Missing SERVICE_NAME:**
```bash
# Add to .env file
SERVICE_NAME=python-tool
```

### Database Issues (Optional)
**PostgreSQL connection failed:**
```bash
# Restart database container
docker compose down
just dev  # Will restart PostgreSQL automatically
```

**Database schema errors:**
```bash
# Clear database and restart
docker compose down -v  # Removes volumes
just dev  # Creates fresh database
```

### Docker Issues
**Build failures:**
```bash
# Clear Docker cache
docker builder prune
just build-container
```

**Permission errors:**
```bash
# Ensure Docker daemon is running
docker ps
```

### CLI Tool Issues
**Command not found:**
```bash
# Ensure CLI is installed
just install

# Run via module instead
uv run python -m src.python_tool.main health
```

## Template Customization

### Change Application Name
1. Update `SERVICE_NAME` in `.env`
2. Update `[project]` name in `pyproject.toml`
3. Update script name in `[project.scripts]`
4. Update import paths if needed

### Add New Commands
1. Add subparser in `main.py`
2. Add command handler function
3. Add command logic to main() function
4. Write tests for new command

### Remove Database Features
1. Remove database-related dependencies from `pyproject.toml`
2. Remove database imports from `main.py`
3. Remove `--save-db` options and database code
4. Remove `compose.yml` and `models.py`

### Custom justfile Tasks
Add to `justfile`:
```just
# Custom deployment
deploy:
    docker build -t myapp:latest .
    docker push registry.example.com/myapp:latest
```