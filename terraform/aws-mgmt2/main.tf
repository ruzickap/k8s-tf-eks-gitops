terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.8.0"
    }
  }
  required_version = ">= 1.0.1"
}

locals {
  vpc_name     = var.cluster_fqdn
  cluster_name = split(".", var.cluster_fqdn)[0]

  # Merging tfvars file when running terraform is not possible therefore I'm doing it here
  # (https://stackoverflow.com/questions/64615552/merge-more-than-2-tfvars-file-contents)
  aws_default_tags = merge(
    var.aws_tags_group_level,
    var.aws_tags_cluster_level,
  )
}

provider "aws" {
  # Default tags that will be applied to ALL resources: https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider
  # Not working: Provider produced inconsistent final plan
  # default_tags {
  #   tags = local.aws_default_tags
  # }
  region = var.aws_default_region
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks-cluster.endpoint
    token                  = data.aws_eks_cluster_auth.eks-cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority.0.data)
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks-cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks-cluster.token
}
