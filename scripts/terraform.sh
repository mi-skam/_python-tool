#!/usr/bin/env bash
# Unified script for Terraform operations (plan/apply)
set -euo pipefail

# Determine action (plan or deploy) from first argument or default to plan
ACTION="${1:-plan}"
shift || true # Remove first argument if it exists

case "$ACTION" in
    plan|deploy)
        ;;
    *)
        echo "❌ Usage: $0 {plan|deploy}"
        echo "  plan   - Show what would change without applying"
        echo "  deploy - Plan and apply changes"
        exit 1
        ;;
esac

echo "📋 ${ACTION^}ing ${GIT_REPO}-${GIT_HASH}..."

if [ ! -f infrastructure/terraform.tfvars ]; then
    echo "❌ Create infrastructure/terraform.tfvars first!"
    exit 1
fi

# Validate required environment variables
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN environment variable is required for container registry authentication"
    exit 1
fi

cd infrastructure

# Initialize if needed
if [ ! -d .terraform ]; then
    echo "🔧 Initializing Terraform..."
    tofu init
fi

# Common Terraform variables
TF_VARS=(
    -var="project_name=${GIT_REPO}"
    -var="deployment_id=${GIT_HASH}"
    -var="image_tag=${GIT_REGISTRY}/${GIT_USER}/${GIT_REPO}:${GIT_HASH}"
    -var="github_user=${GIT_USER}"
    -var="github_token=${GITHUB_TOKEN}"
)

if [ "$ACTION" = "plan" ]; then
    # Show what would change
    tofu plan "${TF_VARS[@]}"
else
    # Create and show plan
    echo "📋 Planning infrastructure..."
    tofu plan "${TF_VARS[@]}" -out=tfplan

    # Apply the plan
    echo "🚀 Applying infrastructure..."
    tofu apply -auto-approve tfplan

    # Clean up plan file
    rm -f tfplan

    echo "✅ Infrastructure deployed!"
    
    # Get deployment info
    VM_IP=$(tofu output -json deployment_info | jq -r '.vm_ip')
    DNS_NAME=$(tofu output -json deployment_info | jq -r '.dns_name')
    
    echo "VM IP: $VM_IP"
    echo "DNS: $DNS_NAME"
    
    # Wait for SSH to be ready before proceeding to Ansible
    echo "⏳ Waiting for VM to be ready for SSH..."
    timeout=300
    elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if ssh -i deployment_key -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null deploy@${VM_IP} 'echo "SSH ready"' >/dev/null 2>&1; then
            echo "✅ VM is ready for deployment!"
            break
        fi
        sleep 10
        elapsed=$((elapsed + 10))
        if [ $((elapsed % 60)) -eq 0 ]; then
            echo "Still waiting... ($elapsed/${timeout}s)"
        fi
    done
    
    if [ $elapsed -ge $timeout ]; then
        echo "⚠️  Warning: VM not ready after ${timeout}s, proceeding anyway..."
    fi
    echo ""
fi

cd ..