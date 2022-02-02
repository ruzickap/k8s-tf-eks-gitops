# ---------------------------------------------------------------------------------------------------------------------
# CloudWatch - log group
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  kms_key_id        = aws_kms_key.eks-kms_key.key_id
  retention_in_days = 1
}

# ---------------------------------------------------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.3"

  name = local.vpc_name
  cidr = var.aws_vpc_cidr

  azs             = ["${var.aws_default_region}a", "${var.aws_default_region}b", "${var.aws_default_region}c"]
  private_subnets = var.aws_private_subnets
  public_subnets  = var.aws_public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Create the cluster's KMS key
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_kms_key" "eks-kms_key" {
  description             = "${var.cluster_fqdn} Amazon EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}"
  target_key_id = aws_kms_key.eks-kms_key.key_id
}
