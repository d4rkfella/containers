terraform {
  required_providers {
    apko = { source = "chainguard-dev/apko" }
    cosign = { source = "chainguard-dev/cosign" }
  }
  backend "s3" {
    key = "bazarr/terraform.tfstate"
  }
}

provider "apko" {
  default_archs      = ["amd64", "arm64"]
  extra_repositories = ["https://packages.wolfi.dev/os"]
  extra_keyring      = [
    "https://packages.darkfellanetwork.com/artifactory/wolfi-os/melange.rsa.pub"
  ]
  extra_packages     = ["wolfi-baselayout"]
  build_repositories = ["https://packages.darkfellanetwork.com/artifactory/wolfi-os/latest/main"]
}

data "apko_config" "this" {
  config_contents = file("${path.module}/apko.yaml")
}

data "apko_tags" "this" {
  config         = data.apko_config.this.config
  target_package = "bazarr"
}

resource "apko_build" "this" {
  repo    = "ghcr.io/d4rkfella/bazarr"
  config  = data.apko_config.this.config
  configs = data.apko_config.this.configs
}

resource "apko_publish" "this" {
  config_contents = data.apko_config.this.config_contents
  repo            = "ghcr.io/d4rkfella/bazarr"
  tags            = data.apko_tags.this.tags 
}

resource "cosign_sign" "this" {
  image = apko_publish.this.index_type == "" ? apko_publish.this.image_ref : apko_publish.this.index_ref
}

resource "cosign_attest" "this" {
  image = cosign_sign.this.signed_ref

  dynamic "predicates" {
    for_each = apko_build.this.sboms
    content {
      type = "https://spdx.dev/Document"
      file = {
        path   = predicates.value
        sha256 = filebase64sha256(predicates.value)
      }
    }
  }
}

output "sboms" {
  value       = apko_build.this.sboms
  description = "Map of architectures to their digests and SBOM paths."
}
