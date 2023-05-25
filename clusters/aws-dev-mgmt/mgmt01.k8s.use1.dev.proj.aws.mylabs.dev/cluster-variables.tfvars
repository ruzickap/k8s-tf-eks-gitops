cluster_fqdn = "mgmt01.k8s.use1.dev.proj.aws.mylabs.dev"
# Domain where TF will create NS record to point to the new "zone" `cluster_fqdn`
base_domain     = "k8s.use1.dev.proj.aws.mylabs.dev"
aws_assume_role = "arn:aws:iam::729560437327:role/GitHubOidcFederatedRole"
cluster_path    = "clusters/aws-dev-mgmt/mgmt01.k8s.use1.dev.proj.aws.mylabs.dev"

# Key used for encrypting and decrypting secrests using SOPS + Flux
flux_kustomize_controller_kms_key_arn = "arn:aws:kms:eu-central-1:729560437327:key/f2d53be5-7422-41a5-a463-2fbf6912402b"

environment             = "dev"
letsencrypt_environment = "staging"

# Email (used for Let's Encrypt)
email = "petr.ruzicka@gmail.com"

# Choose GitOps tool [ flux / argocd ]
gitops = "flux"

# The ArgoCD Version is only used for initial ArgoCD installation (https://github.com/argoproj/argo-cd/tags)
# renovate: datasource=github-tags depName=argoproj/argo-cd
argocd_core_version = "2.7.3"

# renovate: datasource=github-tags depName=fluxcd/flux2
flux_version = "0.41.2"

cluster_version                 = "1.25"
cluster_endpoint_private_access = false
cluster_endpoint_public_access  = true

aws_vpc_cidr        = "10.0.0.0/21"
aws_private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
aws_public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

aws_tags_cluster_level = {
  owner = "petr.ruzicka@gmail.com"
}

kms_key_owners = [
  "arn:aws:iam::729560437327:role/admin",
  "arn:aws:iam::729560437327:user/aws-cli",
]

aws_auth_roles = [
  {
    rolearn  = "arn:aws:iam::729560437327:role/admin"
    username = "system:aws:root"
    groups   = ["system:masters"]
  },
]

aws_auth_users = [
  {
    userarn  = "arn:aws:iam::729560437327:user/aws-cli"
    username = "system:aws:root"
    groups   = ["system:masters"]
  },
]

eks_managed_node_groups = {
  mgmt01-ng01 = {
    node_group_name = "mgmt01-ng01"

    desired_size    = 3
    min_size        = 2
    max_size        = 5
    max_unavailable = 1
    capacity_type   = "SPOT"
  }
}
