output "amazon_eks_kubectl_commands" {
  description = "kubectl commands"
  value       = <<EOF
  export KUBECONFIG="/tmp/kubeconfig-${local.cluster_name}.conf"
  eval "$(aws sts assume-role --role-arn "${var.aws_assume_role}" --role-session-name "$USER@$(hostname -f)-k8s-tf-eks-argocd-$(date +%s)" --duration-seconds 36000 | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)\n"')"
  aws eks update-kubeconfig --region "${var.aws_default_region}" --name "${local.cluster_name}" --kubeconfig "$KUBECONFIG"
  kubectl get nodes
  EOF
}

output "eks_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks_blueprints.eks_oidc_issuer_url
}

output "eks_oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`."
  value       = module.eks_blueprints.eks_oidc_provider_arn
}

output "eks_cluster_id" {
  description = "Kubernetes Cluster Name"
  value       = module.eks_blueprints.eks_cluster_id
}
