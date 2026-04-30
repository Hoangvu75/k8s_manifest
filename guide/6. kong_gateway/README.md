# Kong Gateway with API Key and OAuth2 Authentication

This guide describes how Kong Gateway is deployed as an API authentication layer between Traefik and backend applications.

## Architecture

```
Cloudflare → Traefik (shared-gateway) → Kong (key-auth / oauth2) → helloworld-api
```

## Traffic Flow

1. **Traefik** receives traffic for `api.hoangvu75.space` via `HTTPRoute kong-ingress`
2. **HTTPRoute** routes to `kong-proxy:80` (Kong Proxy Service)
3. **Kong Gateway** validates authentication (either `X-API-Key` header or `Authorization: Bearer <token>`) using `key-auth` and `oauth2` plugins
4. **KIC** (Kong Ingress Controller) manages Kong routing via:
   - `Ingress` → translates to Kong routes
   - `KongPlugin` → enables auth on routes
   - `KongConsumer` + `Secret` → creates credentials (API keys, OAuth2 clients)
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
| `chart/plugins/key-auth-plugin.yaml` | KongPlugin CRD for key-auth |
| `chart/plugins/oauth2-plugin.yaml` | KongPlugin CRD for OAuth2 (Client Credentials flow) |
| `chart/consumers/default-user-consumer.yaml` | KongConsumer + key-auth credential Secret |
| `chart/consumers/oauth2-client-consumer.yaml` | KongConsumer + OAuth2 credential Secret |
| `chart/ingress/helloworld-api-ingress.yaml` | KIC Ingress: routes /helloworld → helloworld-api:5678 (key-auth) |
| `chart/ingress/oauth2-token-ingress.yaml` | KIC Ingress: routes /auth → helloworld-api:5678 (oauth2 token endpoint) |
| `chart/services/helloworld-api-service.yaml` | Cross-namespace ExternalName bridge (kong-gateway → helloworld-api) |

## Testing

### API Key Authentication

```bash
# Without API key (should return 401)
curl -v https://api.hoangvu75.space/helloworld

# With API key (should return 200)
curl -v -H "X-API-Key: dev-api-key-123" https://api.hoangvu75.space/helloworld
```

### OAuth2 Client Credentials Flow

The OAuth2 token endpoint and the API endpoint are **different routes** — `key-auth` and `oauth2` cannot be stacked on the same path, so the token endpoint uses a dedicated `/auth` path:

| Endpoint | Purpose | Auth Plugin |
|----------|---------|-------------|
| `POST https://api.hoangvu75.space/auth/oauth2/token` | Exchange client credentials for an access token | oauth2 only |
| `https://api.hoangvu75.space/helloworld` | Actual API (requires `X-API-Key` header) | key-auth |

**Step 1** — Get an access token:

```bash
curl -s -X POST https://api.hoangvu75.space/auth/oauth2/token \
  -d "client_id=kong-oauth2-client" \
  -d "client_secret=changeme-oauth2-secret" \
  -d "grant_type=client_credentials" \
  -d "scope=read"
```

**Step 2** — Use the token by creating an OAuth2-protected Ingress (see below).

> **Note**: The `oauth2` plugin can only be applied to Ingresses without `key-auth`. To create an OAuth2-protected API route, create a new Ingress with `konghq.com/plugins: oauth2` (without `key-auth`) and point it to your backend service. Then access it with `Authorization: Bearer <token>`.

> The Kong Gateway is managed via CRDs in `plugins/`, `consumers/`, `ingress/`, `services/` directories. No dashboard is needed — routes are configured through `Ingress` resources.

### Adding an OAuth2 Client

To add an OAuth2 client application, create a file in `chart/consumers/`:

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: my-oauth2-client
  annotations:
    kubernetes.io/ingress.class: kong
username: my-oauth2-client
credentials:
  - my-oauth2-credential
---
apiVersion: v1
kind: Secret
metadata:
  name: my-oauth2-credential
  labels:
    konghq.com/credential: oauth2
  annotations:
    kubernetes.io/ingress.class: kong
stringData:
  client_id: my-client-id
  client_secret: my-client-secret
  name: My OAuth2 App
  redirect_uris: "[]"
type: Opaque
```

Then reference the OAuth2 plugin in your Ingress annotation (must be a separate Ingress from key-auth):
```yaml
annotations:
  konghq.com/plugins: oauth2
```

Keep `key-auth` and `oauth2` on **different** Ingresses — they cannot be stacked on the same path.

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

#### API Key (key-auth)

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
| OAuth2 in DB-less mode | Auth code / implicit grants require runtime DB | Only Client Credentials flow works in DB-less mode |