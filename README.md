# Amazon EKS installation using Terraform, GitHub Actions and ArgoCD

[![Build Status](https://github.com/ruzickap/k8s-tf-eks-gitops/actions/workflows/mdbook-build-check-deploy.yml/badge.svg)](https://github.com/ruzickap/k8s-tf-eks-gitops/actions/workflows/mdbook-build-check-deploy.yml)

* GitHub repository: [https://github.com/ruzickap/k8s-tf-eks-gitops](https://github.com/ruzickap/k8s-tf-eks-gitops)
* Web Pages: [https://ruzickap.github.io/k8s-tf-eks-gitops](https://ruzickap.github.io/k8s-tf-eks-gitops)

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

## Secrets

There are severals secrets:

* `cluster-apps-vars-terraform-secret` - used for providing Terraform variables
  to Flux/Kustomizations: [eks.tf](https://github.com/ruzickap/k8s-tf-eks-gitops/blob/1f00e1dbcb82422e0ec291b85a4d48786e93b7f4/terraform/aws-mgmt2/eks.tf#L399-L412)
* `cluster-apps-secrets` - secrets specific to cluster: [cluster-apps-secrets.yaml](https://github.com/ruzickap/k8s-tf-eks-gitops/blob/main/clusters/aws-dev-mgmt2/mgmt02.k8s.use1.dev.proj.aws.mylabs.dev/flux/cluster-apps-secrets/cluster-apps-secrets.yaml)
* `cluster-apps-group-secrets` - secrets specific to cluster group: [cluster-apps-secrets.yaml](https://github.com/ruzickap/k8s-tf-eks-gitops/blob/main/clusters/aws-dev-mgmt2/flux/cluster-apps-secrets/cluster-apps-secrets.yaml)

## Notes

* Describe the directory structure
* Check emails form [policy-reporter](https://github.com/kyverno/policy-reporter/blob/03bbebed79a69e9f3dc123b01e9e332145713e1e/charts/policy-reporter/values.yaml#L157-L199)
