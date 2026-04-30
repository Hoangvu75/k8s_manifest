# Kong Gateway with API Key Authentication

This guide describes how Kong Gateway is deployed as an API authentication layer between Traefik and backend applications.

## Architecture

```
Cloudflare → Traefik (shared-gateway) → Kong (key-auth) → helloworld-api
```

## Traffic Flow

1. **Traefik** receives traffic for `api.hoangvu75.space` via `HTTPRoute kong-ingress`
2. **HTTPRoute** routes to `kong-proxy:80` (Kong Proxy Service)
3. **Kong Gateway** validates `X-API-Key` header using the `key-auth` plugin
4. **KIC** (Kong Ingress Controller) manages Kong routing via:
   - `Ingress` → translates to Kong routes
   - `KongPlugin` → enables key-auth on routes
   - `KongConsumer` + `Secret` → creates API key credentials
5. **Kong Proxy** forwards authenticated requests to `helloworld-api:5678`

## Component Files

Located in `apps/infra/kong-gateway/`:

| File | Purpose |
|------|---------|
| `config.yaml` | ApplicationSet discovery (destNamespace: kong-gateway, wave: 2) |
| `kustomization.yaml` | Parent kustomize with `namespace: kong-gateway` |
| `chart/values.yaml` | Kong Helm chart values (DB-less, GHCR images, KIC v3.3) |
| `chart/kustomization.yaml` | Chart-level kustomize (Helm chart + subdirectory resources) |
| `chart/httproute-kong.yaml` | Traefik → Kong proxy HTTPRoute (wave: 3) |
| `chart/httproute-kong-manager.yaml` | Traefik → Kong Manager GUI HTTPRoute (wave: 3) |
| `chart/httproute-kong-admin.yaml` | Traefik → Kong Admin API HTTPRoute (wave: 3, restricted) |
| `chart/plugins/key-auth-plugin.yaml` | KongPlugin CRD for key-auth |
| `chart/consumers/default-user-consumer.yaml` | KongConsumer + credential Secret |
| `chart/ingress/helloworld-api-ingress.yaml` | KIC Ingress: routes /helloworld → helloworld-api:5678 |
| `chart/services/helloworld-api-service.yaml` | Cross-namespace ExternalName bridge (kong-gateway → helloworld-api) |

## Testing

### API Key Authentication

```bash
# Without API key (should return 401)
curl -v https://api.hoangvu75.space/helloworld

# With API key (should return 200)
curl -v -H "X-API-Key: dev-api-key-123" https://api.hoangvu75.space/helloworld
```

### Kong Manager Dashboard

Open **https://kong.hoangvu75.space** in your browser.

The Manager UI shows:
- Kong Gateway status and configuration
- Routes, Services, Plugins, and Consumers
- Health metrics and monitoring (DB-less read-only mode)

### Admin API (Direct Access)

The Kong Admin API is available at **https://kong-admin.hoangvu75.space** for direct REST access:

```bash
# List all routes configured in Kong
curl https://kong-admin.hoangvu75.space/routes

# List all services
curl https://kong-admin.hoangvu75.space/services

# List consumers
curl https://kong-admin.hoangvu75.space/consumers
```

## Adding a New App Behind Kong

Place all new resource files in the appropriate subdirectory under `chart/`:

| What | Where |
|------|-------|
| KIC Ingress route | `chart/ingress/` (e.g. `helloworld-api-ingress.yaml`) |
| ExternalName service | `chart/services/` (e.g. `helloworld-api-service.yaml`) |
| KongConsumer + Secret | `chart/consumers/` |
| KongPlugin | `chart/plugins/` |

No changes needed to `chart/kustomization.yaml` — subdirectories auto-discover new files.

### 1. Add Kong Route (Ingress)

Create a new file in `chart/ingress/` for your app with `ingressClassName: kong`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    konghq.com/plugins: key-auth
    konghq.com/strip-path: "false"
spec:
  ingressClassName: kong
  rules:
    - http:
        paths:
          - path: /myapp
            pathType: Prefix
            backend:
              service:
                name: my-app-service     # Must be in kong-gateway namespace or use ExternalName
                port:
                  number: 8080
```

If the backend service is in a different namespace, create an ExternalName service file in `chart/services/`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: kong-gateway
spec:
  type: ExternalName
  externalName: my-app-service.my-app-ns.svc.cluster.local
```

### 2. Add Routing to Kong

The `httproute-kong.yaml` routes `api.hoangvu75.space/*` → `kong-proxy:80`. If you want a different hostname, create a new HTTPRoute.

### 3. Add Consumer Credentials (Optional)

To add API keys for different consumers, create a file in `chart/consumers/`:

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: my-consumer
  annotations:
    kubernetes.io/ingress.class: kong
username: my-consumer
credentials:
  - my-consumer-key-auth
---
apiVersion: v1
kind: Secret
metadata:
  name: my-consumer-key-auth
  labels:
    konghq.com/credential: key-auth
  annotations:
    kubernetes.io/ingress.class: kong
stringData:
  key: my-custom-api-key
type: Opaque
```

## Known Issues & Lessons Learned

| Issue | Symptom | Fix |
|-------|---------|-----|
| KIC wipes dbless config | Routes empty in Kong admin API | Must use KIC CRDs (Ingress + KongPlugin) instead of `dblessConfig` |
| Credential not created | Consumer exists but no key-auth | Add explicit `credentials: [secret-name]` field to KongConsumer |
| `ingressController.enabled: false` breaks ArgoCD build | Kustomize build fails | Keep KIC enabled but manage config via CRDs |
| Docker Hub rate limits (429) | Image pull failures | Use GHCR images (`ghcr.io/hoangvu75/`) |
| Namespace override by ArgoCD | `destNamespace: kong-gateway` forces all resources to kong-gateway ns | Use ExternalName services for cross-namespace backends |
| `KONG_KIC=on` hard-coded by Helm chart | env.kic: off is overridden | Cannot disable KIC via values — keep enabled and use CRDs |
