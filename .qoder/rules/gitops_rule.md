---
trigger: always_on
---

## Core GitOps Rules

- **Never** use `kubectl apply`, `kubectl edit`, `kubectl patch`, or `kubectl create` to modify cluster state
- All changes go through Git — commit YAML manifests, ArgoCD syncs automatically
- Read-only `kubectl` commands (`get`, `describe`, `logs`, `top`) are allowed for debugging

## App Structure Convention

Every app under `apps/<type>/<name>/` MUST follow this structure:

```
apps/<type>/<name>/
├── config.yaml             # ApplicationSet discovery metadata
├── kustomization.yaml      # Kustomize root (with --enable-helm if using Helm)
└── chart/                  # All chart-related resources go here, NOT at app root
    ├── kustomization.yaml  # Kustomize wrapping Helm chart
    ├── values.yaml         # Default Helm values overrides
    ├── values-*.yaml       # Optional: variant values files (e.g., values-httproute.yaml)
    └── ...                 # Other chart-related resources
```

- `config.yaml` supports `destNamespace` (optional, defaults to folder name) and `annotations` (e.g., sync-wave) — keep it minimal and at app root only
- **All important resource files** (values variants, templates, patches) MUST be placed **inside `chart/`**, never at the app root alongside `config.yaml` — only `config.yaml` and `kustomization.yaml` belong at app root
- Use `kustomize build . --enable-helm` when Helm charts are involved; the `chart/kustomization.yaml` references Helm via `helmCharts` block, and `chart/values.yaml` holds overrides. Multiple variant values files (e.g., `values-httproute.yaml`, `values-service.yaml`) can exist in `chart/` and be selectively referenced via `helmCharts`
- The parent `kustomization.yaml` at app root references `./chart` as a resource
- First-time cluster bootstrap uses `kustomize build . | kubectl apply -f -` (one-time manual step)

## Namespace Management

- Define shared namespaces once in `cluster-resources/default/namespace.yaml`
- Annotate with `argocd.argoproj.io/sync-wave: "-1"` to ensure namespaces exist before app resources deploy
- Do NOT define namespaces inline inside app manifests — keep them centralized

## Sync-Wave Discipline

| Wave | Resources |
|------|-----------|
| `-2` | AppProjects |
| `-1` | Namespaces |
| `0` | ApplicationSets, Traefik Deployment |
| `1` | Secrets from private repo |
| `2` | Gateway, Datadog, and other mid-tier resources |
| `3` | HTTPRoutes (last, after Gateway exists) |

- Stick to this wave ordering when assigning sync-wave annotations
- HTTPRoutes MUST always come last (wave `3`) since they depend on the Gateway resource

## Repo URL Pattern

- Never hardcode `repoURL` values — use `components/repo-url/` kustomization with `PLACEHOLDER` substitution
- The `components/repo-url/` component is included in all kustomizations that need repo URLs
- When adding a new Application or ApplicationSet that references a repository, use the PLACEHOLDER pattern

## Secrets Policy

- **Never** commit secrets (API keys, tunnel tokens, PATs, TLS private keys) to this repository
- All secrets live in the private repo `https://github.com/Hoangvu75/k8s_manifest_secrets`
- Secrets are synced via `bootstrap/secrets.yaml` with sync-wave `1`
- The `guide/argocd/argocd-repository-secrets.yaml` shows the template for ArgoCD repository credentials — but the actual PAT goes in the private repo

## Helm Chart Policy

- Prefer OCI Helm charts from `oci://ghcr.io/hoangvu75/helm_application`
- Helm charts source repo: `https://github.com/Hoangvu75/helm_application`
- Reference Helm charts via Kustomize `helmCharts` blocks in `chart/kustomization.yaml`, not standalone `helm install`