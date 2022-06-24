# ---------------------------------------------------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

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

module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.2.0"

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

  managed_node_groups = var.managed_node_groups
}

# ---------------------------------------------------------------------------------------------------------------------
# IRSA
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_policy" "cert_manager" {
  name        = "${module.eks_blueprints.eks_cluster_id}-cert-manager"
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
  version                       = "5.1.0"
  create_role                   = true
  provider_url                  = module.eks_blueprints.eks_oidc_issuer_url
  role_name                     = "${module.eks_blueprints.eks_cluster_id}-iamserviceaccount-cert-manager"
  role_description              = "Allow cert-manager to change Route53 entries"
  role_policy_arns              = [aws_iam_policy.cert_manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:cert-manager:cert-manager"]
}

resource "aws_iam_policy" "external_dns" {
  name        = "${module.eks_blueprints.eks_cluster_id}-external-dns"
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
  version                       = "5.1.0"
  create_role                   = true
  provider_url                  = module.eks_blueprints.eks_oidc_issuer_url
  role_name                     = "${module.eks_blueprints.eks_cluster_id}-iamserviceaccount-external-dns"
  role_description              = "Allow external-dns to change Route53 entries"
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:external-dns:external-dns"]
}

# ---------------------------------------------------------------------------------------------------------------------
# Argo CD
# ---------------------------------------------------------------------------------------------------------------------

resource "kubectl_manifest" "argo-cd_namespace" {
  wait       = true
  apply_only = true
  yaml_body  = file("templates/argo-cd_namespace.yaml")
}

resource "kubectl_manifest" "argo-cd_core-install" {
  depends_on         = [kubectl_manifest.argo-cd_namespace]
  for_each           = data.kubectl_file_documents.argo-cd_core-install.manifests
  apply_only         = true
  wait               = true
  override_namespace = "argocd"
  yaml_body          = each.value

  lifecycle {
    ignore_changes = all
  }
}

resource "kubectl_manifest" "argo-cd_appproject" {
  depends_on = [kubectl_manifest.argo-cd_core-install]
  wait       = true
  apply_only = true
  yaml_body  = file("templates/argo-cd_appproject.yaml")

  lifecycle {
    ignore_changes = all
  }
}

# This App is going to https://github.com/ruzickap/k8s-tf-eks-gitops / ${var.cluster_path}/argocd
resource "kubectl_manifest" "argo-cd_application" {
  count      = var.gitops == "argocd" ? 1 : 0
  depends_on = [kubectl_manifest.argo-cd_appproject]
  wait       = true
  apply_only = true
  yaml_body = templatefile("templates/argo-cd_application.yaml", {
    path           = "${var.cluster_path}/argocd"
    targetRevision = data.git_repository.current_git_repository.branch
  })

  lifecycle {
    ignore_changes = all
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Flux
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "main" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "main" {
  title      = var.cluster_fqdn
  repository = join("", regex(".*/([^.]*)", data.git_repository.current_git_repository.url))
  key        = tls_private_key.main.public_key_openssh
  read_only  = true
}

# Problems with terraform destroy: https://github.com/fluxcd/terraform-provider-flux/issues/67
resource "kubectl_manifest" "flux_namespace" {
  wait       = true
  apply_only = true
  yaml_body  = file("templates/flux_namespace.yaml")
}

resource "kubernetes_config_map" "cluster-apps-vars-terraform" {
  depends_on = [kubectl_manifest.flux_namespace]
  metadata {
    name      = "cluster-apps-vars-terraform"
    namespace = "flux-system"
  }

  data = {
    CLUSTER_FQDN = var.cluster_fqdn
    CLUSTER_NAME = local.cluster_name
    CLUSTER_PATH = var.cluster_path
    EMAIL        = var.email
    ENVIRONMENT  = var.environment
    # Environment=dev,Team=test
    TAGS_INLINE = local.tags_inline
  }
}

resource "kubernetes_secret" "flux" {
  depends_on = [kubectl_manifest.flux_namespace]

  metadata {
    name      = "flux-system"
    namespace = "flux-system"
  }

  data = {
    identity       = tls_private_key.main.private_key_pem
    "identity.pub" = tls_private_key.main.public_key_pem
    known_hosts    = local.known_hosts
  }
}

resource "kubectl_manifest" "install" {
  for_each   = { for v in local.flux_install : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
  depends_on = [kubernetes_secret.flux]
  yaml_body  = each.value
}

resource "kubectl_manifest" "sync" {
  for_each   = { for v in local.flux_sync : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content if var.gitops == "flux" }
  depends_on = [kubectl_manifest.install]
  yaml_body  = each.value
}
