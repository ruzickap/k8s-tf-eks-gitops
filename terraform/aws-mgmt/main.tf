terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.34.0"
    }
    git = {
      source  = "innovationnorway/git"
      version = "0.1.3"
    }
    github = {
      source  = "integrations/github"
      version = "5.5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.1.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.14.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.3"
    }
  }
  required_version = ">= 1.2.5"
}

locals {
  vpc_name     = var.cluster_fqdn
  cluster_name = split(".", var.cluster_fqdn)[0]
  root_domain  = regex(".*\\.([^.]+\\.\\w+)", var.cluster_fqdn)[0]

  # Merging tfvars file when running terraform is not possible therefore I'm doing it here
  # (https://stackoverflow.com/questions/64615552/merge-more-than-2-tfvars-file-contents)
  aws_default_tags = merge(
    var.aws_tags_group_level,
    var.aws_tags_cluster_level,
  )

  # Environment=dev,Team=test,Owner=aaaa
  tags_inline = join(",", [for key, value in local.aws_default_tags : "${key}=${value}"])

  flux_install = [for v in data.kubectl_file_documents.flux_install.documents : {
    data : yamldecode(v)
    content : v
    }
  ]

  flux_sync = [for v in data.kubectl_file_documents.flux_sync.documents : {
    data : yamldecode(v)
    content : v
    }
  ]

  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = module.eks_blueprints.eks_cluster_id
      cluster = {
        certificate-authority-data = data.aws_eks_cluster.eks-cluster.certificate_authority[0].data
        server                     = data.aws_eks_cluster.eks-cluster.endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = module.eks_blueprints.eks_cluster_id
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

provider "github" {
  token = var.github_token
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks-cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks-cluster.token
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.eks-cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks-cluster.token
  load_config_file       = false
}
