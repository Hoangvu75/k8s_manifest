---
name: kustomize-struct
description: Create or modify Kustomize overlay structures following this project's conventions for ArgoCD-based deployments
compatibility: opencode
metadata:
  audience: devops
  stack: kustomize, argocd, kubernetes
---

## What I Do
- Guide you through creating proper Kustomize overlay directories for new apps
- Ensure `kustomization.yaml` files follow the project's two-layer pattern (app layer + chart layer)
- Set up proper resource ordering, namespace references, and label inheritance
- Configure `helmCharts` blocks correctly within Kustomize

## When to Use Me
Use this skill when you need to:
- Scaffold a new application in `apps/infra/` or `apps/playground/`
- Add resources or patches to an existing Kustomize app
- Set up a Kustomize overlay that includes Helm charts

## Project Kustomize Patterns

### Two-Layer Structure
```
apps/<project>/<app>/
  kustomization.yaml       # Layer 1: references chart/ as resource, applies patches
  config.yaml              # ArgoCD ApplicationSet discovery metadata

apps/<project>/<app>/chart/
  kustomization.yaml       # Layer 2: contains helmCharts + raw resources
  values.yaml              # Helm values override
  <resource>.yaml          # Raw K8s resources (if any)
```

### Layer 1 Example (app-level)
```yaml
# apps/infra/<app>/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: <namespace>
resources:
  - chart/
patches:
  - path: custom-patch.yaml   # optional
labels:
  - includeSelectors: true
    pairs:
      app.kubernetes.io/name: <app>
```

### Layer 2 Example (chart-level)
```yaml
# apps/infra/<app>/chart/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: <namespace>
resources:
  - traefik-deployment.yaml   # raw K8s manifests
helmCharts:
  - name: cloudflared
    repo: oci://ghcr.io/hoangvu75/helm_application
    version: 0.1.0
    releaseName: cloudflared
    namespace: cloudflared
    valuesFile: values.yaml
```

## Existing Patterns to Follow
- `apps/infra/gateway-api/` — raw K8s manifests + kustomization (no Helm)
- `apps/infra/cloudflared/` — Helm chart in chart/ subdirectory
- `apps/infra/datadog/` — Helm chart with sync-wave annotation
- `apps/playground/cert-manager/` — Jetstack Helm chart
- `apps/playground/rancher/` — Rancher Helm chart + HTTPRoute resource
- `apps/playground/argocd-ingress/` — Raw resources + Helm service

## Key Rules
- Always set `namespace:` in kustomization.yaml
- ArgoCD builds with `--enable-helm` (configured in projects/*.yaml)
- Extra kustomize build options can be set in the ApplicationSet spec
- Labels with `includeSelectors: true` propagate to all resources
