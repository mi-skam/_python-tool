# Python CLI Template

A modern Python CLI application template with deployment automation, featuring:

- **Modern Python development** with uv, ruff, mypy, pytest
- **CLI application framework** with argparse and command structure  
- **Docker containerization** with multi-stage builds
- **Infrastructure as Code** with Terraform/OpenTofu + Hetzner Cloud + Cloudflare
- **Configuration Management** with Ansible
- **CI/CD pipeline** with GitHub Actions
- **Database integration** with SQLAlchemy (optional)

## Quick Start

### 1. Initialize Template
```bash
./scripts/init-template.sh
```
This interactive script will:
- Replace all template placeholders with your project values
- Rename directories and files appropriately  
- Create initial configuration files

### 2. Development Setup
```bash
just install  # Install dependencies
just dev      # Start development environment
just test     # Run tests to verify setup
```

### 3. Optional: Deployment Setup
If you want to deploy to the cloud:

1. **Configure infrastructure tokens** in `infrastructure/terraform.tfvars`
2. **Deploy**: `just deploy`
3. **Test deployment**: `just ssh status`
4. **Teardown**: `just teardown`

## Template Features

### Development Workflow
- **Task automation** with `justfile` 
- **Fast dependency management** with `uv`
- **Code quality** with `ruff` (linting/formatting) + `mypy` (type checking)
- **Testing** with `pytest` + coverage reporting
- **Docker development** with compose setup

### Production Deployment  
- **Infrastructure**: Hetzner Cloud VMs + Cloudflare DNS
- **Automation**: Terraform → Ansible → Health checks
- **Container registry**: GitHub Container Registry (ghcr.io)
- **Monitoring**: Built-in health checks and status reporting

### Project Structure
```
├── src/YOUR_PROJECT_NAME/     # Main application code
├── tests/                     # Test suite
├── infrastructure/            # Terraform configuration
├── ansible/                   # Deployment playbooks  
├── scripts/                   # Automation scripts
├── .github/workflows/         # CI/CD pipeline
├── justfile                   # Task automation
└── pyproject.toml            # Python project config
```

## Available Commands

### Development
```bash
just install     # Install dependencies
just dev         # Start development services
just test        # Run test suite
just lint        # Code linting and formatting
just typing      # Type checking
just check-all   # All quality checks
```

### Application
```bash  
just run health                    # Health check
just run echo "hello" --json      # Echo command with JSON output
just run status --save-db         # Status with database logging
```

### Deployment
```bash
just build       # Build Docker image
just push        # Push to container registry  
just deploy      # Deploy infrastructure + application
just ssh <cmd>   # Run commands on deployed server
just teardown    # Destroy infrastructure
```

## Configuration

### Required Files
- **`.env`** - Application configuration (created from `.env.example`)
- **`infrastructure/terraform.tfvars`** - Cloud credentials (created from template)

### Key Environment Variables
- **`SERVICE_NAME`** - Your project name  
- **`GIT_USER`** - Your GitHub username
- **`PYTHON_ENV`** - development | production

## Template Customization

The template uses these placeholders:
- **`YOUR_PROJECT_NAME`** - Replaced with your project name
- **`YOUR_GITHUB_USERNAME`** - Replaced with your GitHub username  
- **`your-domain.com`** - Replaced with your domain (if deploying)

Run `./scripts/init-template.sh` to automatically replace all placeholders.

## Infrastructure Details

### Cloud Providers
- **Hetzner Cloud** - VPS hosting (cost-effective, EU-based)
- **Cloudflare** - DNS management + CDN

### Deployment Architecture
```
GitHub Actions → Docker Image → GitHub Container Registry
       ↓
Terraform → Hetzner VM + Cloudflare DNS  
       ↓
Ansible → Application deployment + health checks
```

### Security Features
- **Fail2ban** - Intrusion prevention
- **UFW firewall** - Network security  
- **SSH key authentication** - No password login
- **Container isolation** - Application runs in Docker

## Getting Help

1. **Check the justfile**: `just` (lists all available commands)
2. **Read CLAUDE.md**: Detailed development guidance
3. **Review example configs**: All `.example` files show required format

## License

MIT License - Use this template freely for any project.