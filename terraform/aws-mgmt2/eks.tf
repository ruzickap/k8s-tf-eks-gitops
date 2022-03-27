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

  tags = local.aws_default_tags
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

module "aws_eks_accelerator_for_terraform" {
  source = "github.com/aws-samples/aws-eks-accelerator-for-terraform?ref=v4.0.0"

  tenant      = var.tenant
  environment = var.environment
  zone        = var.zone

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  # EKS CONTROL PLANE VARIABLES
  cluster_version = var.cluster_version
  cluster_name    = local.cluster_name

  cloudwatch_log_group_retention_in_days  = var.cloudwatch_log_group_retention_in_days
  cluster_enabled_log_types               = var.cluster_enabled_log_types
  cluster_endpoint_private_access         = var.cluster_endpoint_private_access
  cluster_endpoint_public_access          = var.cluster_endpoint_public_access
  cluster_kms_key_deletion_window_in_days = var.cluster_kms_key_deletion_window_in_days

  map_roles = var.map_roles
  map_users = var.map_users

  tags = local.aws_default_tags

  # EKS MANAGED NODE GROUPS
  managed_node_groups = var.managed_node_groups
}

# ---------------------------------------------------------------------------------------------------------------------
# IRSA
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_policy" "external_dns" {
  name        = "${module.aws_eks_accelerator_for_terraform.eks_cluster_id}-external-dns"
  description = "Policy allowing external-dns to change Route53 entries"
  tags        = local.aws_default_tags
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/${aws_route53_zone.cluster_fqdn.zone_id}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

module "iam_assumable_role_external_dns" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.14.0"
  create_role                   = true
  provider_url                  = module.aws_eks_accelerator_for_terraform.eks_oidc_issuer_url
  role_name                     = "${module.aws_eks_accelerator_for_terraform.eks_cluster_id}-iamserviceaccount-external-dns"
  role_description              = "Allow external-dns to change Route53 entries"
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:external-dns:external-dns"]
}

resource "aws_iam_policy" "cert_manager" {
  name        = "${module.aws_eks_accelerator_for_terraform.eks_cluster_id}-cert-manager"
  description = "Policy allowing external-dns to change Route53 entries"
  tags        = local.aws_default_tags
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/${aws_route53_zone.cluster_fqdn.zone_id}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/${aws_route53_zone.cluster_fqdn.zone_id}"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    }
  ]
}
EOF
}

module "iam_assumable_role_cert_manager" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.14.0"
  create_role                   = true
  provider_url                  = module.aws_eks_accelerator_for_terraform.eks_oidc_issuer_url
  role_name                     = "${module.aws_eks_accelerator_for_terraform.eks_cluster_id}-iamserviceaccount-cert-manager"
  role_description              = "Allow cert-manager to change Route53 entries"
  role_policy_arns              = [aws_iam_policy.cert_manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:cert-manager:cert-manager"]
}

# ---------------------------------------------------------------------------------------------------------------------
# Argo CD
# ---------------------------------------------------------------------------------------------------------------------

resource "helm_release" "argocd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argo-cd_version
  namespace        = "argocd"
  create_namespace = true

  values = [
    templatefile("templates/argocd-values.yaml", {
      test = "test"
    })
  ]

  # Install argo-cd and ignore any future changes - no further changes are made to the release
  # It is only used for the initial ArgoCD deployment...
  # ArgoCD application is deployed and you're able to manage ArgoCD from ArgoCD.
  # https://registry.terraform.io/modules/lablabs/argocd/helm/latest
  lifecycle {
    ignore_changes = all
  }
}
