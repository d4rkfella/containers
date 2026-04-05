terraform {
  required_providers {
    apko = { source = "chainguard-dev/apko" }
  }

  backend "s3" {
    key = "bazarr/terraform.tfstate"
  }
}

provider "apko" {
  default_archs = ["amd64", "arm64"]

  extra_keyring = [
    "https://packages.darkfellanetwork.com/artifactory/wolfi-os/melange.rsa.pub"
  ]

  build_repositories = [
    "https://packages.darkfellanetwork.com/artifactory/wolfi-os/latest/main"
  ]

  extra_packages = ["wolfi-baselayout"]
}

data "apko_config" "this" {
  config_contents = file("${path.module}/apko.yaml")
}

data "apko_tags" "this" {
  config         = data.apko_config.this.config
  target_package = "bazarr"
}

module "apko" {
  source  = "chainguard-dev/apko/publisher"
  version = "0.0.18"

  config = file("${path.module}/apko.yaml")

  target_repository = "ghcr.io/d4rkfella/bazarr"

  # optional but useful
  extra_packages = ["wolfi-baselayout"]
}

resource "oci_tag" "this" {
  for_each   = toset(data.apko_tags.this.tags)
  digest_ref = module.apko.image_ref
  tag        = each.value
}


output "image_ref" {
  value       = module.apko.image_ref
  description = "The fully-qualified index digest."
}

output "arch_digests" {
  value       = module.apko.arch_to_image
  description = "Map of architecture to fully-qualified digest ref."
}

output "image_tags" {
  value       = data.apko_tags.this.tags
  description = "Tags derived from the bazarr package version."
}