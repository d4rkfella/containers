variable "image_name" {}
variable "config_file" {}
variable "target_repository" {}

module "apko" {
  source            = "chainguard-dev/apko/publisher"
  version           = "0.0.18"
  config            = file(var.config_file)
  target_repository = var.target_repository
}

output "config" {
  value = module.apko.config
}

output "image_ref" {
  value = module.apko.image_ref
}
