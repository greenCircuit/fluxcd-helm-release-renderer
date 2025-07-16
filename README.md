# fluxcd-helm-release-renderer
# About
Want to render helm releases the same way as do `helm template .`, but there is no fast way to do it unless want to do `helm template -f myvalues.yam`

# Usage
- Will output into folder

# Limitations
- values need to provided inside helmRelease already, so don't add any templating there

# Supported sources
### GitRepository

```bash
.generateHr.sh -f tests/hr_gitrepo.yaml -p <path to your gitrepo on your host>

```

### HelmRepository
```bash
```

# TODO
- more flags?
- move to go in case logic to complicated?
- Support config maps as extra values file?
