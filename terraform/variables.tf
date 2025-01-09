variable "region" {
  default = "us-west-2"
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
