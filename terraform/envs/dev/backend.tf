terraform {
  backend "s3" {
    bucket         = "tf-state-streamflix-itinfra2025"
    key            = "streamflix/dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-locks-streamflix"
    encrypt        = true
  }
}
