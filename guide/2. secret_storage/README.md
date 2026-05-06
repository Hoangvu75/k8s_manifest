## 🐙 What is k8s_manifest_secrets
https://github.com/Hoangvu75/k8s_manifest_secrets

### This private repo contains secrets env variable (K8s Secret resource files):

**cloudflared-secret.yaml** (Cloudflare tunnel authentication)
Used by `apps/infra/cloudflared` to establish a secure tunnel to Cloudflare CDN.
```yaml 
apiVersion: v1
kind: Secret
metadata:
  name: cloudflared-credentials
  namespace: cloudflared
type: Opaque
stringData:
  TUNNEL_TOKEN: "eyJhIjoiMjQ4ODk2...VExTldNeiJ9"
```
**datadog-secret.yaml** (Datadog API key)
Used by `apps/infra/datadog` to send cluster metrics and logs to Datadog.
```yaml 
apiVersion: v1
kind: Secret
metadata:
  name: datadog-key
  namespace: datadog
type: Opaque
stringData:
  api-key: "44d5...853"
```
**wildcard-tls-secret.yaml** (Wildcard TLS certificate)
Used by `apps/infra/gateway-api` for HTTPS termination on the shared Gateway (`*.hoangvu75.space`).
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: wildcard-tls
  namespace: gateway-api
  annotations:
    argocd.argoproj.io/sync-wave: "1"
type: kubernetes.io/tls
data:
  tls.crt: LS0tL...0tLQ0K
  tls.key: LS0tL...tLS0NCg==
```
**registry-credentials.yaml** (Docker Hub + GHCR image pull credentials)
Used by multiple apps as `imagePullSecrets` to pull images from private registries (see table below for the full list).
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: registry-credentials
  namespace: helloworld-api
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: ey...Cg==
---
apiVersion: v1
kind: Secret
metadata:
  name: registry-credentials
  namespace: gateway-api
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: ey...Cg==
---
...
```
**arc-github-config.yaml** (GitHub Actions Runner Controller auth)
Used by `apps/infra/arc-runner-set` to register runners with GitHub.
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: arc-github-config
  namespace: arc-runners
type: Opaque
stringData:
  github_token: "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```
