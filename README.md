# k8s_manifest

GitOps repo for Kubernetes cluster management with ArgoCD, Kustomize, and Helm.

## Network Flow

```
                    Internet
                        │
                        ▼
              ┌─────────────────────┐
              │   Cloudflare CDN    │
              │  (cloudflared tunnel│◄── HTTP/2 tunnel
              └────────┬────────────┘
                       │
                       ▼
              ┌─────────────────────┐
              │  NodePort 30080/    │
              │  30443 (Traefik)    │
              └────────┬────────────┘
                       │ Gateway API
                       ▼
              ┌─────────────────────┐
              │  shared-gateway     │
              │  (gateway-api ns)   │
              │  :80 HTTP           │
              │  :443 HTTPS (TLS)   │
              └────────┬────────────┘
                       │ HTTPRoutes
           ┌───────────┼───────────────┐
           ▼           ▼               ▼
    ┌──────────┐ ┌──────────┐   ┌──────────┐
    │ argocd   │ │ rancher  │   │  ...     │
    │ :80      │ │ :80      │   │          │
    └──────────┘ └──────────┘   └──────────┘
```

### Traffic Path

| Step | Component | Details |
|------|-----------|---------|
| 1 | Cloudflare Edge | DNS resolves to Cloudflare, traffic enters via cloudflared tunnel |
| 2 | cloudflared pod | Decapsulates tunnel traffic, forwards to cluster services |
| 3 | Traefik (NodePort) | Receives on 30080/30443, acts as Gateway API controller |
| 4 | shared-gateway | Gateway resource routes by hostname (Gateway API) |
| 5 | HTTPRoute | Matches hostname, routes to backend Service |
| 6 | Application | Final destination pod (argocd-server, rancher, etc.) |

### Hostnames

| Hostname | Backend | Namespace |
|----------|---------|-----------|
| `argocd.hoangvu75.space` | argocd-server:80 | argocd |
| `rancher.hoangvu75.space` | rancher:80 | cattle-system |
| `*.hoangvu75.space` | (wildcard TLS) | gateway-api |

## Workflow

### Bootstrap Chain

```
bootstrap.yaml ──► bootstrap/root.yaml ──► projects/*.yaml ──► apps/**/config.yaml
     │                    │                      │                      │
  root App            points to             AppProject +           Kustomize +
  (manual apply)      projects/             ApplicationSet         Helm charts
```

1. **`bootstrap.yaml`** — manually applied once; creates the root ArgoCD `Application` pointing to `bootstrap/`
2. **`bootstrap/root.yaml`** — root Application syncs `projects/`, which defines AppProjects and ApplicationSets
3. **`bootstrap/cluster-resources.yaml`** — creates namespaces and shared cluster objects (sync-wave `-1`)
4. **`bootstrap/secrets.yaml`** — syncs secrets from private repo `k8s_manifest_secrets` (sync-wave `1`)
5. **`projects/infra.yaml`** + **`projects/playground.yaml`** — ApplicationSets discover apps via `config.yaml` files
6. **`apps/infra/**/config.yaml`** + **`apps/playground/**/config.yaml`** — each discovered app is rendered by Kustomize (`--enable-helm`) and synced

### Sync Order (by sync-wave)

| Wave | Resources |
|------|-----------|
| `-2` | AppProjects |
| `-1` | Namespaces |
| `0` | ApplicationSets, Traefik Deployment |
| `1` | Secrets from private repo |
| `2` | Gateway, Datadog, and other mid-tier resources |
| `3` | HTTPRoutes (last, after Gateway exists) |

## Repo Structure

```
├── bootstrap.yaml              # Root ArgoCD Application (manual apply once)
├── bootstrap/                  # Bootstrap Applications
│   ├── root.yaml               # Points to projects/
│   ├── cluster-resources.yaml  # Namespace ApplicationSet
│   └── secrets.yaml            # Private secrets repo sync
├── projects/                   # AppProjects + ApplicationSets
│   ├── infra.yaml              # Infrastructure project
│   └── playground.yaml         # Experimental/user apps project
├── cluster-resources/          # Shared cluster resources
│   └── default/                # Namespace definitions
├── apps/
│   ├── infra/                  # Platform/infrastructure components
│   │   ├── gateway-api-crds/   # Gateway API CRDs (install first)
│   │   ├── gateway-api/        # Traefik + Gateway + wildcard TLS
│   │   ├── cloudflared/        # Cloudflare tunnel connector
│   │   └── datadog/            # Monitoring agent
│   └── playground/             # Experimental and user-facing apps
│       ├── cert-manager/       # Certificate management
│       ├── argocd-ingress/     # ArgoCD HTTPRoute exposure
│       └── rancher/            # Rancher management UI
├── guide/                      # Setup guides and troubleshooting
└── .opencode/                  # OpenCode config, rules, agents, skills
```

## GitOps Rules

- **Never** use `kubectl apply`, `kubectl edit`, `kubectl patch`, or `kubectl create` to modify cluster state
- All changes go through Git — commit YAML manifests, ArgoCD syncs automatically
- Read-only `kubectl` commands (`get`, `describe`, `logs`, `top`) are allowed for debugging
- Prefer OCI Helm charts from `oci://ghcr.io/hoangvu75/helm_application`

## Adding a New App

1. Create a folder under `apps/infra/<name>/` or `apps/playground/<name>/`
2. Add `config.yaml` for ApplicationSet discovery (set `destNamespace` if needed)
3. Add `kustomization.yaml` and optional `chart/` directory
4. If using Helm, reference charts via Kustomize `helmCharts` blocks with `--enable-helm`
5. Commit and push — ArgoCD detects and syncs automatically

### config.yaml Example

```yaml
destNamespace: my-namespace       # optional, defaults to folder name
annotations:
  argocd.argoproj.io/sync-wave: "2"  # optional sync ordering
```

## Namespace Management

Shared namespaces are defined in `cluster-resources/default/namespace.yaml` with sync-wave `-1` to ensure they exist before apps deploy.

## Common Apps

| App | Type | Purpose |
|-----|------|---------|
| Gateway API CRDs | infra | Kubernetes Gateway API custom resource definitions |
| Traefik + Gateway | infra | Ingress controller via Gateway API |
| Cloudflared | infra | Cloudflare tunnel for external access |
| Datadog | infra | Monitoring and observability agent |
| cert-manager | playground | TLS certificate automation |
| ArgoCD Ingress | playground | Expose ArgoCD UI via HTTPRoute |
| Rancher | playground | Cluster management UI |

## OpenCode Setup

This repo includes OpenCode configuration for:
- **Main agents** (`build`/`plan`): `deepseek/deepseek-v4-pro`
- **Subagents** (`general`/`explore`): `openrouter/auto`
- **Specialized agents**: `k8s-validator`, `gitops-reviewer`, `helm-reviewer`, `input-optimizer`
- **Skills**: GitOps sync, Kustomize structure, Helm chart management, Prometheus rules, Dockerfile optimization, K8s debugging

## Private Secrets

Secrets are managed in a separate private repo `k8s_manifest_secrets`, synced via `bootstrap/secrets.yaml`. This keeps sensitive data (API keys, tunnel tokens, PATs) out of this public repo.
