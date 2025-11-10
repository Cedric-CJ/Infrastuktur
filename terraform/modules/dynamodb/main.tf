locals {
  prefix = "${var.project}-${var.env}"
}

resource "aws_dynamodb_table" "users" {
  name         = "${local.prefix}-users_auth"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "comments" {
  name         = "${local.prefix}-comments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "content_id"
  range_key    = "comment_id"

  attribute {
    name = "content_id"
    type = "S"
  }

  attribute {
    name = "comment_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "reactions" {
  name         = "${local.prefix}-reactions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "content_id"
  range_key    = "user_id"

  attribute {
    name = "content_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "logs" {
  name         = "${local.prefix}-logs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "log_date"
  range_key    = "log_id"

  attribute {
    name = "log_date"
    type = "S"
  }

  attribute {
    name = "log_id"
    type = "S"
  }

  ttl {
    enabled        = var.ttl_enabled
    attribute_name = "ttl"
  }
}
