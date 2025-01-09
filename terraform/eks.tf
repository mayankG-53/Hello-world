module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.21"

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id     = "vpc-063f8b19542cbff63"
  subnet_ids = ["subnet-0dc77f5afb57c85bf", "subnet-084148df9d3bf7e81"]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}