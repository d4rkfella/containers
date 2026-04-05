variable "image_name" {}
variable "config_file" {}
variable "target_repository" {}

terraform {
  required_providers {
    apko = {
      source  = "chainguard-dev/apko"
      version = ">= 0.29.10"
    }
    cosign = {
      source  = "chainguard-dev/cosign"
      version = ">= 0.2.7"
    }
  }
}

module "apko" {
  source            = "chainguard-dev/apko/publisher"
  version           = "0.0.18"
  config            = file(var.config_file)
  target_repository = var.target_repository
}

output "config" {
  value = module.apko.config
}

output "image_ref" {
  value = module.apko.image_ref
}
