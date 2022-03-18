output "amazon_eks_kubectl_commands" {
  value = <<EOF
  export KUBECONFIG="/tmp/kubeconfig-${local.cluster_name}.conf"
  aws eks update-kubeconfig --region ${var.aws_default_region} --name "${local.cluster_name}" --kubeconfig "$KUBECONFIG"
  kubectl get nodes
  EOF
}

output "eks_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.aws-eks-accelerator-for-terraform.eks_oidc_issuer_url
}

output "eks_oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`."
  value       = module.aws-eks-accelerator-for-terraform.eks_oidc_provider_arn
}

output "eks_cluster_id" {
  description = "Kubernetes Cluster Name"
  value       = module.aws-eks-accelerator-for-terraform.eks_cluster_id
}