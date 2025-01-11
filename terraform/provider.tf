provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket         = var.s3_bucket
    key            = "terraform/state"
    region         = var.region
    encrypt        = true
    dynamodb_table = var.dynamodb_table
  }
}
