# Kong Gateway with API Key Authentication

This guide describes how Kong Gateway is deployed as an API authentication layer between Traefik and backend applications.

## Architecture

```
Cloudflare → Traefik (shared-gateway) → Kong (key-auth) → hello-api
```

## Traffic Flow

1. **Traefik** receives traffic for `api.hoangvu75.space` via `HTTPRoute kong-ingress`
2. **HTTPRoute** routes to `kong-proxy:80` (Kong Proxy Service)
3. **Kong Gateway** validates `X-API-Key` header using the `key-auth` plugin
4. **KIC** (Kong Ingress Controller) manages Kong routing via:
   - `Ingress` → translates to Kong routes
   - `KongPlugin` → enables key-auth on routes
   - `KongConsumer` + `Secret` → creates API key credentials
5. **Kong Proxy** forwards authenticated requests to `hello-api:5678`

## Component Files

Located in `apps/infra/kong/`:

| File | Purpose |
|------|---------|
| `config.yaml` | ApplicationSet discovery (destNamespace: kong, wave: 2) |
| `kustomization.yaml` | Parent kustomize with `namespace: kong` |
| `chart/values.yaml` | Kong Helm chart values (DB-less, GHCR images, KIC v3.3) |
| `chart/kustomization.yaml` | Chart-level kustomize (Helm chart + resources) |
| `chart/httproute-kong.yaml` | Traefik → Kong proxy HTTPRoute (wave: 3) |
| `chart/externalname-hello-api.yaml` | Cross-namespace service bridge (kong → hello-api) |
| `chart/kong-plugin-key-auth.yaml` | KongPlugin CRD for key-auth |
| `chart/kong-consumer.yaml` | KongConsumer + credential Secret |
| `chart/hello-api-ingress.yaml` | KIC Ingress: routes /helloworld → hello-api:5678 |

## Testing

```bash
# Without API key (should return 401)
curl -v https://api.hoangvu75.space/helloworld

# With API key (should return 200)
curl -v -H "X-API-Key: dev-api-key-123" https://api.hoangvu75.space/helloworld
```

## Adding a New App Behind Kong

### 1. Add Kong Route (Ingress)

Create a new Ingress for your app with `ingressClassName: kong`:

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
                name: my-app-service     # Must be in kong namespace or use ExternalName
                port:
                  number: 8080
```

If the backend service is in a different namespace, create an ExternalName service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: kong
spec:
  type: ExternalName
  externalName: my-app-service.my-app-ns.svc.cluster.local
```

### 2. Add Routing to Kong

The `httproute-kong.yaml` routes `api.hoangvu75.space/*` → `kong-proxy:80`. If you want a different hostname, create a new HTTPRoute.

### 3. Add Consumer Credentials (Optional)

To add API keys for different consumers:

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
| Namespace override by ArgoCD | `destNamespace: kong` forces all resources to kong ns | Use ExternalName services for cross-namespace backends |
| `KONG_KIC=on` hard-coded by Helm chart | env.kic: off is overridden | Cannot disable KIC via values — keep enabled and use CRDs |
