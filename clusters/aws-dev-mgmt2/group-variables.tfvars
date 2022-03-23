aws_default_region = "eu-central-1"
aws_assume_role    = "arn:aws:iam::729560437327:role/GitHubOidcFederatedRole"
terraform_code_dir = "terraform/aws-mgmt2"

cluster_enabled_log_types = [] # "audit", "authenticator"

aws_tags_group_level = {
  cluster_group       = "dev2-mgmt"
  entity              = "org1"
  environment         = "dev"
  data-classification = "green"
  product_id          = "12345"
  department          = "myit"
  charge-code         = "4321"
}
