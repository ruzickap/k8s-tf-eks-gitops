# Changelog

## 1.0.0 (2024-06-09)


### Features

* **cluster-apps:** add helm-dashboard ([#512](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/512)) ([2178912](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/2178912ed000152addde30d9f09c07fc4b18406b))
* **commitlint:** add commitlint GH Action ([99297f7](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/99297f74e4f73d196c56950d561b387a4a6362dd))
* **eks:** update Amazon EKS to latest version ([58ecb29](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/58ecb29bdec140784f5187e31f896a1508483411))
* **external-snapshotter:** add external-snapshotter ([a1ed8aa](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/a1ed8aa46b77accde402ce4bca9a4ad7bea6486d))
* **gh-actions:** add lint-pr-title ([1fea814](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/1fea8146183f74e8981fdbf569e5d72b762117b0))
* **gha:** change name in flux-validate ([#562](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/562)) ([eae6805](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/eae6805ed16893d94bf4a11aafc03743b9f187be))
* **gh:** add default GitHub repo files ([#566](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/566)) ([5f69002](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/5f6900299ed6fc39007cafc5e581e734c94eebaf))
* **gh:** add default GitHub repo files ([#569](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/569)) ([d66c4a5](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/d66c4a50c4aac5a8481058d42f0f82744715daf4))
* **gha:** unify GHA - renovate, megalinter, markdown, and others ([#548](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/548)) ([4c3ffc2](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/4c3ffc2147981068f19a6681d8b7c52913195235))
* **karpenter:** add karpenter ([5cba592](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/5cba5927d5a4ef28f6d516507fb85a17364512ac))
* **kyverno:** enable kyverno ([aba4363](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/aba4363d199fcda7b3ff9693044ba30d9cf151eb))
* **renovate:** split k8s and non-k8s updates into 2 groups ([9600bd3](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/9600bd3653ea4ab98a19d030e498e2436b4f3476))
* **stale:** improve stale by adding custom messages ([be49e27](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/be49e27cbe68b9e65f5ea18c87c7ac2966934daa))
* **stale:** replace probot/stale by actions/stale ([232eedd](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/232eeddf8cc59e1086af77a95f50449861caa579))
* **tf:** change eks tf module to terraform-aws-eks ([199f943](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/199f9431c86da007bb50ee23b227177f287d011c))


### Bug Fixes

* **branch:** fix flux branch ([8da3f77](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/8da3f77ca099ff3434d3b35b056e72bd18226f64))
* **cf:** fix ThumbprintList for GitHub Action + README update ([#539](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/539)) ([a0d5980](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/a0d598052437083f88504fa4724ce663c08d6a39))
* **flux:** fix Kustomization/cluster-apps.flux-system timeout ([7869e8a](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/7869e8a5c96a90a340bcb11b92955b6dd544d696))
* **flux:** move branch back ([2265476](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/22654767e002789260eb8b8add16b05243cb8981))
* **flux:** set proper apiVersion for flux notification - v1beta2 ([7addd6f](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/7addd6f95b52d12095b390f55555cc4edf528ef1))
* **gh-action:** Fix missing export in clusters-aws-schedule ([#560](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/560)) ([baf243f](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/baf243f65c3bcd983aab6ffa4227dccbb2080a67))
* **gha:** disable kics, remove spell_misspell add tag cluster_fqdn ([#536](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/536)) ([7e9dace](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/7e9daceae2255aab8607b080dd63a956e6c52e3e))
* **gha:** fix GitHub Actions permissions ([#528](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/528)) ([1fe05fa](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/1fe05fa2b0063ec1520443dcd12852d52c2ad7ce))
* **issues:** fix velero, sort tf vars + outputs, vpc, add lychee cache ([#532](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/532)) ([f0e5aec](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/f0e5aecb593c200d571365c7bb52cd5d058f78a4))
* **kyverno:** fix tf destroy + kyverno - webhook ([50f8b6f](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/50f8b6fe932cfe1d2684bafc719d70de3717fdd4))
* **linter:** fix azure secret issue in checkov ([#550](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/550)) ([0b9fe26](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/0b9fe26ce531c393a0b7cce3705f9f6e498ff093))
* **linters:** add permissions: read-all to all GH actions ([239b497](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/239b497ce46b28e14650c677de2c734affc90573))
* **linters:** fix checkov issues ([b00ecad](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/b00ecadff1aac5a24a943ce75bafe309df8340b7))
* **linters:** fix code linting form MD files ([6d0eca3](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/6d0eca310188fb13e0e3aed69f68ae2a75c31b05))
* **linters:** fix spell check ([7038262](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/703826207c6b2af7475b42bf2208a7e6e0c25fc9))
* **renovate:** schedule typo ([46f7074](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/46f7074ad598615ae653f2cd5124bed0d2ae0800))
* **url:** fix broken URL(s) ([#579](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/579)) ([d4737e1](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/d4737e1a3e5e3368e7b846cc04621962223e2242))
* **url:** fix waveworks url ([#574](https://github.com/ruzickap/k8s-tf-eks-gitops/issues/574)) ([f74a966](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/f74a96636dffd917a6a33963e8fb19c11fd928ee))


### Performance Improvements

* **dynamodb:** use PAY_PER_REQUEST for dynamodb + disable backups ([639d0ae](https://github.com/ruzickap/k8s-tf-eks-gitops/commit/639d0aecc85e4c8da9d538ccb3f28b8f3a9f2d9b))
