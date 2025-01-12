output "cluster_name" {
  value = aws_eks_cluster.my_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.my_cluster.endpoint
}

output "cluster_arn" {
  value = aws_eks_cluster.my_cluster.arn
}

output "vpc_id" {
  value = aws_vpc.main.id
}
