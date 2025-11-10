data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_api_gateway_rest_api" "api" {
  rest_api_id = var.api_id
}

locals {
  parsed = { for key, arn in var.lambdas :
    key => {
      method = upper(split(key, " ")[0])
      path   = length(split(key, " ")) > 1 ? split(key, " ")[1] : "/"
      arn    = arn
    }
  }

  normalized_paths = distinct([for route in local.parsed : route.path == "" ? "/" : route.path])

  segments_by_path = {
    for path in local.normalized_paths :
    path => path == "/" ? [] : split(trim(path, "/"), "/")
  }

  expanded_paths = distinct(flatten([
    [
      "/" + join("/", slice(local.segments_by_path[path], 0, i + 1))
      for i in range(length(local.segments_by_path[path]))
    ]
    for path in keys(local.segments_by_path)
    if length(local.segments_by_path[path]) > 0
  ]))

  resource_map = {
    for full_path in local.expanded_paths :
    full_path => {
      parent = length(split(trim(full_path, "/"), "/")) == 1 ? "/" : "/" + join("/", slice(split(trim(full_path, "/"), "/"), 0, length(split(trim(full_path, "/"), "/")) - 1))
      part   = element(reverse(split(trim(full_path, "/"), "/")), 0)
    }
  }
}

resource "aws_api_gateway_resource" "paths" {
  for_each   = local.resource_map
  rest_api_id = var.api_id
  parent_id   = each.value.parent == "/" ? data.aws_api_gateway_rest_api.api.root_resource_id : aws_api_gateway_resource.paths[each.value.parent].id
  path_part   = each.value.part
}

resource "aws_api_gateway_method" "this" {
  for_each    = local.parsed
  rest_api_id = var.api_id
  resource_id = each.value.path == "/" ? data.aws_api_gateway_rest_api.api.root_resource_id : aws_api_gateway_resource.paths[each.value.path].id
  http_method = each.value.method

  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this" {
  for_each                = aws_api_gateway_method.this
  rest_api_id             = var.api_id
  resource_id             = each.value.resource_id
  http_method             = each.value.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${local.parsed[each.key].arn}/invocations"
}

resource "aws_lambda_permission" "apigw" {
  for_each      = local.parsed
  statement_id  = "AllowAPIGateway${each.value.method}${replace(each.value.path, "/", "_")}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/${each.value.method}${each.value.path == "/" ? "/" : each.value.path}"
}
