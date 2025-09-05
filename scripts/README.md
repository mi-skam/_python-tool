# Scripts Directory

This directory contains bash scripts that are called by justfile targets to keep the justfile clean and maintainable.

## Scripts

### `dev.sh`
Sets up the development environment by starting Docker Compose services (primarily the PostgreSQL database).

**Usage**: Called by `just dev`
**Dependencies**: Docker Compose, `compose.yml`

### `push-container.sh`
Builds, tags, and pushes Docker images to GitHub Container Registry.

**Usage**: Called by `just push-container`
**Environment Variables Required**:
- `GIT_REGISTRY` - Container registry URL (e.g., ghcr.io)
- `GIT_USER` - GitHub username
**Dependencies**: Docker, built container image

## Design Principles

1. **Self-contained**: Each script should handle its own validation and error checking
2. **Environment-aware**: Scripts should validate required environment variables
3. **Executable**: All scripts must have execute permissions (`chmod +x`)
4. **Documentation**: Scripts should include comments explaining their purpose

## Adding New Scripts

When creating new scripts:
1. Add executable script to this directory
2. Update this README with script documentation  
3. Update the corresponding justfile target to call the script
4. Test both direct script execution and justfile target execution