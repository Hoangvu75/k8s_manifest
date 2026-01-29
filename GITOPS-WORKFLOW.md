# GitOps Workflow

## 📖 Triết lý GitOps

```
Git = Single Source of Truth
↓
Push to Git
↓
ArgoCD tự động phát hiện và deploy
↓
Không bao giờ apply trực tiếp
```

## 🚀 Bootstrap Cluster Mới (1 lần duy nhất)

### Bước 1: Cài đặt ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Bước 2: Apply ApplicationSets (1 lần duy nhất)

```bash
kubectl apply -f https://raw.githubusercontent.com/Hoangvu75/k8s_manifest/master/bootstrap/applicationsets.yaml
```

### Bước 3: Apply MetalLB Config (1 lần duy nhất)

```bash
kubectl apply -f https://raw.githubusercontent.com/Hoangvu75/k8s_manifest/master/bootstrap/metallb-config.yaml
```

**Done!** ApplicationSets sẽ tự động:
1. Scan Git repo
2. Tìm tất cả apps trong `apps/git-based/*/app.yaml` và `apps/helm-based/*/app.yaml`
3. Tự động tạo ArgoCD Applications
4. Deploy tất cả lên cluster

## 📁 Cấu trúc Repo

```
k8s_manifest/
├── bootstrap/
│   ├── applicationsets.yaml      # ApplicationSets definitions
│   └── metallb-config.yaml       # MetalLB IPAddressPool & L2Advertisement
│
└── apps/
    ├── git-based/                # Apps với Helm charts trong Git
    │   └── n8n/
    │       ├── app.yaml          # ArgoCD config
    │       ├── Chart.yaml
    │       ├── values.yaml
    │       └── templates/
    │
    └── helm-based/               # Apps từ public Helm repos
        ├── ingress-nginx/
        │   └── app.yaml          # ArgoCD config với Helm values
        └── metallb/
            └── app.yaml
```

## ✨ Thêm Application Mới

### Option 1: Git-based App (Custom Helm Chart)

```bash
# 1. Tạo folder
mkdir -p apps/git-based/myapp

# 2. Tạo Helm chart
apps/git-based/myapp/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml

# 3. Tạo app.yaml
cat > apps/git-based/myapp/app.yaml <<EOF
app:
  name: myapp
  namespace: myapp
  source:
    repoURL: https://github.com/Hoangvu75/k8s_manifest.git
    targetRevision: master
    path: apps/git-based/myapp
  values: ""
EOF

# 4. Push lên Git
git add apps/git-based/myapp/
git commit -m "Add myapp"
git push origin master

# 5. Đợi 1-3 phút, ArgoCD tự động phát hiện và deploy
```

### Option 2: Helm-based App (Public Helm Repo)

```bash
# 1. Tạo folder
mkdir -p apps/helm-based/prometheus

# 2. Tạo app.yaml
cat > apps/helm-based/prometheus/app.yaml <<EOF
app:
  name: prometheus
  namespace: monitoring
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    targetRevision: 25.8.0
    chart: kube-prometheus-stack
  values: |
    grafana:
      enabled: true
      adminPassword: admin123
EOF

# 3. Push lên Git
git add apps/helm-based/prometheus/
git commit -m "Add Prometheus"
git push origin master

# 4. Đợi 1-3 phút, ArgoCD tự động phát hiện và deploy
```

## 🔄 Update Application

```bash
# 1. Sửa values trong app.yaml hoặc values.yaml
vim apps/helm-based/ingress-nginx/app.yaml

# 2. Push lên Git
git add apps/helm-based/ingress-nginx/app.yaml
git commit -m "Update ingress-nginx config"
git push origin master

# 3. ArgoCD tự động sync (hoặc manual sync trong UI)
```

## 🗑️ Xóa Application

```bash
# 1. Xóa folder
rm -rf apps/git-based/myapp

# 2. Push lên Git
git add -A
git commit -m "Remove myapp"
git push origin master

# 3. ArgoCD tự động xóa Application (auto-prune enabled)
```

## 🔍 Monitor Applications

```bash
# Xem tất cả Applications
kubectl get applications -n argocd

# Xem chi tiết
kubectl describe application myapp -n argocd

# Xem ApplicationSets
kubectl get applicationset -n argocd

# Xem logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller --tail=50
```

## ⚠️ Nguyên tắc GitOps

### ✅ DO (Làm)

- ✅ Mọi thay đổi đều commit và push lên Git
- ✅ Để ArgoCD tự động sync
- ✅ Manual sync qua ArgoCD UI nếu cần
- ✅ Review changes trong Git trước khi merge
- ✅ Use Pull Requests cho production

### ❌ DON'T (Không làm)

- ❌ **KHÔNG BAO GIỜ** `kubectl apply` trực tiếp
- ❌ **KHÔNG BAO GIỜ** tạo manual Applications ngoài ApplicationSets
- ❌ **KHÔNG BAO GIỜ** edit resources trực tiếp trong cluster
- ❌ **KHÔNG BAO GIỜ** bypass Git để thay đổi

## 🎯 Current Applications

Sau khi bootstrap, cluster sẽ có:

```
✅ metallb          (LoadBalancer provider)
✅ ingress-nginx    (Ingress Controller - IP 192.168.56.200)
✅ n8n              (Workflow automation)
```

Access n8n: http://n8n.192.168.56.200.nip.io

## 🔧 Troubleshooting

### ApplicationSet không tạo Applications

```bash
# 1. Check ApplicationSet status
kubectl describe applicationset git-based-apps -n argocd
kubectl describe applicationset helm-based-apps -n argocd

# 2. Check logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller --tail=100

# 3. Force refresh
kubectl delete applicationset git-based-apps helm-based-apps -n argocd
kubectl apply -f bootstrap/applicationsets.yaml
```

### Application stuck in OutOfSync

```bash
# Manual sync
kubectl patch application myapp -n argocd \
  --type merge \
  -p '{"operation":{"sync":{"revision":"HEAD"}}}'

# Hoặc sync qua ArgoCD UI
```

### Repo-server connection refused

```bash
# Restart components
kubectl rollout restart deployment argocd-repo-server -n argocd
kubectl rollout restart deployment argocd-applicationset-controller -n argocd
```

## 📊 Benefits

1. **Traceability**: Mọi thay đổi đều có Git history
2. **Reproducibility**: Bootstrap cluster mới chỉ với 3 commands
3. **Rollback**: `git revert` để rollback changes
4. **Collaboration**: Pull Requests, code review
5. **Disaster Recovery**: Rebuild cluster từ Git
6. **Compliance**: Audit trail trong Git
7. **Consistency**: Mọi cluster đều giống nhau

## 🚀 Next Steps

1. Setup CI/CD pipeline để test Helm charts trước khi merge
2. Add monitoring (Prometheus, Grafana)
3. Add logging (Loki, Promtail)
4. Add secret management (Sealed Secrets, External Secrets)
5. Multi-cluster setup với ApplicationSets

---

**Remember**: Git is the single source of truth. Never bypass it! 🎯
