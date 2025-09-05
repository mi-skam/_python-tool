terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# Generate SSH key pair for this deployment
resource "tls_private_key" "deploy_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generate random password for deploy user
resource "random_password" "deploy_password" {
  length  = 16
  special = true
}

# Create SSH key in Hetzner Cloud
resource "hcloud_ssh_key" "deploy_key" {
  name       = "${var.project_name}-${var.deployment_id}"
  public_key = tls_private_key.deploy_key.public_key_openssh
}

# Create the VM
resource "hcloud_server" "app_server" {
  name        = "${var.project_name}-${var.deployment_id}"
  image       = "ubuntu-22.04"
  server_type = "cx22"  # Small AMD instance (2 vCPU, 4GB RAM)
  location    = "nbg1"  # Nuremberg datacenter

  ssh_keys = [hcloud_ssh_key.deploy_key.id]

  user_data = templatefile("${path.module}/cloud-init.yml", {
    deploy_password_hash = bcrypt(random_password.deploy_password.result)
    ssh_public_key      = tls_private_key.deploy_key.public_key_openssh
    project_name        = var.project_name
    deployment_id       = var.deployment_id
    image_tag          = var.image_tag
  })

  # Allow changes to user_data without recreating the server
  lifecycle {
    ignore_changes = [user_data]
  }
}

# Create DNS record
resource "cloudflare_record" "app_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "${var.project_name}-${var.deployment_id}"
  content = hcloud_server.app_server.ipv4_address
  type    = "A"
  ttl     = 300
}

# Output important information
output "deployment_info" {
  value = {
    vm_ip            = hcloud_server.app_server.ipv4_address
    vm_name          = hcloud_server.app_server.name
    dns_name         = cloudflare_record.app_dns.hostname
    ssh_command      = "ssh -i deployment_key deploy@${hcloud_server.app_server.ipv4_address}"
    deploy_password  = random_password.deploy_password.result
    deployment_id    = var.deployment_id
  }
  sensitive = true
}

# Save SSH private key to local file
resource "local_file" "private_key" {
  content         = tls_private_key.deploy_key.private_key_pem
  filename        = "${path.module}/deployment_key"
  file_permission = "0600"
}
