module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name                 = var.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = var.availability_zones
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
}
