# Bootstrap K8s Cluster với ArgoCD

Thư mục này chứa các manifest để bootstrap ArgoCD ApplicationSet.

## Thứ tự deploy

### 1. Cài ArgoCD (nếu chưa có)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Đợi pods ready
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

### 2. Apply ApplicationSet

```bash
kubectl apply -f https://raw.githubusercontent.com/Hoangvu75/k8s_manifest/refs/heads/master/bootstrap/applicationsets.yaml
```

ApplicationSet sẽ tự động tạo các Application:
- `metallb` - LoadBalancer cho cluster
- `ingress-nginx` - Ingress controller
- `argocd` - ArgoCD UI với Ingress

### 3. Đợi MetalLB deploy (khoảng 2-3 phút)

```bash
kubectl get pods -n metallb-system -w
```

### 4. Apply MetalLB config (sau khi MetalLB pods đã Running)

```bash
kubectl apply -f https://raw.githubusercontent.com/Hoangvu75/k8s_manifest/refs/heads/master/bootstrap/metallb-config.yaml

# Kiểm tra
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
```

### 5. Kiểm tra ingress-nginx có External IP

```bash
kubectl get svc -n ingress-nginx

# Bạn sẽ thấy:
# NAME                       TYPE           EXTERNAL-IP       PORT(S)
# ingress-nginx-controller   LoadBalancer   192.168.56.200    80:xxxxx/TCP,443:xxxxx/TCP
```

### 6. Truy cập ArgoCD

```bash
# Lấy password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo

# Username: admin
# URL: http://argocd.192.168.56.200.nip.io
```

## IP Pool MetalLB

MetalLB được cấu hình với IP pool: `192.168.56.200-192.168.56.210`

- `192.168.56.200` - Dành cho ingress-nginx
- `192.168.56.201-210` - Dành cho các services khác

## Troubleshooting

### Applications không được tạo

```bash
# Xem logs applicationset-controller
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller --tail=50

# Restart controller
kubectl rollout restart deployment argocd-applicationset-controller -n argocd
```

### Ingress-nginx không có External IP

```bash
# Kiểm tra MetalLB pods
kubectl get pods -n metallb-system

# Kiểm tra logs
kubectl logs -n metallb-system -l app=metallb,component=controller

# Kiểm tra config
kubectl get ipaddresspool,l2advertisement -n metallb-system
```

### Không truy cập được ArgoCD

```bash
# Kiểm tra ingress
kubectl get ingress -n argocd
kubectl describe ingress -n argocd

# Kiểm tra ingress-nginx logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=50
```

