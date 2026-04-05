terraform {
  required_providers {
    apko = {
      source  = "d4rkfella/apko"
      version = ">= 1.0.1"
    }
  }

  backend "s3" {
    bucket   = "terraform-state"
    region   = "auto"
    endpoints = {
      s3 = "https://2bd80478faceecf0d53c596cd910805f.r2.cloudflarestorage.com"
    }
    skip_credentials_validation  = true
    skip_metadata_api_check      = true
    skip_region_validation       = true
    skip_requesting_account_id   = true
    use_path_style               = true
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
  plan_offline       = true
}

data "apko_config" "this" {
  config_contents = file("${path.module}/apko.yaml")
  lock_file       = "${path.module}/apko.lock.json"
}

data "apko_tags" "this" {
  config         = data.apko_config.this.config
  target_package = "autobrr"
}

resource "apko_build" "this" {
  repo    = "ghcr.io/d4rkfella/autobrr"
  config  = data.apko_config.this.config
  configs = data.apko_config.this.configs
}
