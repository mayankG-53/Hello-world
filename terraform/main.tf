provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_eks_cluster" "eks" {
  name     = "my-eks-cluster"
  role_arn = "arn:aws:iam::905418187826:user/eks-cluster-role"

  vpc_config {
    subnet_ids = aws_subnet.subnet[*].id
  }

  depends_on = [aws_vpc.main]
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"
  acl    = "private"
}

# Backend configuration (this should be in a separate file)
resource "aws_s3_bucket_object" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket
  key    = "terraform.tfstate"
  source = "terraform.tfstate"
}
