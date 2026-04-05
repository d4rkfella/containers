terraform {
  required_providers {
    apko   = { source = "chainguard-dev/apko" }
    cosign = { source = "chainguard-dev/cosign" }
  }
  backend "s3" {
    key = "bazarr/terraform.tfstate"
  }
}

data "apko_config" "this" {
  config_contents = file("${path.module}/apko.yaml")
}

data "apko_tags" "this" {
  config         = data.apko_config.this.config
  target_package = "bazarr"
}

module "bazarr_image" {
  source = "chainguard-dev/apko/publisher"

  target_repository = "ghcr.io/d4rkfella/bazarr"
  config            = file("${path.module}/apko.yaml")
  skip_attest       = false
  check_sbom        = true
}

output "image_tags" {
  value       = data.apko_tags.this.tags
  description = "Tags derived from the tracked package version."
}

output "sboms" {
  value       = module.bazarr_image.sboms
  description = "Map of architectures to their digests and SBOM paths."
}