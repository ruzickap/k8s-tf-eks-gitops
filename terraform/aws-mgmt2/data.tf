data "aws_eks_cluster" "eks-cluster" {
  name = module.aws_eks_accelerator_for_terraform.eks_cluster_id
}

data "aws_eks_cluster_auth" "eks-cluster" {
  name = module.aws_eks_accelerator_for_terraform.eks_cluster_id
}

data "aws_route53_zone" "base_domain" {
  name = var.base_domain
}

data "aws_caller_identity" "current" {}

data "http" "argo-cd_core-install" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/v2.3.2/manifests/core-install.yaml"
}

data "kubectl_file_documents" "argo-cd_core-install" {
  content = data.http.argo-cd_core-install.body
}
