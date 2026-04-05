terraform {
  required_providers {
    apko = { source = "d4rkfella/apko" }
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
    lock_file       = "${path.module}/apko.lock.json"
}

data "apko_tags" "this" {
  config         = data.apko_config.this.config
  target_package = "bazarr"
}

resource "apko_build" "this" {
  repo    = "ghcr.io/d4rkfella/bazarr"
  config  = data.apko_config.this.config
  configs = data.apko_config.this.configs
  archs  = ["amd64", "arm64"]
}

output "sboms" {
  value       = apko_build.this.sboms
  description = "Map of architectures to their digests and SBOM paths."
}