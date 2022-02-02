# Cluster Name should only consist alphanumeric character and '-'
cluster_name = "ruzickap-eks"
cluster_fqdn = "ruzickap-eks.test.k8s.mylabs.dev"

aws_vpc_cidr        = "10.0.0.0/21"
aws_private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
aws_public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

aws_tags_cluster_level = {
  owner = "petr.ruzicka@gmail.com"
}
