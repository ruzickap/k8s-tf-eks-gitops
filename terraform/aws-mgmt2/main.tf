terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.9.0"
    }
    git = {
      source  = "innovationnorway/git"
      version = "0.1.3"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.10.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.3.0"
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

  flux_install = [for v in data.kubectl_file_documents.install.documents : {
    data : yamldecode(v)
    content : v
    }
  ]

  flux_sync = [for v in data.kubectl_file_documents.sync.documents : {
    data : yamldecode(v)
    content : v
    }
  ]

  known_hosts = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
}

provider "aws" {
  # Default tags that will be applied to ALL resources: https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider
  # Not working: Provider produced inconsistent final plan
  # default_tags {
  #   tags = local.aws_default_tags
  # }
  region = var.aws_default_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks-cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks-cluster.token
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.eks-cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks-cluster.token
  load_config_file       = false
}
