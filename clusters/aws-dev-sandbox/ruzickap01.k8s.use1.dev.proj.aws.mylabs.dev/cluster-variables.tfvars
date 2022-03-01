cluster_fqdn = "ruzickap01.k8s.use1.dev.proj.aws.mylabs.dev"
# Domain where TF will create NS record to point to the new "zone" `cluster_fqdn`
base_domain = "k8s.use1.dev.proj.aws.mylabs.dev"

aws_vpc_cidr        = "10.0.8.0/21"
aws_private_subnets = ["10.0.8.0/24", "10.0.9.0/24", "10.0.10.0/24"]
aws_public_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

cluster_version = "1.21"

aws_tags_cluster_level = {
  owner = "petr.ruzicka@gmail.com"
}

eks_managed_node_groups = {
  ruzickap01-ng-01 = {
    description = "Amazon EKS managed node group for ruzickap-eks.k8s.use1.dev.proj.aws.mylabs.dev"
    name        = "ruzickap-eks-ng01"

    ami_type       = "BOTTLEROCKET_x86_64"
    platform       = "bottlerocket"
    instance_types = ["t2.medium"]

    desired_size = 2
    min_size     = 2
    max_size     = 3

    block_device_mappings = {
      root = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 4
          volume_type           = "gp3"
          delete_on_termination = true
          encrypted             = true
        }
      }
      containers = {
        device_name = "/dev/xvdb"
        ebs = {
          volume_size           = 21
          volume_type           = "gp3"
          delete_on_termination = true
          encrypted             = true
        }
      }
    }
  }
}
