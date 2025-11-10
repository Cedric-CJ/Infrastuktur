variable "api_id" {
  type        = string
  description = "API Gateway REST API identifier"
}

variable "lambdas" {
  type        = map(string)
  description = "Map of <METHOD PATH> to Lambda ARN"
}
