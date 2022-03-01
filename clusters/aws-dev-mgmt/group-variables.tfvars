aws_default_region                       = "eu-central-1"
aws_github_oidc_federated_role_to_assume = "arn:aws:iam::123456789012:role/GitHubOidcFederatedRole"
terraform_code_dir                       = "terraform/aws-mgmt"

cloudwatch_log_group_retention_in_days = "1"
cluster_enabled_log_types              = [] # "audit", "authenticator"

# arn:aws:iam::123456789012:role/Admins
eks_aws_auth_configmap_admins = [
  "role/Admins",
  "user/ruzickap",
]

aws_tags_group_level = {
  cluster_group       = "dev-mgmt"
  entity              = "org1"
  environment         = "dev"
  data-classification = "green"
  product_id          = "12345"
  department          = "myit"
  charge-code         = "4321"
}
