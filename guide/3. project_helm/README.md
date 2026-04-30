# Project Helm Chart

This directory contains the source for the custom Helm chart used across the `k8s_manifest` GitOps repo. It is a fork of the [Stakater/application](https://github.com/stakater/application) generic Helm chart, published as an OCI chart at:

```
oci://ghcr.io/hoangvu75/helm_application
```

Source repo: [https://github.com/Hoangvu75/helm_application](https://github.com/Hoangvu75/helm_application)

## Chart Structure

```
helm_application/application/
├── Chart.yaml                 # v2 Helm chart, version 6.16.1
├── values.yaml                # All configurable values (~1400 lines)
├── values-test.yaml           # Test values overrides
└── templates/
    ├── _helpers.tpl           # Shared template helpers
    ├── NOTES.txt              # Post-install notes
    ├── deployment.yaml        # Main workload (Deployment/StatefulSet)
    ├── service.yaml           # Service resource
    ├── serviceaccount.yaml    # ServiceAccount
    ├── configmap.yaml         # ConfigMap
    ├── secret.yaml            # Kubernetes Secret
    ├── sealedsecrets.yaml     # SealedSecret
    ├── externalsecrets.yaml   # ExternalSecret (External Secrets Operator)
    ├── secretproviderclass.yaml # SecretProviderClass (CSI)
    ├── httproute.yaml         # Gateway API HTTPRoute
    ├── ingress.yaml           # Traditional Ingress
    ├── route.yaml             # OpenShift Route
    ├── hpa.yaml               # HorizontalPodAutoscaler
    ├── pdb.yaml               # PodDisruptionBudget
    ├── pvc.yaml               # PersistentVolumeClaim
    ├── networkpolicy.yaml     # NetworkPolicy
    ├── role.yaml              # RBAC Role
    ├── rolebinding.yaml       # RBAC RoleBinding
    ├── cronjob.yaml           # CronJob
    ├── job.yaml               # Job
    ├── certificate.yaml       # cert-manager Certificate
    ├── forecastle.yaml        # Forecastle (app catalog)
    ├── grafanadashboard.yaml  # GrafanaDashboard CR
    ├── prometheusrule.yaml    # PrometheusRule CR
    ├── servicemonitor.yaml    # ServiceMonitor CR
    ├── endpointmonitor.yaml   # EndpointMonitor
    ├── alertmanagerconfig.yaml # AlertmanagerConfig
    ├── backup.yaml            # Backup CR
    ├── vpa.yaml               # VerticalPodAutoscaler
    ├── extraobjects.yaml      # Raw YAML passthrough
    └── tests/                 # Helm unittest suite
```

Every template is **optional** — enabled/disabled via `values.yaml` flags (e.g., `deployment.enabled: true`, `httproute.enabled: true`).

## Apps Using This Chart

Three apps in the `k8s_manifest` repo consume this OCI chart via Kustomize `helmCharts`:

| App | Namespace | Chart Version | Values Files | Purpose |
|-----|-----------|---------------|--------------|---------|
| **Cloudflared** | `cloudflared` | 6.16.1 | `values.yaml` | Cloudflare tunnel connector |
| **ArgoCD Ingress** | `argocd` | 6.16.1 | `values.yaml` | Expose ArgoCD UI via HTTPRoute |
| **Hello API** | `hello-api` | 6.16.1 | `values.yaml`, `values-service.yaml`, `values-httproute.yaml` | Demo API with variant overrides |

### How They Reference the Chart

Each app follows this pattern in its `chart/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
- name: application
  repo: oci://ghcr.io/hoangvu75/helm_application
  releaseName: <app-name>
  namespace: <namespace>
  version: 6.16.1
  valuesFile: values.yaml
  additionalValuesFiles:   # optional
    - values-service.yaml
    - values-httproute.yaml
```

Example from [hello-api](../../apps/applications/hello-api/chart/kustomization.yaml):

```yaml
helmCharts:
- name: application
  repo: oci://ghcr.io/hoangvu75/helm_application
  releaseName: hello-api
  namespace: hello-api
  version: 6.16.1
  valuesFile: values.yaml
  additionalValuesFiles:
    - values-service.yaml
    - values-httproute.yaml
```

## How Kustomize Processes Helm Charts

ArgoCD runs `kustomize build . --enable-helm` which:

1. Fetches the chart from `oci://ghcr.io/hoangvu75/helm_application`
2. Merges `values.yaml` + optional `additionalValuesFiles`
3. Renders the Helm templates
4. Outputs rendered YAML manifests
5. ArgoCD applies them to the cluster

```
ArgoCD
  └─ kustomize build . --enable-helm
        └─ chart/kustomization.yaml
              └─ helmCharts:
                    └─ oci://ghcr.io/hoangvu75/helm_application
                          └─ values.yaml (+ additionalValuesFiles)
                                └─ Rendered YAML
                                      └─ kubectl apply
```

## Other Helm Charts in the Project

Not all apps use the custom chart. These use their own upstream Helm charts directly:

| App | Chart Source | Version |
|-----|-------------|---------|
| **Datadog** | `https://helm.datadoghq.com` | 3.201.2 |
| **cert-manager** | `https://charts.jetstack.io` | v1.14.4 |
| **Rancher** | `https://releases.rancher.com/server-charts/latest` | latest |

## Making Changes to the Chart

1. Edit the templates or `values.yaml` in `helm_application/application/`
2. Run tests (if available):
   ```bash
   cd helm_application/application
   helm unittest .
   ```
3. Build and push the OCI chart:
   ```bash
   helm package application/
   helm push application-6.16.1.tgz oci://ghcr.io/hoangvu75/helm_application
   ```
4. Update the `version:` field in consuming `kustomization.yaml` files
5. Commit and push both repos