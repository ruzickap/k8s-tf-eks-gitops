variable "aws_default_region" {
  description = "AWS region"
  type        = string
  default     = null
}

variable "aws_github_oidc_federated_role_to_assume" {
  description = "OIDC Federation role (not used in the code)"
  type        = string
  default     = null
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
  description = "Path to terraform code (not used in the code)"
  type        = string
  default     = null
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
  default     = []
}


variable "rancher_api_url" {
  description = "Rancher API endpoint FQDN"
  type        = string
}

variable "rancher_token_key" {
  description = "Rancher API token key to connect to rancher"
  type        = string
}
