# k8s_manifest

K8s manifest repository (GitOps), synced to the cluster using **Argo CD**. Git is the source of truth; Argo CD compares Git with the cluster state and applies changes (auto-sync).

---

## Directory Structure

| Directory / File | Description |
|------------------|-------------|
| **bootstrap/** | The "bootstrap" Application syncs this directory → creates the **root** Application and **cluster-resources** ApplicationSet on the cluster. |
| **bootstrap.yaml** | Defines the "bootstrap" Application (syncs `bootstrap/` path). Installed manually once or applied using `kubectl apply -f`. |
| **projects/** | The **root** Application syncs this directory → contains AppProject and **playground**, **infra** ApplicationSets (automatically creates child Applications from `apps/`). |
| **cluster-resources/default/** | The **cluster-resources** ApplicationSet creates the **cluster-resources-default** app which syncs this directory → mainly **namespaces** (sync-wave -1, created before other apps). |
| **apps/<project>/<app>/** | Each app has a `config.yaml` (metadata), `kustomization.yaml` (+ Helm chart in `chart/` if used). The **playground** / **infra** ApplicationSets scan `apps/playground/**/config.yaml` and `apps/infra/**/config.yaml` → creating an Application for each app. |
| **guide/** | Quick Start Guides: Argo CD, Jenkins, Kubernetes Dashboard (URLs, obtaining passwords/tokens). |

---

## Sync Flow (Summary)

1.  **Bootstrap** (Application, configured once) syncs `bootstrap/`:
    - Creates the **root** Application (syncs `projects/`).
    - Creates the **cluster-resources** ApplicationSet → generates the **cluster-resources-default** Application (syncs `cluster-resources/default/` → namespaces, etc.).

2.  **Root** syncs `projects/`:
    - Applies AppProject + **playground** and **infra** ApplicationSets to the cluster.

3.  **ApplicationSet playground / infra**:
    - Scans Git for patterns `apps/playground/**/config.yaml` and `apps/infra/**/config.yaml`.
    - Each `config.yaml` corresponds to an Application (named `playground-<app>`, `infra-<app>`), syncing the path containing that app (Kustomize ± Helm).

4.  **cluster-resources-default** syncs `cluster-resources/default/`:
    - Applies `namespace.yaml` (and other files if present) → creates Namespaces with sync-wave -1 so they exist before apps deploy.

---

## Projects and Existing Apps

### playground (5 apps)
| App | Host (LAN) | Public URL |
|-----|------------|------------|
| argocd | argocd.localhost | argocd.hoangvu75.space |
| harbor | harbor.localhost | harbor.hoangvu75.space |
| jenkins | jenkins.localhost | jenkins.hoangvu75.space |
| n8n | n8n.localhost | n8n.hoangvu75.space |
| sample-gitops-web | - | - |

### infra (3 apps)
| App | Host (LAN) | Public URL |
|-----|------------|------------|
| ingress-nginx | - | (Controller) |
| cloudflared | - | (Tunnel Connector) |
| kubernetes-dashboard | kubedashboard.localhost | dashboard.hoangvu75.space |

*> **Note:** Since MetalLB has been removed, LAN Hosts can only be accessed from outside the cluster via `kubectl port-forward`. The primary access method is via **Public URL** (Cloudflare Tunnel).*

Adding an app: create a directory `apps/<project>/<app-name>/` with `config.yaml` + `kustomization.yaml` (and `chart/` if using Helm). Add the Namespace (if needed) to `cluster-resources/default/namespace.yaml`. Push to Git → Argo CD automatically creates the Application and syncs.

---

## Quick Guides

- **Network Flow (DNS → K8s):** [guide/network_flow.md](guide/network_flow.md)
- **Argo CD:** [guide/argo_cd.md](guide/argo_cd.md)
- **Jenkins (Unlock password):** [guide/jenkins.md](guide/jenkins.md)
- **Kubernetes Dashboard (token):** [guide/kube_dashboard.md](guide/kube_dashboard.md)
- **Harbor (registry):** [guide/harbor.md](guide/harbor.md)
