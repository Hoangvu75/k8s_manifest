## 🐙 ArgoCD Installation

### 1. Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Enable Helm for Kustomize (required for apps using helmCharts) — run again after cluster reset
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'
kubectl rollout restart deployment argocd-repo-server -n argocd
```
### 2. Expose UI

**Ingress (GitOps):** The `playground-argocd` app deploys Ingress automatically. The Service keeps **ClusterIP** (default). Access via **https://argocd.localhost** — no port-forward needed. If previously patched to NodePort, revert: `kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"ClusterIP"}}'`

**port-forward (manual):** Use ClusterIP, no service change needed:
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```
Then open https://localhost:8080

**NodePort:** Only if direct access via NodeIP:Port is needed (without Ingress):
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
# Get port: kubectl get svc argocd-server -n argocd
```

### 3. Get Initial Admin Password
Default username: `admin`
Password is in the `argocd-initial-admin-secret` secret:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
