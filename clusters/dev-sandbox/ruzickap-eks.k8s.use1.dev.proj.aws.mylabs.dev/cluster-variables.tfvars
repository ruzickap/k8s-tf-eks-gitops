cluster_name = "ruzickap-eks"
cluster_fqdn = "ruzickap-eks.test.k8s.mylabs.dev"

aws_vpc_cidr        = "10.0.0.0/21"
aws_private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
aws_public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
aws_default_tags = {
  cluster_group       = "dev-sandbox"
  owner               = "petr.ruzicka@gmail.com"
  entity              = "org1"
  environment         = "dev"
  data-classification = "green"
  product_id          = "12345"
  department          = "myit"
  charge-code         = "4321"
}
