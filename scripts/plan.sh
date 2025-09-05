#!/usr/bin/env bash
# Plan deployment changes without applying
set -euo pipefail

echo "📋 Planning ${GIT_REPO}-${GIT_HASH}..."

if [ ! -f infrastructure/terraform.tfvars ]; then
    echo "❌ Create infrastructure/terraform.tfvars first!"
    exit 1
fi

cd infrastructure

# Initialize if needed
if [ ! -d .terraform ]; then
    echo "🔧 Initializing Terraform..."
    tofu init
fi

# Show what would change
tofu plan \
    -var="project_name=${GIT_REPO}" \
    -var="deployment_id=${GIT_HASH}" \
    -var="image_tag=${GIT_REGISTRY}/${GIT_USER}/${GIT_REPO}:${GIT_HASH}"

cd ..