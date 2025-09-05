#!/usr/bin/env bash
    cd infrastructure  
    VM_IP=$(tofu output -json deployment_info | jq -r '.vm_ip')
    ssh -i deployment_key -o StrictHostKeyChecking=no deploy@${VM_IP}