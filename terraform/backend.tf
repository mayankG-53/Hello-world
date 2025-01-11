terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"  # Same as the bucket name in your resource
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}
