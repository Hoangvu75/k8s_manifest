# GitOps Workflow

## Bootstrap

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f https://raw.githubusercontent.com/Hoangvu75/k8s_manifest/master/bootstrap.yaml
```

Chỉ cần apply **bootstrap.yaml** (ở root repo). Application "bootstrap" sync folder **bootstrap/** → apply root.yaml, cluster-resources.yaml. Root sync projects/, cluster-resources ApplicationSet sync cluster-resources/default/ (namespace).

## Cấu trúc

```
bootstrap.yaml (root)            → Application sync bootstrap/
bootstrap/root.yaml              → sync projects/
bootstrap/cluster-resources.yaml → ApplicationSet, Application sync cluster-resources/default/
projects/playground.yaml, infra.yaml
cluster-resources/default/namespace.yaml
apps/playground/<app>/, apps/infra/<app>/
```

## Thêm app playground

- Tạo `apps/playground/<app>/config.yaml`, `kustomization.yaml`, `chart/kustomization.yaml` (+ values). ApplicationSet playground tự discover.

## Thêm app Helm từ repo công khai

- Cùng cấu trúc playground: config.yaml, kustomization.yaml, chart/kustomization.yaml (helmCharts repo URL), chart/values.yaml.

## Update / Xóa app

- Sửa hoặc xóa thư mục app trong `apps/playground/` hoặc `apps/infra/`, push Git. Argo CD sync/auto-prune.

## Troubleshooting

```bash
kubectl get applications -n argocd
kubectl describe applicationset playground infra -n argocd
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller --tail=100
# Force refresh: kubectl delete application bootstrap -n argocd; kubectl apply -f bootstrap.yaml
```
