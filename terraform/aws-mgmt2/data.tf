data "aws_eks_cluster" "eks-cluster" {
  name = module.eks_blueprints.eks_cluster_id
}

data "aws_eks_cluster_auth" "eks-cluster" {
  name = module.eks_blueprints.eks_cluster_id
}

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
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/${var.argocd_core_version}/manifests/core-install.yaml"
}

data "kubectl_file_documents" "argo-cd_core-install" {
  content = data.http.argo-cd_core-install.body
}

# ---------------------------------------------------------------------------------------------------------------------
# Flux
# ---------------------------------------------------------------------------------------------------------------------

data "kubectl_file_documents" "install" {
  content = file(fileexists("../../${var.cluster_path}/flux/flux-system/gotk-components.yaml") ? "../../${var.cluster_path}/flux/flux-system/gotk-components.yaml" : "../../${var.cluster_path}/../flux/flux-system/gotk-components.yaml")
}

data "kubectl_file_documents" "sync" {
  content = file("../../${var.cluster_path}/flux/flux-system/gotk-sync.yaml")
}
