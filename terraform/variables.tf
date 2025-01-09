variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "my-eks-cluster"
}

variable "subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}
