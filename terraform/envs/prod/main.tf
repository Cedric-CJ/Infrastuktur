module "network" {
  source              = "../../modules/networking"
  project             = var.project
  env                 = var.env
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "security" {
  source     = "../../modules/security"
  project    = var.project
  env        = var.env
  vpc_id     = module.network.vpc_id
  admin_cidr = var.admin_cidr
}

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

module "alb" {
  source               = "../../modules/alb"
  project              = var.project
  env                  = var.env
  subnet_ids           = module.network.public_subnet_ids
  vpc_id               = module.network.vpc_id
  lb_security_group_id = module.security.lb_security_group_id
}

locals {
  video_url = "https://${module.site.bucket_name}.s3.${var.aws_region}.amazonaws.com/${var.video_object_key}"
}

module "compute" {
  source                 = "../../modules/autoscaling"
  project                = var.project
  env                    = var.env
  subnet_ids             = module.network.public_subnet_ids
  app_security_group_ids = [module.security.app_security_group_id]
  alb_target_group_arn   = module.alb.target_group_arn
  instance_type          = var.instance_type
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.desired_capacity
  key_name               = var.instance_key_name
  frontend_bucket        = module.site.bucket_name
  api_url                = module.api.api_base_url
  video_url              = local.video_url
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

output "load_balancer_dns" {
  value = module.alb.dns_name
}

output "autoscaling_group" {
  value = module.compute.autoscaling_group_name
}
