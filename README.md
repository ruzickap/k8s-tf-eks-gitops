# :sailboat: Build Amazon EKS using Terraform, GitHub Actions and GitOps

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67"
align="left" width="144px" height="144px"/>

_... managed by Flux/ArgoCD and serviced with Renovate ..._

[![Amazon EKS](https://img.shields.io/badge/Amazon%20EKS-grey?style=for-the-badge&logo=amazoneks)](https://aws.amazon.com/eks/)
[![Cilium](https://img.shields.io/badge/Cilium-grey?style=for-the-badge&logo=cilium)](https://github.com/argoproj/argo-cd)
[![Rancher](https://img.shields.io/badge/Rancher-grey?style=for-the-badge&logo=rancher)](https://rancher.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-grey?style=for-the-badge&logo=prometheus)](https://prometheus.io/)
[![Argo CD](https://img.shields.io/badge/Argo%20CD-grey?style=for-the-badge&logo=argo)](https://github.com/argoproj/argo-cd)
[![Renovate](https://img.shields.io/badge/Renovate-grey?style=for-the-badge&logo=renovatebot)](https://github.com/renovatebot/renovate)

[![Build Status](https://github.com/ruzickap/k8s-tf-eks-gitops/actions/workflows/mdbook-build-check-deploy.yml/badge.svg)](https://github.com/ruzickap/k8s-tf-eks-gitops/actions/workflows/mdbook-build-check-deploy.yml)

<br/>

* GitHub repository: [https://github.com/ruzickap/k8s-tf-eks-gitops](https://github.com/ruzickap/k8s-tf-eks-gitops)
* Web Pages: [https://ruzickap.github.io/k8s-tf-eks-gitops](https://ruzickap.github.io/k8s-tf-eks-gitops)

---

## :book:&nbsp; Overview

---

## :sparkles:&nbsp; Cluster setup

---

## :art:&nbsp; Cluster components

* [cilium](https://docs.cilium.io/en/stable/): For cluster networking.
* [ingress-nginx](https://kubernetes.github.io/ingress-nginx/): Provides ingress
  cluster services.
* [SOPS](https://toolkit.fluxcd.io/guides/mozilla-sops/): Encrypts secrets which
  is safe to store - even to a public repository.
* [external-dns](https://github.com/kubernetes-sigs/external-dns): Creates DNS
  entries in Cloud Provider's DNS service.
* [cert-manager](https://cert-manager.io/docs/): Configured to create TLS certs
  for all ingress services automatically using LetsEncrypt.

---

## :open_file_folder:&nbsp; Repository structure

```bash
flux tree kustomization flux-system --compact
```

Output:

```text
Kustomization/flux-system/flux-system
├── Kustomization/flux-system/cluster-apps
│   ├── HelmRelease/metrics-server/metrics-server
│   ├── HelmRelease/polaris/polaris
│   ├── Kustomization/flux-system/cert-manager
│   │   └── HelmRelease/cert-manager/cert-manager
│   ├── Kustomization/flux-system/cert-manager-certificate
│   ├── Kustomization/flux-system/cert-manager-clusterissuer
│   ├── Kustomization/flux-system/cert-manager-crds
│   ├── Kustomization/flux-system/cluster-autoscaler
│   │   └── HelmRelease/cluster-autoscaler/cluster-autoscaler
│   ├── Kustomization/flux-system/crossplane
│   │   └── HelmRelease/crossplane-system/crossplane
│   ├── Kustomization/flux-system/crossplane-provider
│   ├── Kustomization/flux-system/crossplane-providerconfig
│   ├── Kustomization/flux-system/dex
│   │   └── HelmRelease/dex/dex
│   ├── Kustomization/flux-system/external-dns
│   │   └── HelmRelease/external-dns/external-dns
│   ├── Kustomization/flux-system/ingress-nginx
│   │   └── HelmRelease/ingress-nginx/ingress-nginx
│   ├── Kustomization/flux-system/kube-prometheus-stack
│   │   └── HelmRelease/kube-prometheus-stack/kube-prometheus-stack
│   ├── Kustomization/flux-system/kubernetes-dashboard
│   │   └── HelmRelease/kubernetes-dashboard/kubernetes-dashboard
│   ├── Kustomization/flux-system/oauth2-proxy
│   │   └── HelmRelease/oauth2-proxy/oauth2-proxy
│   └── Kustomization/flux-system/podinfo
│       └── HelmRelease/podinfo/podinfo
├── Kustomization/flux-system/cluster-apps-secrets
├── Kustomization/flux-system/sources
│   ├── HelmRepository/flux-system/autoscaler
│   ├── HelmRepository/flux-system/bitnami
│   ├── HelmRepository/flux-system/crossplane
│   ├── HelmRepository/flux-system/dex
│   ├── HelmRepository/flux-system/fairwinds-stable
│   ├── HelmRepository/flux-system/ingress-nginx
│   ├── HelmRepository/flux-system/jetstack
│   ├── HelmRepository/flux-system/kubernetes-dashboard
│   ├── HelmRepository/flux-system/metrics-server
│   ├── HelmRepository/flux-system/oauth2-proxy
│   ├── HelmRepository/flux-system/podinfo
│   └── HelmRepository/flux-system/prometheus-community
└── GitRepository/flux-system/flux-system
```

---

## :robot:&nbsp; Automate all the things

* [GitHub Actions](https://github.com/features/actions) for checking code
  formatting
* [Renovate](https://github.com/renovatebot/renovate) Renovate GitHub action
  keeps my application charts and container images up-to-date

---

## :spider_web:&nbsp; Secrets

There are several secrets:

* `cluster-apps-vars-terraform-secret` - used for providing Terraform variables
  to Flux/Kustomizations: [eks.tf](https://github.com/ruzickap/k8s-tf-eks-gitops/blob/1f00e1dbcb82422e0ec291b85a4d48786e93b7f4/terraform/aws-mgmt2/eks.tf#L399-L412)
* `cluster-apps-secrets` - secrets specific to cluster: [cluster-apps-secrets.yaml](https://github.com/ruzickap/k8s-tf-eks-gitops/blob/main/clusters/aws-dev-mgmt2/mgmt02.k8s.use1.dev.proj.aws.mylabs.dev/flux/cluster-apps-secrets/cluster-apps-secrets.yaml)
* `cluster-apps-group-secrets` - secrets specific to cluster group: [cluster-apps-secrets.yaml](https://github.com/ruzickap/k8s-tf-eks-gitops/blob/main/clusters/aws-dev-mgmt2/flux/cluster-apps-secrets/cluster-apps-secrets.yaml)

---

## :man_shrugging:&nbsp; Notes

* Describe the directory structure
* Check emails form [policy-reporter](https://github.com/kyverno/policy-reporter/blob/03bbebed79a69e9f3dc123b01e9e332145713e1e/charts/policy-reporter/values.yaml#L157-L199)
* Put all `HelmRepository` objects to `flux-system` instead of "namespaces"
  to be able to share them
* Check snapshots (cnpg/velero) + KMS keys (if they are being deleted)
* kubernetes-dashboard - auto login not working

---

## :handshake:&nbsp; Thanks

A lot of inspiration for my cluster came from the people that have shared their
clusters over at [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes)
and many other "GitHub" repositories...
