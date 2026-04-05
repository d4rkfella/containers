terraform {
  required_providers {
    apko   = { source = "chainguard-dev/apko" }
    cosign = { source = "chainguard-dev/cosign" }
  }
}

provider "apko" {
  default_archs      = ["amd64", "arm64"]
  extra_keyring      = ["https://packages.darkfellanetwork.com/artifactory/wolfi-os/melange.rsa.pub"]
  build_repositories = ["https://packages.darkfellanetwork.com/artifactory/wolfi-os/latest/main"]
  extra_packages     = ["wolfi-baselayout"]
}