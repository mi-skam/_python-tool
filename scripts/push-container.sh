#!/usr/bin/env bash
# Push Docker container to GitHub Container Registry
set -euo pipefail

# Get environment variables
GIT_HASH=$(git rev-parse --short HEAD)
GIT_REPO=$(basename $(git rev-parse --show-toplevel))

# Validate required environment variables
if [ -z "$GIT_REGISTRY" ]; then
    echo "Error: GIT_REGISTRY environment variable is required"
    exit 1
fi

if [ -z "$GIT_USER" ]; then
    echo "Error: GIT_USER environment variable is required"
    exit 1
fi

# Tag and push images
docker tag ${GIT_REPO}:latest ${GIT_REGISTRY}/${GIT_USER}/${GIT_REPO}:latest
docker tag ${GIT_REPO}:latest ${GIT_REGISTRY}/${GIT_USER}/${GIT_REPO}:${GIT_HASH}
docker push ${GIT_REGISTRY}/${GIT_USER}/${GIT_REPO}:latest
docker push ${GIT_REGISTRY}/${GIT_USER}/${GIT_REPO}:${GIT_HASH}