output "kubeconfig" {
  value = aws_eks_cluster.main.endpoint
}
