terraform {
  required_providers {
    apko   = { source = "chainguard-dev/apko" }
    cosign = { source = "chainguard-dev/cosign" }
    oci    = { source = "chainguard-dev/oci" }
  }
  backend "s3" {
    key = "bazarr/terraform.tfstate"
  }
}

provider "apko" {
  default_archs      = ["amd64", "arm64"]
  extra_keyring = [
    "https://packages.darkfellanetwork.com/artifactory/wolfi-os/melange.rsa.pub"
  ]
  build_repositories = ["https://packages.darkfellanetwork.com/artifactory/wolfi-os/latest/main"]
  extra_packages     = ["wolfi-baselayout"]
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

locals {
  archs = toset(concat(["index"], data.apko_config.this.config.archs))
}

resource "cosign_sign" "this" {
  for_each = local.archs
  image    = apko_build.this.sboms[each.key].digest
  conflict = "REPLACE"
}

resource "cosign_attest" "sbom" {
  for_each = local.archs
  image    = cosign_sign.this[each.key].signed_ref

  predicates {
    type = "https://spdx.dev/Document"
    file = {
      path   = apko_build.this.sboms[each.key].predicate_path
      sha256 = apko_build.this.sboms[each.key].predicate_sha256
    }
  }
}

resource "oci_tag" "this" {
  for_each   = toset(data.apko_tags.this.tags)
  digest_ref = apko_build.this.image_ref
  tag        = each.value
}

output "image_ref" {
  value       = apko_build.this.image_ref
  description = "The fully-qualified index digest."
}

output "arch_digests" {
  value = {
    for arch, sbom in apko_build.this.sboms : arch => "${sbom.digest}"
  }
  description = "Map of architecture to fully-qualified digest ref, including index."
}

output "image_tags" {
  value       = data.apko_tags.this.tags
  description = "Tags derived from the bazarr package version."
}
