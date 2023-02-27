aws_default_region = "eu-central-1"
terraform_code_dir = "terraform/aws-mgmt"

cloudwatch_log_group_retention_in_days = 1
cluster_enabled_log_types              = [] # "audit", "authenticator"
kms_key_deletion_window_in_days        = 7

aws_tags_group_level = {
  cluster_group       = "dev2-mgmt"
  entity              = "org1"
  environment         = "dev"
  data-classification = "green"
  product_id          = "12345"
  department          = "myit"
  charge-code         = "4321"
}

eks_managed_node_group_defaults = {
  ami_type       = "BOTTLEROCKET_x86_64"
  disk_size      = 20
  instance_types = ["t3a.medium"]
  # Enables/disables detailed monitoring
  enable_monitoring = false
  iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore : "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  }
}

# github_token is used to create Flux deploy key
# This is a "secret" and should be paased to teraform using TF_VAR_github_token variable
# github_token = "xxxxxxx"
