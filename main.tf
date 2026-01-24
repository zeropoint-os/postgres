terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

variable "zp_module_id" {
  type        = string
  default     = "postgres"
  description = "Unique identifier for this module instance (user-defined, freeform)"
}

variable "zp_arch" {
  type        = string
  default     = "amd64"
  description = "Target architecture - amd64, arm64, etc. (injected by zeropoint)"
}

variable "zp_gpu_vendor" {
  type        = string
  default     = ""
  description = "GPU vendor - nvidia, amd, intel, or empty for no GPU (injected by zeropoint)"
}

variable "zp_network_name" {
  type        = string
  description = "Pre-created Docker network name for this module (managed by zeropoint)"
}

variable "zp_module_storage" {
  type        = string
  description = "Host path for persistent storage (injected by zeropoint)"
}

variable "zp_db_user" {
  type        = string
  default     = "postgres"
  description = "Postgres user to create/use"
}

variable "zp_db_password" {
  type        = string
  description = "Postgres user password (injected or provided)"
  default     = "postgres"
}

variable "zp_db_name" {
  type        = string
  default     = "postgres"
  description = "Postgres database name"
}

locals {
  # Map the injected architecture to a Docker platform string used when pulling images.
  # Common values: "amd64" -> "linux/amd64", "arm64" -> "linux/arm64".
  image_platform = var.zp_arch == "arm64" ? "linux/arm64" : "linux/amd64"
}

# Pull the official Postgres image
resource "docker_image" "postgres" {
  name = "postgres:17"
  platform = local.image_platform
  keep_locally = true
}

# Main Postgres container (joined to zeropoint network, no host port binding)
resource "docker_container" "postgres_main" {
  name  = "${var.zp_module_id}-main"
  image = docker_image.postgres.image_id

  networks_advanced {
    name = var.zp_network_name
  }

  restart = "unless-stopped"

  env = [
    "POSTGRES_USER=${var.zp_db_user}",
    "POSTGRES_PASSWORD=${var.zp_db_password}",
    "POSTGRES_DB=${var.zp_db_name}",
  ]

  volumes {
    host_path      = "${var.zp_module_storage}/postgres"
    container_path = "/var/lib/postgresql/data"
  }

  # No host port binding; services access Postgres via the Docker network.
}

output "main" {
  value       = docker_container.postgres_main
  description = "Main Postgres container resource"
}

output "main_ports" {
  value = {
    postgres = {
      port        = 5432
      protocol    = "tcp"
      transport   = "tcp"
      description = "Postgres database port"
      default     = true
    }
  }
  description = "Service ports for external access"
}

output "postgres_connection" {
  value = {
    host     = docker_container.postgres_main.name
    port     = 5432
    user     = var.zp_db_user
    password = var.zp_db_password
    database = var.zp_db_name
    uri      = "postgresql://${var.zp_db_user}:${var.zp_db_password}@${docker_container.postgres_main.name}:5432/${var.zp_db_name}"
  }
  description = "Connection information usable by other zeropoint modules"
}