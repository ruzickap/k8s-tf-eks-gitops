# Generate gotk-components.yaml - Flux update

```bash
flux install --version v0.29.3 --export > gotk-components.yaml
```

> Note: Watch for "branch" in `gotk-sync.yaml` when testing the upgrade

The `clusters/<cluste_group>/<cluster_name>/flux/flux-system/gotk-components.yaml`
has precedence over `clusters/<cluste_group>/flux/flux-system/gotk-components.yaml`.
