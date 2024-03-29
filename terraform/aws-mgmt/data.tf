data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "eks-cluster" {
  name = module.eks.cluster_name
}

data "aws_kms_alias" "kms_secretmanager" {
  name = "alias/aws/secretsmanager"
}

data "aws_partition" "current" {}

data "aws_route53_zone" "base_domain" {
  name = var.base_domain
}

data "git_repository" "current_git_repository" {
  path = path.cwd
}

# ---------------------------------------------------------------------------------------------------------------------
# ArgoCD
# ---------------------------------------------------------------------------------------------------------------------

data "http" "argo-cd_core-install" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/v${var.argocd_core_version}/manifests/core-install.yaml"
}

data "kubectl_file_documents" "argo-cd_core-install" {
  content = data.http.argo-cd_core-install.response_body
}

# ---------------------------------------------------------------------------------------------------------------------
# Flux
# ---------------------------------------------------------------------------------------------------------------------

data "kubectl_file_documents" "flux_install" {
  content = file(fileexists("../../${var.cluster_path}/flux/flux-system/gotk-components.yaml") ? "../../${var.cluster_path}/flux/flux-system/gotk-components.yaml" : "../../${var.cluster_path}/../flux/flux-system/gotk-components.yaml")
}

data "kubectl_file_documents" "flux_sync" {
  content = file("../../${var.cluster_path}/flux/flux-system/gotk-sync.yaml")
}
