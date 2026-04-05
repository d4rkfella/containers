module "bazarr" {
  source            = "../modules/apko-image"
  image_name        = "bazarr"
  config_file       = "${path.module}/apko.yaml"
  target_repository = "ghcr.io/d4rkfella/bazarr"
}

data "apko_tags" "this" {
  config         = module.bazarr.config
  target_package = "bazarr"
}

resource "oci_tag" "this" {
  for_each   = toset(data.apko_tags.this.tags)
  digest_ref = module.bazarr.image_ref
  tag        = each.value
}
