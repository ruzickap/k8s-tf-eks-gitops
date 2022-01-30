resource "rancher2_cluster" "cluster" {
  name        = var.cluster_name
  description = var.cluster_description

  # https://github.com/rancher/terraform-provider-rancher2/blob/master/rancher2/structure_cluster_eks_config_v2.go
  eks_config_v2 {
    cloud_credential_id = rancher2_cloud_credential.rancher_aws_account.id
    kms_key             = aws_kms_key.eks-kms_key.arn
    kubernetes_version  = var.cluster_version
    name                = var.cluster_name
    private_access      = var.eks_config_v2.private_access
    public_access       = var.eks_config_v2.public_access
    # public_access_sources =
    region             = var.aws_default_region
    secrets_encryption = true
    # security_groups  =
    # security_groups  =
    # service_role     =
    # subnets          =
    tags = local.aws_default_tags

    logging_types = var.eks_config_v2.logging_types

    # https://github.com/rancher/terraform-provider-rancher2/blob/master/rancher2/structure_cluster_eks_config_v2.go
    dynamic "node_groups" {
      for_each = var.eks_config_v2_node_groups

      content {
        desired_size = node_groups.value.desired_size == "" ? 3 : node_groups.value.desired_size
        disk_size    = node_groups.value.disk_size == "" ? 29 : node_groups.value.disk_size
        gpu          = node_groups.value.gpu == "" ? false : node_groups.value.gpu
        # image_id      = node_groups.value.image_id <- not working .... !!!!
        instance_type = node_groups.value.instance_type
        # labels       = ""
        # launch_template = ""
        max_size = node_groups.value.max_size == "" ? 6 : node_groups.value.max_size
        min_size = node_groups.value.min_size == "" ? 2 : node_groups.value.min_size
        name     = node_groups.value.name
        # request_spot_instances = ""
        resource_tags = merge(local.aws_default_tags, { "Name" = var.cluster_name }, node_groups.value.resource_tags)
        # spot_instance_types = ""
        # subnets =
        # tags = ""
        # user_data = ""
        # version = ""
      }
    }
  }
}
