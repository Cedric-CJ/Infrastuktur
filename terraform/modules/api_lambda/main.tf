locals {
  name = "${var.project}-${var.env}"
}

data "archive_file" "auth_signup" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/auth_signup"
  output_path = "${path.module}/../../../lambdas/auth_signup/function.zip"
}

data "archive_file" "auth_login" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/auth_login"
  output_path = "${path.module}/../../../lambdas/auth_login/function.zip"
}

data "archive_file" "comments_write" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/comments_write"
  output_path = "${path.module}/../../../lambdas/comments_write/function.zip"
}

data "archive_file" "reactions_write" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/reactions_write"
  output_path = "${path.module}/../../../lambdas/reactions_write/function.zip"
}

resource "aws_lambda_function" "auth_signup" {
  function_name = "${local.name}-auth-signup"
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.auth_signup.output_path
  source_code_hash = data.archive_file.auth_signup.output_base64sha256

  # Free Tier Optimization
  memory_size = 128  # Minimum for Free Tier
  timeout     = 30   # 30 seconds max

  environment {
    variables = {
      USERS_TABLE = var.users_table_name
    }
  }
}

resource "aws_lambda_function" "auth_login" {
  function_name = "${local.name}-auth-login"
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.auth_login.output_path
  source_code_hash = data.archive_file.auth_login.output_base64sha256

  # Free Tier Optimization
  memory_size = 128  # Minimum for Free Tier
  timeout     = 30   # 30 seconds max

  environment {
    variables = {
      USERS_TABLE = var.users_table_name
      JWT_SECRET  = var.jwt_secret
    }
  }
}

resource "aws_lambda_function" "comments_write" {
  function_name = "${local.name}-comments-write"
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.comments_write.output_path
  source_code_hash = data.archive_file.comments_write.output_base64sha256

  # Free Tier Optimization
  memory_size = 128  # Minimum for Free Tier
  timeout     = 30   # 30 seconds max

  environment {
    variables = {
      COMMENTS_TABLE = var.comments_table_name
      LOGS_TABLE     = var.logs_table_name
      JWT_SECRET     = var.jwt_secret
    }
  }
}

resource "aws_lambda_function" "reactions_write" {
  function_name = "${local.name}-reactions-write"
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.reactions_write.output_path
  source_code_hash = data.archive_file.reactions_write.output_base64sha256

  # Free Tier Optimization
  memory_size = 128  # Minimum for Free Tier
  timeout     = 30   # 30 seconds max

  environment {
    variables = {
      REACTIONS_TABLE = var.reactions_table_name
      LOGS_TABLE      = var.logs_table_name
      JWT_SECRET      = var.jwt_secret
    }
  }
}

resource "aws_api_gateway_rest_api" "this" {
  name = "${local.name}-api"
}

module "routes" {
  source = "./routes"
  api_id = aws_api_gateway_rest_api.this.id
  lambdas = {
    "POST /auth/signup" = aws_lambda_function.auth_signup.arn,
    "POST /auth/login"  = aws_lambda_function.auth_login.arn,
    "POST /comments"    = aws_lambda_function.comments_write.arn,
    "POST /reactions"   = aws_lambda_function.reactions_write.arn
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeploy = sha1(jsonencode(module.routes.integrations))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.env
}
