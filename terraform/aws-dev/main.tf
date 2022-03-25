terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.7.0"
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

  aws_auth_configmap_yaml = <<-EOT
${chomp(module.eks.aws_auth_configmap_yaml)}
${var.eks_aws_auth_configmap}
  EOT
}

provider "aws" {
  # Default tags that will be applied to ALL resources: https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider
  default_tags {
    tags = local.aws_default_tags
  }
  region = var.aws_default_region
}
