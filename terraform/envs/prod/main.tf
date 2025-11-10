module "site" {
  source              = "../../modules/s3_static_site"
  bucket_name_prefix  = "${var.project}-site-${var.env}"
  enable_website_host = true
}

module "ddb" {
  source      = "../../modules/dynamodb"
  project     = var.project
  env         = var.env
  ttl_enabled = true
}

module "iam" {
  source              = "../../modules/iam_lambda"
  project             = var.project
  env                 = var.env
  comments_table_arn  = module.ddb.comments_table_arn
  reactions_table_arn = module.ddb.reactions_table_arn
  logs_table_arn      = module.ddb.logs_table_arn
  users_table_arn     = module.ddb.users_table_arn
}

module "api" {
  source               = "../../modules/api_lambda"
  project              = var.project
  env                  = var.env
  lambda_role_arn      = module.iam.lambda_role_arn
  comments_table_name  = module.ddb.comments_table_name
  reactions_table_name = module.ddb.reactions_table_name
  logs_table_name      = module.ddb.logs_table_name
  users_table_name     = module.ddb.users_table_name
  jwt_secret           = var.jwt_secret
}

output "website_endpoint" {
  value = module.site.website_endpoint
}

output "api_base_url" {
  value = module.api.api_base_url
}

output "video_bucket" {
  value = module.site.bucket_name
}
