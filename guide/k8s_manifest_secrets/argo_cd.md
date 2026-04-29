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
