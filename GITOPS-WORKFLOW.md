# GitOps Workflow

## Bootstrap

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Bật Helm cho Kustomize (bắt buộc vì app dùng helmCharts trong kustomization) — 1 lần sau khi cài Argo CD
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'
kubectl rollout restart deployment argocd-repo-server -n argocd
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

### root Degraded / không thấy playground-n8n, playground-jenkins

ApplicationSet dùng **directories** generator (`apps/playground/*`, `apps/infra/*`) — discover theo thư mục, không dùng file glob. Không cần bật flag trên cluster (GitOps thuần).

1. **Đảm bảo Git đã có** `projects/playground.yaml` và `projects/infra.yaml` với generator `directories` (path `apps/playground/*`, `apps/infra/*`). Push nếu chưa.

2. **Xóa Application sai** (nếu còn từ lần cũ): `playground-playground`, `infra-infra` (path sai).
   ```bash
   kubectl delete application playground-playground infra-infra -n argocd --ignore-not-found
   ```

3. **Hard refresh root**: Argo CD UI → **root** → **REFRESH** → **HARD REFRESH**.

Sau vài phút sẽ thấy **playground-n8n**, **playground-jenkins**, **playground-ingress-nginx**, **playground-metallb**, **infra-metallb-system**.

### App không load / ComparisonError "must specify --enable-helm"

Kustomize có `helmCharts` cần Argo CD build với `--enable-helm`. Cấu hình toàn cục (1 lần):

```bash
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'
kubectl rollout restart deployment argocd-repo-server -n argocd
```

Sau đó Hard refresh từng app (hoặc REFRESH APP) trong UI.

### infra-metallb-system Sync failed / Missing (IPAddressPool, L2Advertisement)

CRD MetalLB chưa có trên cluster. Cần **playground-metallb** (Helm chart MetalLB) sync thành công trước để cài CRD. Thứ tự: fix "must specify --enable-helm" → sync playground-metallb → sync lại infra-metallb-system.

### Lệnh chung

```bash
kubectl get applications -n argocd
kubectl describe applicationset playground infra -n argocd
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller --tail=100
# Force refresh: kubectl delete application bootstrap -n argocd; kubectl apply -f bootstrap.yaml
```
