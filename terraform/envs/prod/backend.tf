terraform {
  backend "s3" {
    bucket         = "tf-state-streamflix-itinfra2025"
    key            = "streamflix/prod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-locks-streamflix"
    encrypt        = true
  }
}
