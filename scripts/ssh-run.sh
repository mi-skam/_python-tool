#!/usr/bin/env bash
# SSH to deployed VM and run python-tool command
set -euo pipefail

cd infrastructure

# Check if deployment exists
if [ ! -f terraform.tfstate ]; then
    echo "❌ No deployment found. Run 'just deploy' first."
    exit 1
fi

# Get VM IP from Terraform output
VM_IP=$(tofu output -json deployment_info | jq -r '.vm_ip')

if [ "$VM_IP" = "null" ] || [ -z "$VM_IP" ]; then
    echo "❌ Could not get VM IP from deployment. Is the deployment running?"
    exit 1
fi

# Default to health command if no args provided
COMMAND="${@:-health}"

echo "🔗 Running 'python-tool $COMMAND' on VM at $VM_IP..."
ssh -T -i deployment_key -o StrictHostKeyChecking=no deploy@${VM_IP} "python-tool $COMMAND"