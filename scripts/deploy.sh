#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Deploying ${GIT_REPO}-${GIT_HASH}..."

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

# Create and show plan
echo "📋 Planning deployment..."
tofu plan \
    -var="project_name=${GIT_REPO}" \
    -var="deployment_id=${GIT_HASH}" \
    -var="image_tag=${GIT_REGISTRY}/${GIT_USER}/${GIT_REPO}:${GIT_HASH}" \
    -out=tfplan

# Apply the plan
echo "🚀 Applying deployment..."
tofu apply -auto-approve tfplan

# Clean up plan file
rm -f tfplan

echo "✅ Deployment complete!"
echo "VM IP: $(tofu output -json deployment_info | jq -r '.vm_ip')"
echo "DNS: $(tofu output -json deployment_info | jq -r '.dns_name')"
echo ""
echo "Use 'just ssh' to connect or 'just ssh-run <command>' to run python-tool"
cd ..