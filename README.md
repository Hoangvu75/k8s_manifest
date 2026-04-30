# k8s_manifest

GitOps repo for Kubernetes cluster management with ArgoCD, Kustomize, and Helm.

## Network Flow

```
                    Internet
                        │
                        ▼
              ┌─────────────────────┐
              │   Cloudflare CDN    │
              │ (cloudflared tunnel)│◄── HTTP/2 tunnel
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
           ┌───────────┼────────────────┐
           ▼           ▼                ▼
    ┌──────────┐ ┌──────────┐   ┌──────────────┐
    │ argocd   │ │ rancher  │   │  Kong Proxy  │
    │ :80      │ │ :80      │   │  (kong ns)   │
    └──────────┘ └──────────┘   └──────┬───────┘
                                       │ key-auth
                                       ▼
                              ┌────────────────┐
                              │   hello-api    │
                              │  :5678         │
                              └────────────────┘
```

### Traffic Path

| Step | Component | Details |
|------|-----------|---------|
| 1 | Cloudflare Edge | DNS resolves to Cloudflare, traffic enters via cloudflared tunnel |
| 2 | cloudflared pod | Decapsulates tunnel traffic, forwards to cluster services |
| 3 | Traefik (NodePort) | Receives on 30080/30443/30900/30901/30082, acts as Gateway API controller |
| 4 | shared-gateway | Gateway resource routes by hostname (Gateway API) |
| 5 | HTTPRoute | Matches hostname, routes to backend Service |
| 6a | Kong Gateway (api.*) | API key authentication via Kong Plugin, then routes to app |
| 6b | Direct (other hosts) | Routes directly to backend Service (argocd, rancher, traefik) |
| 7 | Application | Final destination pod (hello-api, argocd-server, rancher, etc.) |

### Hostnames

| Hostname | Backend | Namespace | Auth |
|----------|---------|-----------|------|
| `argocd.hoangvu75.space` | argocd-server:80 | argocd | — |
| `rancher.hoangvu75.space` | rancher:80 | cattle-system | — |
| `traefik.hoangvu75.space` | traefik:8080 | gateway-api | — |
| `api.hoangvu75.space` | hello-api:5678 (via Kong) | hello-api / kong | API Key |

## Workflow

### Bootstrap Chain

```
kustomize build . ──► bootstrap.yaml ──► bootstrap/    ──► projects/   ──► apps/**/config.yaml
(kubectl apply)         │                    │               │                  │
                     root App            bootstrap/       AppProject +       Kustomize +
                     (manual apply)      kustomization    ApplicationSet     Helm charts
```

1. **`kustomize build . | kubectl apply -f -`** — (initial one-time) builds `bootstrap.yaml` with repo URLs injected from `components/repo-url/`, then creates the root ArgoCD `Application`
2. **`bootstrap/`** — kustomization applies the same component, substituting `PLACEHOLDER` URLs in `root.yaml`, `cluster-resources.yaml`, and `secrets.yaml`
3. **`bootstrap/root.yaml`** — root Application syncs `projects/`, which defines AppProjects and ApplicationSets
4. **`bootstrap/cluster-resources.yaml`** — creates namespaces and shared cluster objects (sync-wave `-1`)
5. **`bootstrap/secrets.yaml`** — syncs secrets from private repo (sync-wave `1`)
6. **`projects/infra.yaml`** + **`projects/applications.yaml`** — ApplicationSets discover apps via `config.yaml` files
7. **`apps/infra/**/config.yaml`** + **`apps/applications/**/config.yaml`** — each discovered app is rendered by Kustomize (`--enable-helm`) and synced

### Sync Order (by sync-wave)

| Wave | Resources |
|------|-----------|
| `-2` | AppProjects |
| `-1` | Namespaces |
| `0` | ApplicationSets, Traefik Deployment |
| `1` | Secrets from private repo |
| `2` | Kong, Gateway, Datadog, and other mid-tier resources |
| `3` | HTTPRoutes, KIC resources (Ingress, KongPlugin, KongConsumer) |

## Repo Structure

```
├── kustomization.yaml           # Root Kustomize — builds bootstrap.yaml via components
├── bootstrap.yaml               # Root ArgoCD Application (contains PLACEHOLDER repoURL)
├── components/
│   └── repo-url/                # Central repo URL definitions (shared by all kustomizations)
│       └── kustomization.yaml
├── bootstrap/                   # Bootstrap Applications
│   ├── kustomization.yaml       # Uses components/repo-url, replaces PLACEHOLDERs
│   ├── root.yaml                # Points to projects/
│   ├── cluster-resources.yaml   # Namespace ApplicationSet
│   └── secrets.yaml             # Private secrets repo sync
├── projects/                    # AppProjects + ApplicationSets
│   ├── kustomization.yaml       # Uses components/repo-url, replaces PLACEHOLDERs
│   ├── infra.yaml               # Infrastructure project
│   └── applications.yaml        # Application apps project
├── cluster-resources/           # Shared cluster resources
│   └── default/                 # Namespace definitions
├── apps/
│   ├── infra/                   # Platform/infrastructure components
│   │   ├── gateway-api/         # Traefik + Gateway + wildcard TLS
│   │   ├── cloudflared/         # Cloudflare tunnel connector
│   │   ├── datadog/             # Monitoring agent
│   │   ├── kong/                # Kong Gateway — API key authentication proxy
│   │   │   ├── config.yaml      # discovery metadata (destNamespace: kong, wave: 2)
│   │   │   ├── kustomization.yaml
│   │   │   └── chart/
│   │   │       ├── kustomization.yaml
│   │   │       ├── values.yaml           # DB-less KIC config
│   │   │       ├── httproute-kong.yaml    # Traefik → Kong route
│   │   │       ├── plugins/              # KongPlugin CRDs
│   │   │       │   ├── kustomization.yaml
│   │   │       │   └── key-auth-plugin.yaml
│   │   │       ├── consumers/            # KongConsumer + credential Secrets
│   │   │       │   ├── kustomization.yaml
│   │   │       │   └── default-user-consumer.yaml
│   │   │       ├── ingress/              # KIC Ingress routes
│   │   │       │   ├── kustomization.yaml
│   │   │       │   └── hello-api-ingress.yaml
│   │   │       └── services/             # ExternalName cross-ns bridges
│   │   │           ├── kustomization.yaml
│   │   │           └── hello-api-service.yaml
│   │   ├── rancher/             # Rancher management UI (includes cert-manager)
│   │   └── argocd-ingress/      # ArgoCD HTTPRoute exposure
│   └── applications/            # User-facing application apps
│       ├── hello-api/           # Hello API demo app
│       ├── tcp-demo/            # TCP echo demo (Traefik TCP routing)
│       ├── udp-demo/            # UDP echo demo (Traefik UDP routing)
│       └── cluster-check/       # Debug jump pod (netshoot: curl, nc, dig, etc.)
├── guide/                       # Setup guides and troubleshooting
└── .opencode/                   # OpenCode config, rules, agents, skills
```

## GitOps Rules

- **Never** use `kubectl apply`, `kubectl edit`, `kubectl patch`, or `kubectl create` to modify cluster state
- All changes go through Git — commit YAML manifests, ArgoCD syncs automatically
- Read-only `kubectl` commands (`get`, `describe`, `logs`, `top`) are allowed for debugging
- Prefer OCI Helm charts from `oci://ghcr.io/hoangvu75/helm_application`
- Helm charts repo: `https://github.com/Hoangvu75/helm_application`

## Adding a New App

1. Create a folder under `apps/infra/<name>/` or `apps/applications/<name>/`
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
| Traefik + Gateway | infra | Ingress controller via Gateway API (HTTP/HTTPS/TCP/UDP) with Prometheus metrics, access logs, and OpenTelemetry tracing to Datadog APM |
| Cloudflared | infra | Cloudflare tunnel for external access |
| Datadog | infra | Monitoring and observability agent |
| Kong Gateway | infra | API key authentication layer between Traefik and applications (DB-less mode, KIC-managed) |
| Rancher (incl. cert-manager) | infra | Cluster management UI + TLS cert automation |
| ArgoCD Ingress | infra | Expose ArgoCD UI via HTTPRoute |
| Hello API | applications | Demo API application (protected by Kong key-auth) |
| TCP Echo Demo | applications | TCP echo server via Traefik IngressRouteTCP (NodePort 30900) |
| UDP Echo Demo | applications | UDP echo server via Traefik IngressRouteUDP (NodePort 30901) |
| Cluster Check | applications | Debug jump pod with networking tools (curl, nc, telnet, dig) |

## Private Secrets

Secrets are managed in a separate private repo `k8s_manifest_secrets`, synced via `bootstrap/secrets.yaml`. This keeps sensitive data (API keys, tunnel tokens, PATs) out of this public repo.
