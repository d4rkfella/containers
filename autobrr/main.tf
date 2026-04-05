module "autobrr" {
  source            = "../modules/apko-image"
  image_name        = "autobrr"
  config_file       = "${path.module}/apko.yaml"
  target_repository = "ghcr.io/d4rkfella/autobrr"
}

data "apko_tags" "this" {
  config         = module.autobrr.config
  target_package = "autobrr"
}

resource "oci_tag" "this" {
  for_each   = toset(data.apko_tags.this.tags)
  digest_ref = module.autobrr.image_ref
  tag        = each.value
}
