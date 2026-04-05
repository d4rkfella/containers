module "apko" {
  source  = "chainguard-dev/apko/publisher"
  version = "0.0.18"
  config = file("${path.module}/apko.yaml")
  target_repository = "ghcr.io/d4rkfella/bazarr"
}

data "apko_tags" "this" {
  config         = module.apko.config
  target_package = "bazarr"
}

resource "oci_tag" "this" {
  for_each   = toset(data.apko_tags.this.tags)
  digest_ref = module.apko.image_ref
  tag        = each.value
}
