cluster_fqdn = "ruzickap02.ruzickap.test-example.com"
# Domain where TF will create NS record to point to the new "zone" `cluster_fqdn`
base_domain     = "ruzickap.test-example.com"
aws_assume_role = "arn:aws:iam::801795154280:role/GitHubOidcFederatedRole"

cluster_version = "1.22"

aws_vpc_cidr        = "172.16.0.0/21"
aws_private_subnets = ["172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"]
aws_public_subnets  = ["172.16.3.0/24", "172.16.4.0/24", "172.16.5.0/24"]

aws_tags_cluster_level = {
  owner = "petr.ruzicka@gmail.com"
}

aws_auth_roles = [
  {
    rolearn  = "arn:aws:iam::729560437327:role/Admins"
    username = "system:aws:root"
    groups   = ["system:masters"]
  },
  {
    rolearn  = "arn:aws:iam::729560437327:user/aws-cli"
    username = "system:aws:root"
    groups   = ["system:masters"]
  },
]

eks_managed_node_groups = {
  ruzickap02-ng01 = {
    description = "Amazon EKS managed node group for ruzickap02.ruzickap.test-example.com"
    name        = "ruzickap02-ng01"

    ami_type       = "BOTTLEROCKET_x86_64"
    platform       = "bottlerocket"
    instance_types = ["t2.medium"]

    desired_size = 1
    min_size     = 1
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
