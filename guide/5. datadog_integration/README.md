# Datadog Integration

This guide documents the Datadog observability integration for the `k8s_manifest` GitOps project.

Datadog site: `https://us5.datadoghq.com`

## Deployment

Datadog is deployed as an infrastructure app via Helm chart:

| App | Chart Source | Version | Namespace |
|-----|-------------|---------|-----------|
| **Datadog** | `https://helm.datadoghq.com` | 3.201.2 | `datadog` |

Files:
- [Datadog app definition](../../apps/infra/datadog/kustomization.yaml)
- [Helm chart config](../../apps/infra/datadog/chart/kustomization.yaml)
- [Values overrides](../../apps/infra/datadog/chart/values.yaml)

## Features

The integration covers **three observability signals** — Logs, Metrics, and Traces — all flowing from Traefik to Datadog:

```
Traefik ──logs (stdout)──► Datadog Agent (containerCollectAll: true)
Traefik ──metrics (:9082)─► Datadog Agent (Prometheus scrape)
Traefik ──traces (:4318)──► Datadog Agent (OTLP receiver)
                              │
                              ▼
                         Datadog Cloud (us5.datadoghq.com)
```

### 1. Logs (stdout collection)

**Agent config** (`values.yaml`):
```yaml
logs:
  enabled: true
  containerCollectAll: true
```

**Traefik config** (`traefik-static.yaml`):
```yaml
accessLog:
  format: json
  filters:
    statusCodes: ["200-499"]
  fields:
    defaultMode: keep
```

Every container's stdout is automatically collected (`containerCollectAll: true`). For Traefik specifically, the `accessLog` is enabled to produce **per-request JSON log entries** with:
- Client IP and port
- Request hostname and path
- Backend service name
- Response status code
- Request duration
- Bytes transferred

Without the `accessLog` block, Traefik only outputs its own startup/error logs — no per-request data.

**View in Datadog:**
- [Log Explorer](https://us5.datadoghq.com/logs)
- Filter: `kube_namespace:gateway-api kube_service:traefik`

### 2. Metrics (Prometheus scraping)

**Agent config** (`values.yaml`):
```yaml
prometheusScrape:
  enabled: true
  serviceEndpoints: true
```

**Traefik config** (`traefik-static.yaml`):
```yaml
metrics:
  prometheus:
    entryPoint: metrics
    addEntryPointsLabels: true
    addServicesLabels: true
```

Traefik exposes Prometheus-formatted metrics on `:9082/metrics`. The Datadog Agent scrapes this endpoint using **autodiscovery annotations** on the Traefik pod:

```yaml
# traefik.yaml — pod template annotations
ad.datadoghq.com/traefik.check_names: '["openmetrics"]'
ad.datadoghq.com/traefik.init_configs: '[{}]'
ad.datadoghq.com/traefik.instances: '[{"openmetrics_endpoint":"http://%%host%%:9082/metrics","namespace":"traefik","metrics":["^traefik_"]}]'
```

> **Note:** Standard Prometheus annotations (`prometheus.io/scrape: "true"`) are also present but Datadog requires its own `ad.datadoghq.com/` annotations for autodiscovery.

Available metrics (~16 total) include:

| Metric Prefix | Description |
|--------------|-------------|
| `traefik_entrypoint_*` | Traffic entering each entryPoint (port 80, 443, 9000, 9001) |
| `traefik_service_*` | Traffic forwarded to each backend service |
| `traefik_router_*` | Traffic matched by each router rule |
| `traefik_config_*` | Configuration reload health |
| `traefik_tcp_*` / `traefik_udp_*` | Layer 4 connection counters |

**View in Datadog:**
- [Metrics Summary](https://us5.datadoghq.com/metric/summary?filter=traefik)

### 3. Traces (OTLP APM)

**Agent config** (`values.yaml`):
```yaml
otlp:
  receiver:
    protocols:
      http:
        enabled: true
      grpc:
        enabled: true
```

**Traefik config** (`traefik-static.yaml`):
```yaml
tracing:
  otlp:
    http:
      endpoint: http://datadog.datadog:4318/v1/traces
```

Traefik sends an OpenTelemetry trace span for every HTTP request it processes. The Datadog Agent's OTLP receiver accepts it on `:4318` and forwards to Datadog APM.

**View in Datadog:**
- [APM Traces](https://us5.datadoghq.com/apm/traces?query=service%3Atraefik)
- Filter: `service:traefik`

Each trace shows the full request journey through Traefik's pipeline:

```
GET /helloworld (45ms)
├── Router (0.2ms)         ← hostname/path matching
├── RequestHeaderModifier  ← X-Forwarded-Proto/Port
└── Service (44ms)         ← backend helloworld-api
```

## Additional Features

### Process Collection
```yaml
processAgent:
  enabled: true
  processCollection: true
  containerCollection: true
```
Enables live process monitoring in Datadog.

### Orchestrator Explorer
```yaml
orchestratorExplorer:
  enabled: true
kubeStateMetricsCore:
  enabled: true
```
Enables Kubernetes resource view (pods, deployments, services) in the Datadog UI.

## Troubleshooting

### Check Datadog Agent status
```bash
kubectl exec -n datadog daemonset/datadog -- agent status
```

### Verify OTLP receiver is running
```bash
kubectl exec -n datadog daemonset/datadog -- agent status | grep -A 8 "OTLP"
# Expected: Status: Enabled, Collector status: Running
```

### Verify metrics scraping
```bash
kubectl exec -n datadog daemonset/datadog -- agent status | grep -A 15 "openmetrics"
# Look for an Instance ID containing "traefik" or "gateway-api"
```

### Verify Traefik metrics endpoint
```bash
kubectl exec -n cluster-check deploy/cluster-check -- curl -s http://traefik.gateway-api:9082/metrics | head -20
```

### Check Agent connectivity to Datadog
```bash
kubectl exec -n datadog daemonset/datadog -- agent status | grep "diagnostics"
```

## Links

| Feature | Datadog URL |
|---------|-------------|
| **Metrics** | [Metrics Summary → traefik](https://us5.datadoghq.com/metric/summary?filter=traefik) |
| **Logs** | [Log Explorer → gateway-api](https://us5.datadoghq.com/logs?query=kube_namespace%3Agateway-api) |
| **APM Traces** | [APM Traces → traefik](https://us5.datadoghq.com/apm/traces?query=service%3Atraefik) |
