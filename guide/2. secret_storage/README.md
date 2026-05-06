## 🐙 What is k8s_manifest_secrets
https://github.com/Hoangvu75/k8s_manifest_secrets

### This private repo contains secrets env variable (K8s Secret resource files):

**cloudflared-secret.yaml**
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
**datadog-secret.yaml**
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
**wildcard-tls-secret.yaml**
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
**registry-credentials.yaml**
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

Option A — **Personal Access Token (PAT)**: classic PAT with `repo` scope (or `admin:org` for org-level runners):
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

Option B — **GitHub App** (recommended for production):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: arc-github-config
  namespace: arc-runners
type: Opaque
stringData:
  github_app_id: "123456"
  github_app_installation_id: "78901234"
  github_app_private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEA...
    -----END RSA PRIVATE KEY-----
```

> Use **only one** of the two formats. See `guide/7. github_action_runner/README.md` for how to create the PAT or GitHub App.
