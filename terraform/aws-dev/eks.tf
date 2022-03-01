# ---------------------------------------------------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.12.0"

  name = local.vpc_name
  cidr = var.aws_vpc_cidr

  azs             = ["${var.aws_default_region}a", "${var.aws_default_region}b", "${var.aws_default_region}c"]
  private_subnets = var.aws_private_subnets
  public_subnets  = var.aws_public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
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
  name          = "alias/${local.cluster_name}"
  target_key_id = aws_kms_key.eks-kms_key.key_id
}

# ---------------------------------------------------------------------------------------------------------------------
# Route 53
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route53_zone" "cluster_fqdn" {
  name    = var.cluster_fqdn
  comment = "Managed by ${local.aws_default_tags.owner}"
}

resource "aws_route53_record" "base_domain" {
  zone_id = data.aws_route53_zone.base_domain.zone_id
  name    = aws_route53_zone.cluster_fqdn.name
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.cluster_fqdn.name_servers
}

# ---------------------------------------------------------------------------------------------------------------------
# Create the EKS cluster
# ---------------------------------------------------------------------------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.7.2"

  cluster_name                    = local.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks-kms_key.arn
    resources        = ["secrets"]
  }]

  cluster_addons = {
    coredns = {
      addon_version     = "v1.8.4-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      addon_version     = "v1.21.2-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      addon_version     = "v1.10.2-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      addon_version     = "v1.4.0-eksbuild.preview"
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cluster_enabled_log_types              = var.cluster_enabled_log_types

  eks_managed_node_group_defaults = {
    iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  }

  eks_managed_node_groups = var.eks_managed_node_groups

  tags = merge(local.aws_default_tags, { Name = local.cluster_name })
}

resource "null_resource" "patch" {
  triggers = {
    kubeconfig = base64encode(local.kubeconfig)
    cmd_patch  = "kubectl patch configmap/aws-auth --patch \"${local.aws_auth_configmap_yaml}\" -n kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
    command = self.triggers.cmd_patch
  }
}
