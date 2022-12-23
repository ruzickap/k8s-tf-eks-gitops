# Generate gotk-components.yaml - Flux update

```bash
# renovate: datasource=github-tags depName=fluxcd/flux2
FLUX_VERSION="0.38.2"
flux install --version "${FLUX_VERSION}" --export > gotk-components.yaml
```

> By default all clusters in group should have same Flux version
> Note: Watch for "branch" in `gotk-sync.yaml` when testing the upgrade

The `clusters/<cluste_group>/<cluster_name>/flux/flux-system/gotk-components.yaml`
has precedence over `clusters/<cluste_group>/flux/flux-system/gotk-components.yaml`.
