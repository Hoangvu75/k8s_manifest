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
- **Template công ty:** App dùng chart chung (standalone-app) qua OCI: `chart/kustomization.yaml` chỉ có `helmCharts` (name, repo oci://YOUR_OCI_REGISTRY/..., version, valuesFile, additionalValuesFiles); dùng OCI registry của bạn, không dùng registry/image công ty; không thêm chart hay thư mục chart khác trong app.

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

**Bắt buộc:** Đợi repo-server Ready (`kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-repo-server`), rồi **refresh** để Argo CD build lại manifest với `--enable-helm`:

- **Cách 1 (UI):** Trang Applications → nút **REFRESH APPS** (refresh tất cả), hoặc mở từng app → **REFRESH** → **HARD REFRESH**.
- **Cách 2 (CLI):** Refresh từng app bằng argocd CLI hoặc xóa cache bằng cách set annotation:
  ```bash
  kubectl patch app root -n argocd -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' --type merge
  kubectl patch app playground-jenkins -n argocd -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' --type merge
  # Lặp cho playground-n8n, playground-metallb, playground-ingress-nginx, infra-metallb-system
  ```
  Hoặc dùng vòng lặp: `for a in root playground-jenkins playground-n8n playground-metallb playground-ingress-nginx infra-metallb-system; do kubectl patch app $a -n argocd -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' --type merge; done`

### Chart chung (standalone-app) — định nghĩa repo trong helmCharts

Chart **không nằm trong repo k8s_manifest** (nằm repo khác). Bạn đóng gói chart đó, **push lên OCI registry**, rồi trong `chart/kustomization.yaml` khai báo `repo: oci://YOUR_OCI_REGISTRY/charts/standalone-app` (thay bằng registry thật). Argo CD / Kustomize sẽ `helm pull` từ URL đó khi build — dùng được bình thường. Format: `helmCharts` với `name`, `repo`, `version`, `valuesFile`, `additionalValuesFiles` (không dùng helmGlobals/chartHome). Hướng dẫn đóng gói và push: `k8s_setup/helm_chart_registry.md`.

### 401 unauthorized khi pull chart OCI (Docker Hub)

Repo-server Argo CD chạy trong cluster, không có credential Docker Hub của bạn → `helm pull` bị 401. Chọn một trong hai cách:

**Cách 1 — Cho repo Docker Hub thành Public (đơn giản nhất):**  
Vào https://hub.docker.com/repository/docker/hoangvu753/standalone-app/general → **Settings** → **Make public**. Sau đó Argo CD pull không cần đăng nhập.

**Cách 2 — Thêm credential OCI trong Argo CD:**  
Trong Argo CD UI: **Settings** → **Repositories** → **Connect Repo** → chọn **VIA HELM** (hoặc **Connect repo using URL**). Điền:
- **Repository URL:** `oci://registry-1.docker.io/hoangvu753/standalone-app`
- **Username:** Docker Hub username (vd. `hoangvu753`)
- **Password:** Docker Hub Personal Access Token  
Lưu. Hoặc dùng CLI (cài argocd):  
`argocd repo add oci://registry-1.docker.io/hoangvu753/standalone-app --type helm --username hoangvu753 --password YOUR_TOKEN --enable-oci`

Sau khi thêm repo hoặc đổi sang public, **Hard refresh** lại app (playground-jenkins, playground-n8n).

### infra-metallb-system Sync failed / Missing (IPAddressPool, L2Advertisement)

CRD MetalLB chưa có trên cluster. Cần **playground-metallb** (Helm chart MetalLB) sync thành công trước để cài CRD. Thứ tự: fix "must specify --enable-helm" → sync playground-metallb → sync lại infra-metallb-system.

### Lệnh chung

```bash
kubectl get applications -n argocd
kubectl describe applicationset playground infra -n argocd
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller --tail=100
# Force refresh: kubectl delete application bootstrap -n argocd; kubectl apply -f bootstrap.yaml
```
