variable "aws_default_region" {
  type    = string
  default = null
}

variable "aws_github_oidc_federated_role_to_assume" {
  type    = string
  default = null
}

variable "cluster_fqdn" {
  description = "FQDN of the EKS cluster"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Desired kubernetes version. If you do not specify a value, the latest available version is used"
  type        = string
  default     = "1.21"
}

variable "terraform_code_dir" {
  type    = string
  default = null
}

variable "aws_group_tags" {
  description = "A map group of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_cluster_tags" {
  description = "A map of cluster tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "aws_private_subnets" {
  description = "List of private subnets for the worker nodes"
  type        = list(string)
}

variable "aws_public_subnets" {
  description = "List of public subnets for the worker nodes"
  type        = list(string)
  default     = []
}
