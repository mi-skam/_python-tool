#!/usr/bin/env bash
# Setup development environment (start database)
set -euo pipefail

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