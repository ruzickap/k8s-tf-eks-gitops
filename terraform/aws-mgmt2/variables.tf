# Variable used only in the cluster-aws pipeline
variable "aws_default_region" {
  description = "AWS region"
  type        = string
}

# Variable used only in the cluster-aws pipeline
variable "aws_github_oidc_federated_role_to_assume" {
  description = "OIDC Federation role (not used in the code)"
  type        = string
  default     = null
}

variable "aws_private_subnets" {
  description = "List of private subnets for the worker nodes"
  type        = list(string)
}

variable "aws_public_subnets" {
  description = "List of public subnets for the worker nodes"
  type        = list(string)
}

variable "aws_tags_cluster_level" {
  description = "A map of cluster tags to add to all resources"
  type        = map(string)
}

variable "aws_tags_group_level" {
  description = "A map group of tags to add to all resources"
  type        = map(string)
}

variable "aws_vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "base_domain" {
  type        = string
  description = "Domain name used for delegation"
}

variable "cluster_enabled_log_types" {
  type        = list(string)
  description = "A list of the desired control plane logging to enable"
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Indicates whether or not the EKS private API server endpoint is enabled. Default to EKS resource and it is false"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Indicates whether or not the EKS public API server endpoint is enabled. Default to EKS resource and it is true"
}

variable "cluster_fqdn" {
  description = "FQDN of the EKS cluster"
  type        = string
}

variable "cluster_kms_key_deletion_window_in_days" {
  type        = number
  description = "The waiting period, specified in number of days (7 - 30). After the waiting period ends, AWS KMS deletes the KMS key"
}

variable "cluster_log_retention_in_days" {
  description = "Number of days to retain log events. Default retention - 90 days."
  type        = number
}

variable "environment" {
  type        = string
  description = "Environment area, e.g. prod or preprod "
}

variable "kubernetes_version" {
  type        = string
  description = "Desired kubernetes version. If you do not specify a value, the latest available version is used"
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth ConfigMap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "managed_node_groups" {
  description = "Map of maps of eks_node_groups to create"
  type        = any
}

# Variable used only in the cluster-aws pipeline
variable "terraform_code_dir" {
  description = "Path to terraform code (not used in the code)"
  type        = string
}

variable "tenant" {
  type        = string
  description = "Account Name or unique account unique id e.g., apps or management or aws007"
}

variable "zone" {
  type        = string
  description = "zone, e.g. dev or qa or load or ops etc..."
}
