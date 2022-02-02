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

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  validation {
    condition     = can(regex("[a-z0-9]([-a-z0-9]*[a-z0-9])?", var.cluster_name))
    error_message = "The cluster_name value must contain alphanumeric character + '-' only."
  }
}

variable "cluster_version" {
  description = "Desired kubernetes version. If you do not specify a value, the latest available version is used"
  type        = string
  default     = "1.21"
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
