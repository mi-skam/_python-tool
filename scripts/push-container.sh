#!/usr/bin/env bash
# Push Docker container to Container Registry
set -euo pipefail

# Define image references
LOCAL_IMAGE="${GIT_REPO}:latest"
REMOTE_IMAGE="${GIT_REGISTRY}/${GIT_USER}/${GIT_REPO}"

# Tag and push images
echo "📦 Tagging images..."
docker tag "${LOCAL_IMAGE}" "${REMOTE_IMAGE}:latest"
docker tag "${LOCAL_IMAGE}" "${REMOTE_IMAGE}:${GIT_HASH}"

echo "🚀 Pushing to ${GIT_REGISTRY}..."
docker push "${REMOTE_IMAGE}:latest"
docker push "${REMOTE_IMAGE}:${GIT_HASH}"

success "Container pushed to ${REMOTE_IMAGE}:${GIT_HASH}"