# Amazon EKS installation using Terraform, GitHub Actions and ArgoCD

[![Build Status](https://github.com/ruzickap/k8s-tf-eks-argocd/actions/workflows/mdbook-build-check-deploy.yml/badge.svg)](https://github.com/ruzickap/k8s-tf-eks-argocd/actions/workflows/mdbook-build-check-deploy.yml)

* GitHub repository: [https://github.com/ruzickap/k8s-tf-eks-argocd](https://github.com/ruzickap/k8s-tf-eks-argocd)
* Web Pages: [https://ruzickap.github.io/k8s-tf-eks-argocd](https://ruzickap.github.io/k8s-tf-eks-argocd)

## Rancher notes

Very limited amount of settings for Amazon EKS. The following features
are missing:

* You can only re-use "public" subnets [Subnet](https://rancher.com/docs/rancher/v2.6/en/cluster-admin/editing-clusters/eks-config-reference/#subnet)
* Encrypted worker nodes disk(s) can be only configured using launch template
* Disks, EC2, subnets, VPCs, security groups are not tagged
* Subnet / EC2 names can not be set
* Default security groups are set to "allow all everywhere"
