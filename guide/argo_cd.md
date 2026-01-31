## 🐙 Cài đặt ArgoCD

### 1. Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Bật Helm cho Kustomize (bắt buộc vì app dùng helmCharts) — chạy lại sau mỗi lần reset cluster
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'
kubectl rollout restart deployment argocd-repo-server -n argocd
```
### 2. Expose UI

**Ingress (GitOps):** App `playground-argocd` deploy Ingress tự động. Service giữ **ClusterIP** (mặc định). Truy cập **https://argocd.localhost** — không cần port-forward. Nếu trước đó đã patch sang NodePort, revert: `kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"ClusterIP"}}'`

**port-forward (thủ công):** Dùng ClusterIP, không cần đổi service:
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```
Rồi mở https://localhost:8080

**NodePort:** Chỉ khi cần truy cập trực tiếp qua NodeIP:Port (không dùng Ingress):
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
# Lấy port: kubectl get svc argocd-server -n argocd
```

### 3. Lấy Password admin ban đầu
Username mặc định: `admin`
Password nằm trong secret `argocd-initial-admin-secret`:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
