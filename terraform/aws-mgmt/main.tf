terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.57.1"
    }
    git = {
      source  = "innovationnorway/git"
      version = "0.1.3"
    }
    github = {
      source  = "integrations/github"
      version = "5.18.3"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.2.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.18.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.2.5"
}

locals {
  vpc_name                         = var.cluster_fqdn
  cluster_name                     = split(".", var.cluster_fqdn)[0]
  root_domain                      = regex(".*\\.([^.]+\\.\\w+)", var.cluster_fqdn)[0]
  crossplane_pkg_provider_aws_name = "aws-provider"

  # Merging tfvars file when running terraform is not possible therefore I'm doing it here
  # (https://stackoverflow.com/questions/64615552/merge-more-than-2-tfvars-file-contents)
  aws_default_tags = merge(
    var.aws_tags_group_level,
    var.aws_tags_cluster_level,
  )

  # Environment=dev,Team=test,Owner=aaaa
  tags_inline = join(",", [for key, value in local.aws_default_tags : "${key}=${value}"])
  # { Environment: dev, Team: test, Owner: aaaa }
  tags_yaml_flow_style = "{ ${join(", ", [for key, value in local.aws_default_tags : "${key}: ${value}"])} }"

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
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks-cluster.token
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks-cluster.token
  load_config_file       = false
}
