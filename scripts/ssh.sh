#!/usr/bin/env bash
# SSH to deployed Hetzner Cloud VM
set -euo pipefail

COMMAND="${@:-null}"

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

if [ "$COMMAND" != "null" ]; then
    ssh -T -i deployment_key -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no deploy@${VM_IP} "$COMMAND"
    exit 0
elif [ "$COMMAND" != "" ]; then
    ssh -i deployment_key -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no deploy@${VM_IP}
fi
