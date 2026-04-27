## 🐙 What is k8s_manifest_secrets
The repo url: 
```bash
https://github.com/Hoangvu75/k8s_manifest_secrets
```
This contains secrets env variable (K8s Secret resource files):
```yaml 
cloudflared-secret.yaml

apiVersion: v1
kind: Secret
metadata:
  name: cloudflared-credentials
  namespace: cloudflared
type: Opaque
stringData:
  TUNNEL_TOKEN: "eyJhIjoiMjQ4ODk2...VExTldNeiJ9"
```
```yaml 
datadog-secret.yaml

apiVersion: v1
kind: Secret
metadata:
  name: datadog-key
  namespace: datadog
type: Opaque
stringData:
  api-key: "44d5...853"
```
```yaml 
wildcard-tls-secret.yaml

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
