## 🐙 Cài đặt ArgoCD

### 1. Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Bật Helm cho Kustomize (bắt buộc vì app dùng helmCharts) — chạy lại sau mỗi lần reset cluster
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'
kubectl rollout restart deployment argocd-repo-server -n argocd
```
### 2. Expose UI (NodePort)
Để truy cập từ ngoài vào (qua IP của Node), ta chuyển service server sang dạng NodePort:

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

### 3. Lấy Password admin ban đầu
Username mặc định: `admin`
Password nằm trong secret `argocd-initial-admin-secret`:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
