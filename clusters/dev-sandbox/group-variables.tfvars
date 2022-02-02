aws_default_region                       = "eu-central-1"
aws_github_oidc_federated_role_to_assume = "arn:aws:iam::123456789012:role/GitHubOidcFederatedRole"
terraform_code_dir                       = "terraform/dev"
cluster_version                          = "1.21"
aws_tags_group_level = {
  cluster_group       = "dev-sandbox"
  entity              = "org1"
  environment         = "dev"
  data-classification = "green"
  product_id          = "12345"
  department          = "myit"
  charge-code         = "4321"
}
