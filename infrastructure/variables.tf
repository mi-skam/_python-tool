variable "hetzner_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for your domain"
  type        = string
}

variable "project_name" {
  description = "Name of the project (used in hostname)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "deployment_id" {
  description = "Unique identifier for this deployment (usually git hash)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.deployment_id))
    error_message = "Deployment ID must contain only lowercase letters and numbers."
  }
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
}

variable "domain" {
  description = "Base domain for deployments"
  type        = string
}

variable "github_user" {
  description = "GitHub username for container registry authentication"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token for container registry authentication"
  type        = string
  sensitive   = true
}
