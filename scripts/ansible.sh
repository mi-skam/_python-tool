#!/usr/bin/env bash
# Deploy application with Ansible after infrastructure is ready
set -euo pipefail

echo "🚀 Deploying application with Ansible..."

cd infrastructure

# Get deployment info from Terraform
if [ ! -f terraform.tfstate ]; then
    echo "❌ No infrastructure found. Run 'just deploy' first to create infrastructure."
    exit 1
fi

VM_IP=$(tofu output -json deployment_info 2>/dev/null | jq -r '.vm_ip')
DNS_NAME=$(tofu output -json deployment_info 2>/dev/null | jq -r '.dns_name')

if [ "$VM_IP" = "null" ] || [ -z "$VM_IP" ]; then
    echo "❌ Could not get VM IP from Terraform state. Is the infrastructure deployed?"
    exit 1
fi

echo "📍 Target VM: $VM_IP ($DNS_NAME)"

cd ../ansible

# Install required Ansible collections
echo "📦 Installing Ansible collections..."
ansible-galaxy collection install -r requirements.yml --force >/dev/null 2>&1 || echo "Note: Failed to install collections, proceeding anyway..."

# Create dynamic inventory
cat > inventory.ini << EOF
[deployment]
$VM_IP ansible_user=deploy
EOF

# Run Ansible playbook
ansible-playbook -i inventory.ini deploy.yml \
    -e "project_name=${GIT_REPO}" \
    -e "deployment_id=${GIT_HASH}" \
    -e "image_tag=${GIT_REGISTRY}/${GIT_USER}/${GIT_REPO}:${GIT_HASH}" \
    -e "github_user=${GIT_USER}" \
    -e "github_token=${GITHUB_TOKEN}"

cd ..