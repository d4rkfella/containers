terraform {
  required_providers {
    apko = { source = "chainguard-dev/apko" }
    oci = { source = "chainguard-dev/oci"}
  }
  backend "s3" {}
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

module "apko" {
  source  = "chainguard-dev/apko/publisher"
  config = file("${path.module}/apko.yaml")
  target_repository = "ghcr.io/d4rkfella/${basename(abspath(path.module))}"
}

data "apko_tags" "this" {
  config         = module.apko.config
  target_package = "vaultwarden"
}

resource "oci_tag" "this" {
  for_each   = toset(data.apko_tags.this.tags)
  digest_ref = module.apko.image_ref
  tag        = each.value
}
