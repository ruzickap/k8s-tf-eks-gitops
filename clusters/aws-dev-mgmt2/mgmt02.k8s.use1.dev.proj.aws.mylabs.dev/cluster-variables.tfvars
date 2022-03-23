cluster_fqdn = "mgmt02.k8s.use1.dev.proj.aws.mylabs.dev"
# Domain where TF will create NS record to point to the new "zone" `cluster_fqdn`
base_domain = "k8s.use1.dev.proj.aws.mylabs.dev"

kubernetes_version = "1.21"

cluster_endpoint_private_access = false
cluster_endpoint_public_access  = true

cluster_kms_key_deletion_window_in_days = 7
cluster_log_retention_in_days           = 1
environment                             = "dev"
tenant                                  = "test123"
zone                                    = "dev1"

aws_vpc_cidr        = "10.0.0.0/21"
aws_private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
aws_public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

aws_tags_cluster_level = {
  owner = "petr.ruzicka@gmail.com"
}

map_roles = [
  {
    rolearn  = "arn:aws:iam::729560437327:role/Admins"
    username = "system:aws:root"
    groups   = ["system:masters"]
  },
]

map_users = [
  {
    userarn  = "arn:aws:iam::729560437327:user/ruzickap"
    username = "system:aws:root"
    groups   = ["system:masters"]
  },
]

managed_node_groups = {
  mgmt02-ng-01 = {
    node_group_name = "mgmt02-ng01"

    desired_size    = 2
    min_size        = 2
    max_size        = 3
    max_unavailable = 1

    ami_type       = "BOTTLEROCKET_x86_64"
    capacity_type  = "ON_DEMAND"
    instance_types = ["t2.medium"]
    disk_size      = 20
  }
}
