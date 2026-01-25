# Applications

Thư mục này chứa các application được deploy bởi ArgoCD ApplicationSet.

## Cấu trúc

Mỗi app có một thư mục riêng với file `application.yaml` định nghĩa metadata và config.

```
apps/
├── ingress-nginx/
│   └── application.yaml
├── argocd/
│   └── application.yaml
└── your-app/
    └── application.yaml
```

## Cách thêm app mới

### Option 1: Deploy từ Helm Chart có sẵn

```yaml
# apps/my-app/application.yaml
app:
  name: my-app
  namespace: my-app
  source:
    repoURL: https://charts.example.com
    chart: my-app
    targetRevision: 1.0.0
  values: |
    replicas: 2
    service:
      type: ClusterIP
```

### Option 2: Dùng bjw-s app-template

Để deploy custom app bằng bjw-s app-template:

```yaml
# apps/custom-app/application.yaml
app:
  name: custom-app
  namespace: custom-app
  source:
    repoURL: https://bjw-s-labs.github.io/helm-charts
    chart: app-template
    targetRevision: 3.0.0
  values: |
    controllers:
      main:
        containers:
          main:
            image:
              repository: nginx
              tag: alpine
    service:
      main:
        ports:
          http:
            port: 80
    ingress:
      main:
        enabled: true
        className: nginx
        hosts:
          - host: custom-app.192.168.56.200.nip.io
            paths:
              - path: /
                pathType: Prefix
```

## Sau khi thêm app

1. Commit và push:
```bash
git add apps/your-app/
git commit -m "Add your-app"
git push
```

2. ArgoCD sẽ tự động phát hiện và deploy (nhờ `automated: selfHeal: true`)

3. Kiểm tra:
```bash
kubectl get applications -n argocd
kubectl get pods -n your-app
```

## Tham khảo

- [bjw-s app-template docs](https://bjw-s-labs.github.io/helm-charts/docs/app-template/)
- [ArgoCD ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)

