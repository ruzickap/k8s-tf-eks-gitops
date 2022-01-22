variable "aws_default_region" {
  default = "eu-central-1"
}

variable "aws_github_oidc_federated_role_to_assume" {
  default = "arn:aws:iam::1234567890:role/GitHubOidcFederatedRole"
}

variable "cluster_fqdn" {
  default = "mycluster.mylabs.com"
}

variable "cluster_name" {
  default = "mycluster"
}

variable "terraform_code_dir" {
  default = "terraform/dev"
}
