terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.73.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
  }
  required_version = ">= 1.0.0"
}

locals {
  vpc_name = var.cluster_fqdn
}

provider "aws" {
  # specify default tags that will be applied to ALL resources: https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider
  default_tags {
    tags = var.aws_default_tags
  }

  region = var.aws_default_region
}
