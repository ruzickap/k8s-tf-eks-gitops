data "aws_eks_cluster" "eks-cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks-cluster" {
  name = module.eks.cluster_id
}

data "aws_route53_zone" "base_domain" {
  name = var.base_domain
}

data "aws_caller_identity" "current" {}
