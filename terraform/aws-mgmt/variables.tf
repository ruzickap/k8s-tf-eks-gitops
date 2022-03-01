# Variables used in the cluster-aws pipeline

variable "aws_default_region" {
  description = "AWS region"
  type        = string
}

variable "aws_github_oidc_federated_role_to_assume" {
  description = "OIDC Federation role (not used in the code)"
  type        = string
  default     = null
}

variable "cluster_fqdn" {
  description = "FQDN of the EKS cluster"
  type        = string
}

variable "base_domain" {
  type        = string
  description = "Domain name used for delegation"
}

variable "cluster_version" {
  description = "Desired kubernetes version. If you do not specify a value, the latest available version is used"
  type        = string
}

variable "terraform_code_dir" {
  description = "Path to terraform code (not used in the code)"
  type        = string
}

variable "aws_tags_group_level" {
  description = "A map group of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_tags_cluster_level" {
  description = "A map of cluster tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "aws_private_subnets" {
  description = "List of private subnets for the worker nodes"
  type        = list(string)
}

variable "aws_public_subnets" {
  description = "List of public subnets for the worker nodes"
  type        = list(string)
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
}

variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`]"
  type        = list(string)
  default     = []
}

variable "eks_managed_node_groups" {
  description = "Map of maps of eks_node_groups to create"
  type        = any
}

variable "eks_aws_auth_configmap_admins" {
  description = "A list of the Admins which can access the EKS cluster added to aws-config"
  type        = list(string)
}
