#!/usr/bin/env bash
# Setup development environment (start database)
set -euo pipefail

# Start Docker Compose services if compose.yml exists
if [ -f compose.yml ]; then
    echo "🚀 Starting development services..."
    docker compose -f compose.yml up --remove-orphans -d
    echo "⏳ Waiting for services to be ready..."
    sleep 3
else
    echo "ℹ️ No compose.yml found - skipping service startup"
fi