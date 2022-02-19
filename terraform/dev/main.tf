terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.1.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.13.1"
    }
  }
  required_version = ">= 1.0.0"
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

  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = module.eks.cluster_id
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = module.eks.cluster_id
        user    = "terraform"
      }
    }]
    users = [{
      name = "terraform"
      user = {
        token = data.aws_eks_cluster_auth.eks-cluster.token
      }
    }]
  })
}

provider "aws" {
  # Default tags that will be applied to ALL resources: https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider
  default_tags {
    tags = local.aws_default_tags
  }
  region = var.aws_default_region
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks-cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.eks-cluster.name]
      command     = "aws"
    }
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.eks-cluster.name]
    command     = "aws"
  }
  load_config_file = false
}
