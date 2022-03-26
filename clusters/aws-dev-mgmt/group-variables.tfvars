aws_default_region = "eu-central-1"
terraform_code_dir = "terraform/aws-mgmt"

cloudwatch_log_group_retention_in_days = 1
cluster_enabled_log_types              = [] # "audit", "authenticator"

aws_tags_group_level = {
  cluster_group       = "dev-mgmt"
  entity              = "org1"
  environment         = "dev"
  data-classification = "green"
  product_id          = "12345"
  department          = "myit"
  charge-code         = "4321"
}
