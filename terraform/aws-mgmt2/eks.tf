# ---------------------------------------------------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = local.vpc_name
  cidr = var.aws_vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
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
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.6.1"

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

# module "eks_blueprints_kubernetes_addons" {
#   source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.6.0"

#   eks_cluster_id       = module.eks_blueprints.eks_cluster_id
#   eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
#   eks_oidc_provider    = module.eks_blueprints.oidc_provider
#   eks_cluster_version  = module.eks_blueprints.eks_cluster_version

#   # EKS Managed Add-ons
#   enable_amazon_eks_vpc_cni = true
#   amazon_eks_vpc_cni_config = {
#     addon_name        = "vpc-cni"
#     addon_version     = "v1.11.2-eksbuild.1"
#     resolve_conflicts = "OVERWRITE"
#   }
#   enable_amazon_eks_coredns = true
#   amazon_eks_coredns_config = {
#     addon_name        = "coredns"
#     addon_version     = "v1.8.7-eksbuild.1"
#     resolve_conflicts = "OVERWRITE"
#   }
#   enable_amazon_eks_kube_proxy = true
#   amazon_eks_kube_proxy_config = {
#     addon_name        = "kube-proxy"
#     addon_version     = "v1.22.6-eksbuild.1"
#     resolve_conflicts = "OVERWRITE"
#   }
#   enable_amazon_eks_aws_ebs_csi_driver = true
#   amazon_eks_aws_ebs_csi_driver_config = {
#     addon_name        = "aws-ebs-csi-driver"
#     addon_version     = "v1.8.0-eksbuild.0"
#     resolve_conflicts = "OVERWRITE"
#   }

#   tags = local.aws_default_tags
# }

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
      "Resource": "arn:${data.aws_partition.current.id}:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:${data.aws_partition.current.id}:route53:::hostedzone/${aws_route53_zone.cluster_fqdn.zone_id}"
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
  version                       = "5.3.0"
  create_role                   = true
  provider_url                  = module.eks_blueprints.eks_oidc_issuer_url
  role_name                     = "${module.eks_blueprints.eks_cluster_id}-irsa-cert-manager"
  role_description              = "Allow cert-manager to change Route53 entries"
  role_policy_arns              = [aws_iam_policy.cert_manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:cert-manager:cert-manager"]
}

resource "aws_iam_policy" "cnpg_db01" {
  name        = "${module.eks_blueprints.eks_cluster_id}-cnpg-db01"
  description = "Policy allowing cnpg-db01 to access S3"
  tags        = local.aws_default_tags
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectTagging"
      ],
      "Resource": [
        "arn:${data.aws_partition.current.id}:s3:::${var.cluster_fqdn}",
        "arn:${data.aws_partition.current.id}:s3:::${var.cluster_fqdn}/*"
      ]
    }
  ]
}
  EOF
}

module "iam_assumable_role_cnpg_db01" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.3.0"
  create_role                   = true
  provider_url                  = module.eks_blueprints.eks_oidc_issuer_url
  role_name                     = "${module.eks_blueprints.eks_cluster_id}-irsa-cnpg-db01"
  role_description              = "Allow cnpg-db01 to access S3 bucket"
  role_policy_arns              = [aws_iam_policy.velero_server.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:cnpg-db01:cnpg-db01"]
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
        "arn:${data.aws_partition.current.id}:route53:::hostedzone/${aws_route53_zone.cluster_fqdn.zone_id}"
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
  version                       = "5.3.0"
  create_role                   = true
  provider_url                  = module.eks_blueprints.eks_oidc_issuer_url
  role_name                     = "${module.eks_blueprints.eks_cluster_id}-irsa-external-dns"
  role_description              = "Allow external-dns to change Route53 entries"
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:external-dns:external-dns"]
}

resource "aws_iam_policy" "kuard" {
  name        = "${module.eks_blueprints.eks_cluster_id}-kuard"
  description = "Policy allowing kuard to access secrtes in SecretManager"
  tags        = local.aws_default_tags
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:${data.aws_partition.current.id}:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "${data.aws_kms_alias.kms_secretmanager.arn}"
      ],
      "Condition": {
        "StringLike": {
          "kms:ViaService": [
            "secretsmanager.*.amazonaws.com"
          ]
        }
      }
    }
  ]
}
  EOF
}

module "iam_assumable_role_kuard" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.3.0"
  create_role                   = true
  provider_url                  = module.eks_blueprints.eks_oidc_issuer_url
  role_name                     = "${module.eks_blueprints.eks_cluster_id}-irsa-kuard"
  role_description              = "Allow kuard to access secrtes in SecretManager"
  role_policy_arns              = [aws_iam_policy.kuard.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kuard:kuard"]
}

resource "aws_iam_policy" "kustomize_controller" {
  name        = "${module.eks_blueprints.eks_cluster_id}-kustomize-controller"
  description = "Policy allowing Flux kustomize-controller to access KMS"
  tags        = local.aws_default_tags
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": [
        "${var.flux_kustomize_controller_kms_key_arn}"
      ]
    }
  ]
}
  EOF
}

# Role created by this module must be in stored in git in clusters/aws-dev-mgmt2/<cluster_name>/flux/flux-system/kustomization.yaml
module "iam_assumable_role_kustomize_controller" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.3.0"
  create_role                   = true
  provider_url                  = module.eks_blueprints.eks_oidc_issuer_url
  role_name                     = "${module.eks_blueprints.eks_cluster_id}-irsa-kustomize-controller"
  role_description              = "Allow Flux kustomize-controller to access KMS"
  role_policy_arns              = [aws_iam_policy.kustomize_controller.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:flux-system:kustomize-controller"]
}

# https://aws.github.io/aws-eks-best-practices/cluster-autoscaling/#employ-least-privileged-access-to-the-iam-role
resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${module.eks_blueprints.eks_cluster_id}-cluster-autoscaler"
  description = "Policy allowing cluster-autoscaler to interact with the autoscaling groups"
  tags        = local.aws_default_tags
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled": "true",
          "aws:ResourceTag/k8s.io/cluster-autoscaler/${local.cluster_name}": "owned"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": "*"
    }
  ]
}
  EOF
}

# Role created by this module must be in stored in git in clusters/aws-dev-mgmt2/<cluster_name>/flux/flux-system/kustomization.yaml
module "iam_assumable_role_cluster_autoscaler" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.3.0"
  create_role                   = true
  provider_url                  = module.eks_blueprints.eks_oidc_issuer_url
  role_name                     = "${module.eks_blueprints.eks_cluster_id}-irsa-cluster-autoscaler"
  role_description              = "Allow cluster-autoscaler to interact with the autoscaling groups"
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:cluster-autoscaler:cluster-autoscaler"]
}


resource "aws_iam_policy" "velero_server" {
  name        = "${module.eks_blueprints.eks_cluster_id}-velero-server"
  description = "Policy allowing Velero to access S3"
  tags        = local.aws_default_tags
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole",
        "ec2:DescribeVolumes",
        "ec2:DescribeSnapshots",
        "ec2:DeleteSnapshot",
        "ec2:CreateVolume",
        "ec2:CreateTags",
        "ec2:CreateSnapshot"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:${data.aws_partition.current.id}:s3:::${var.cluster_fqdn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
      "Resource": [
        "arn:${data.aws_partition.current.id}:s3:::${var.cluster_fqdn}/*"
      ]
    }
  ]
}
  EOF
}

module "iam_assumable_role_velero_server" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.3.0"
  create_role                   = true
  provider_url                  = module.eks_blueprints.eks_oidc_issuer_url
  role_name                     = "${module.eks_blueprints.eks_cluster_id}-irsa-velero-server"
  role_description              = "Allow velero to access S3 bucket"
  role_policy_arns              = [aws_iam_policy.velero_server.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:velero:velero-server"]
}

# ---------------------------------------------------------------------------------------------------------------------
# Argo CD
# ---------------------------------------------------------------------------------------------------------------------

resource "kubectl_manifest" "argo-cd_namespace" {
  wait       = true
  apply_only = true
  yaml_body  = <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
  EOF
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

resource "tls_private_key" "flux_private_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "flux_github_key" {
  title      = var.cluster_fqdn
  repository = join("", regex(".*/([^.]*)", data.git_repository.current_git_repository.url))
  key        = tls_private_key.flux_private_key.public_key_openssh
  read_only  = true
}

# Problems with terraform destroy: https://github.com/fluxcd/terraform-provider-flux/issues/67
resource "kubectl_manifest" "flux_namespace" {
  depends_on = [kubectl_manifest.flux_namespace]
  wait       = true
  apply_only = true
  yaml_body  = <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: flux-system
  EOF
}

resource "kubernetes_secret" "flux_cluster_apps_terraform_secret" {
  depends_on = [kubectl_manifest.flux_namespace]
  metadata {
    name      = "cluster-apps-vars-terraform-secret"
    namespace = "flux-system"
  }

  data = {
    AWS_ACCOUNT_ID              = data.aws_caller_identity.current.account_id
    AWS_DEFAULT_REGION          = var.aws_default_region
    AWS_PARTITION               = data.aws_partition.current.id
    CLUSTER_FQDN                = var.cluster_fqdn
    CLUSTER_NAME                = local.cluster_name
    CLUSTER_PATH                = var.cluster_path
    EMAIL                       = var.email
    ENVIRONMENT                 = var.environment
    GITHUB_WEBHOOK_TOKEN_BASE64 = base64encode(random_id.github_webhook_flux_secret.hex)
    LETSENCRYPT_ENVIRONMENT     = var.letsencrypt_environment
    SLACK_CHANNEL               = var.slack_channel
    # Environment=dev,Team=test
    TAGS_INLINE = local.tags_inline
  }
}

resource "kubernetes_secret" "flux_github_keys" {
  depends_on = [kubectl_manifest.flux_namespace]

  metadata {
    name      = "flux-system"
    namespace = "flux-system"
  }

  data = {
    identity       = tls_private_key.flux_private_key.private_key_pem
    "identity.pub" = tls_private_key.flux_private_key.public_key_pem
    known_hosts    = local.known_hosts
  }
}

resource "kubernetes_service_account" "kustomize_controller" {
  depends_on = [kubectl_manifest.flux_namespace]
  metadata {
    name      = "kustomize-controller"
    namespace = "flux-system"
    labels = {
      "app.kubernetes.io/instance"            = "flux-system"
      "app.kubernetes.io/part-of"             = "flux"
      "app.kubernetes.io/version"             = "v${var.flux_version}"
      "kustomize.toolkit.fluxcd.io/name"      = "flux-system"
      "kustomize.toolkit.fluxcd.io/namespace" = "flux-system"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_kustomize_controller.iam_role_arn
    }
  }
}

# https://github.com/fluxcd/terraform-provider-flux/issues/120
resource "kubectl_manifest" "flux_install" {
  for_each = { for v in local.flux_install : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content if anytrue([v.data.kind != "ServiceAccount", v.data.metadata.name != "kustomize-controller"]) }
  depends_on = [
    kubernetes_service_account.kustomize_controller,
    kubernetes_secret.flux_github_keys,
    kubernetes_secret.flux_cluster_apps_terraform_secret,
  ]
  yaml_body = each.value
}

resource "kubectl_manifest" "flux_sync" {
  for_each   = { for v in local.flux_sync : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content if var.gitops == "flux" }
  depends_on = [kubectl_manifest.flux_install]
  yaml_body  = each.value
}

resource "random_id" "github_webhook_flux_secret" {
  byte_length = 20
}

resource "github_repository_webhook" "flux" {
  repository = join("", regex(".*/([^.]*)", data.git_repository.current_git_repository.url))

  configuration {
    # Allow providing custom URL to the Receiver to allow IaC for webhooks - https://github.com/fluxcd/flux2/issues/2672
    url          = format("https://flux-receiver.%s/hook/%s", var.cluster_fqdn, sha256("${random_id.github_webhook_flux_secret.hex}github-receiverflux-system"))
    content_type = "form"
    # checkov:skip=CKV_GIT_2:Ensure Repository Webhook uses secure Ssl
    insecure_ssl = var.letsencrypt_environment == "staging" ? "1" : "0"
    secret       = random_id.github_webhook_flux_secret.hex
  }

  active = true
  events = ["push"]
}

# ---------------------------------------------------------------------------------------------------------------------
# Crossplane
# ---------------------------------------------------------------------------------------------------------------------

# Due to specific Crossplane installtion https://github.com/crossplane-contrib/provider-aws/blob/master/AUTHENTICATION.md#using-iam-roles-for-serviceaccounts
# it is necessary to "exctract" the dynamically created ServiceAccount using
# kubectl :-(
# This is breaking idempotency :-(
# https://discuss.hashicorp.com/t/how-to-retrieve-the-null-resource-returned-value/9620/4

resource "time_sleep" "wait" {
  depends_on      = [kubectl_manifest.flux_sync]
  create_duration = "2m"
}

resource "null_resource" "get_crossplane_provider_aws_serviceaccount_name" {
  depends_on = [time_sleep.wait]
  triggers = {
    kubeconfig = base64encode(local.kubeconfig)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = base64encode(local.kubeconfig)
    }
    command = "kubectl get providers.pkg.crossplane.io pkg-aws-provider -o jsonpath='{.status.currentRevision}' --kubeconfig <(echo $KUBECONFIG | base64 --decode) > /tmp/crossplane_provider_aws_serviceaccount_name.txt"
  }
}

data "local_file" "crossplane_provider_aws_serviceaccount_name" {
  depends_on = [null_resource.get_crossplane_provider_aws_serviceaccount_name]
  filename   = "/tmp/crossplane_provider_aws_serviceaccount_name.txt"
}

module "iam_assumable_role_crossplane_provider_aws" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.3.0"
  create_role                   = true
  provider_url                  = module.eks_blueprints.eks_oidc_issuer_url
  role_name                     = "${module.eks_blueprints.eks_cluster_id}-irsa-crossplane-provider-aws"
  role_description              = "Allow Crossplane to create AWS objects"
  role_policy_arns              = ["arn:${data.aws_partition.current.id}:iam::aws:policy/AdministratorAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:crossplane-system:${data.local_file.crossplane_provider_aws_serviceaccount_name.content}"]
}
