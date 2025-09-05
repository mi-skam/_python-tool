#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Deploying ${GIT_REPO}-${GIT_HASH}..."

if [ ! -f infrastructure/terraform.tfvars ]; then
    echo "❌ Create infrastructure/terraform.tfvars first!"
    exit 1
fi

cd infrastructure
[ ! -d .terraform ] && tofu init

tofu apply -auto-approve \
    -var="project_name=${GIT_REPO}" \
    -var="deployment_id=${GIT_HASH}" \
    -var="image_tag=${GIT_REGISTRY}/${GIT_USER}/${GIT_REPO}:${GIT_HASH}"

echo "✅ Deployed to:"
tofu output -json deployment_info | jq -r '.deployed_url'
cd ..