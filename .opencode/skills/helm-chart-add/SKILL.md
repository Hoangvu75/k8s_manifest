---
name: helm-chart-add
description: Add or update Helm charts using the project's OCI Helm repo (ghcr.io/hoangvu75/helm_application) via Kustomize helmCharts blocks
compatibility: opencode
metadata:
  audience: devops
  stack: helm, kustomize, argocd
---

## What I Do
- Guide you through adding a Helm chart to this ArgoCD-managed project
- Use the project's OCI Helm repository: `oci://ghcr.io/hoangvu75/helm_application`
- Generate proper Kustomize `helmCharts` blocks with version pinning
- Set up `values.yaml`, `kustomization.yaml`, and `config.yaml` following existing patterns
- Ensure all files follow the ArgoCD ApplicationSet discovery pattern (`apps/<project>/<app>/config.yaml`)

## When to Use Me
Use this skill when you need to:
- Add a new Helm chart to the `apps/infra/` or `apps/playground/` directories
- Update an existing Helm chart version
- Add custom values to an existing chart

## Project Structure Pattern
- `apps/<project>/<app>/kustomization.yaml` — references `chart/` as a resource
- `apps/<project>/<app>/chart/kustomization.yaml` — contains `helmCharts` and resources
- `apps/<project>/<app>/chart/values.yaml` — Helm chart values override
- `apps/<project>/<app>/config.yaml` — ArgoCD ApplicationSet discovery config

## Helm Chart Reference Format
```yaml
helmCharts:
  - name: <chart-name>
    repo: oci://ghcr.io/hoangvu75/helm_application
    version: <semver-version>
    releaseName: <release-name>
    namespace: <namespace>
    valuesFile: values.yaml
```

## Key Rules
- ALWAYS pin to a specific version (never use `latest`)
- Namespace must match the namespace pre-created in `cluster-resources/default/namespace.yaml`
- Add the namespace if it doesn't exist yet
- Follow sync-wave ordering: infrastructure apps get lower wave numbers
- Secrets go in `k8s_manifest_secrets` repo, never in plain text
