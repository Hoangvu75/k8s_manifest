# 🕸️ Istio Service Mesh (Ambient mode)

Mục tiêu: học Istio **Ambient Mesh** (sidecar-less) và **thay dần Traefik** bằng Istio cho cả ingress lẫn mesh, theo đúng chuẩn GitOps của repo (ArgoCD + Kustomize + Helm).

> Nguyên tắc: **cài song song, không phá Traefik**. Chỉ gỡ Traefik ở bước cutover cuối cùng, sau khi Istio ingress đã verify chạy ổn.

## Kiến trúc 2 loại traffic

| Loại | Trước (hiện tại) | Sau (đích) |
|------|------------------|-----------|
| North-south (internet → cluster) | Cloudflare → Traefik → shared-gateway | Cloudflare → **istio-ingress** |
| East-west (pod ↔ pod) | *(không có mesh)* | **Ambient**: ztunnel (mTLS L4) + waypoint (L7) |

Ambient = không sidecar. Pod trong namespace gắn label `istio.io/dataplane-mode: ambient` sẽ tự động được **ztunnel** (proxy L4 per-node) bọc mTLS. Muốn policy L7 (method/path/retry) thì thêm **waypoint** cho service.

## Đã scaffold gì

| App (ArgoCD) | Chart | Wave | Vai trò |
|--------------|-------|------|---------|
| `infra-istio-base` | istio/base | 0 | CRDs + cluster roles (ServerSideApply=true) |
| `infra-istiod` | istio/istiod (`profile: ambient`) | 1 | Control plane |
| `infra-istio-cni` | istio/cni (`profile: ambient`) | 1 | Node agent redirect traffic |
| `infra-istio-ztunnel` | istio/ztunnel | 2 | Data plane L4 (mTLS toàn mesh) |
| `infra-istio-ingress` | Gateway API (`gatewayClassName: istio`) | 3 | Ingress gateway **song song** Traefik |
| `infra-istio-demo` | httpbin + client + waypoint + AuthorizationPolicy + HTTPRoute | 4 | Sân chơi học tập |

> ⚠️ **Version**: 4 chart core đang để `1.30.2` (bản Latest tại thời điểm setup).
> Kiểm tra bản stable mới nhất ở https://github.com/istio/istio/releases và giữ **cùng version** cho cả 4.

> ⚠️ **ServerSideApply**: CRD Istio rất lớn, client-side apply sẽ lỗi `metadata.annotations: Too long`.
> Đã set annotation `ServerSideApply=true` cho app `istio-base`. (Field `syncPolicy` trong `config.yaml`
> KHÔNG có tác dụng — ApplicationSet template hardcode `syncPolicy`, không đọc field này.)

## Triển khai

```bash
git add apps/infra/istio-* cluster-resources/default/namespace.yaml guide/9.*
git commit -m "add istio ambient mesh (parallel to traefik)"
git push
```

ArgoCD tự sync theo wave. Chờ tới khi các app xanh, rồi verify:

```bash
# Control plane
kubectl get pods -n istio-system            # istiod, istio-cni-node (DaemonSet), ztunnel (DaemonSet) đều Running
kubectl get gatewayclass                    # phải có "istio" và "istio-waypoint" (do istiod tạo)

# Ingress gateway tự sinh (tên = <gateway>-<class>)
kubectl get gateway,svc,deploy -n gateway-api | grep istio-ingress
```

## Bài học (theo phase)

### Phase 1 — Ambient mTLS "miễn phí"
Namespace `istio-demo` đã gắn `istio.io/dataplane-mode: ambient`. Mọi pod trong đó tự có mTLS mà **không cần khai báo gì**.
```bash
kubectl -n istio-demo exec deploy/demo-client -- curl -s httpbin:8000/get   # OK
```
Xem log ztunnel để thấy kết nối được mã hoá:
```bash
kubectl -n istio-system logs ds/ztunnel | grep istio-demo
```

### Phase 2 — Authorization (định danh + L7)
File `authorization-policy.yaml`: chỉ `demo-client` được GET httpbin.
```bash
# ALLOW
kubectl -n istio-demo exec deploy/demo-client -- curl -s -o /dev/null -w "%{http_code}\n" httpbin:8000/get
# DENY (403) — sai method
kubectl -n istio-demo exec deploy/demo-client -- curl -s -o /dev/null -w "%{http_code}\n" -X POST httpbin:8000/post
```
> Luật theo method là **L7** → cần **waypoint** (đã tạo). Bỏ waypoint → chỉ còn luật L4 theo định danh.

### Phase 3 — Ingress qua Istio (chưa cutover)
`httproute.yaml` expose httpbin qua `istio-ingress` (KHÔNG qua Traefik):
```bash
kubectl -n gateway-api port-forward svc/istio-ingress-istio 8443:443
curl -k --resolve httpbin.hoangvu75.space:8443:127.0.0.1 https://httpbin.hoangvu75.space:8443/get
```

### Phase 4 (tuỳ chọn) — Observability
- Cài Kiali/Prometheus để xem đồ thị mesh, hoặc bật tracing sang Datadog (mở comment `extensionProviders` trong `istiod/chart/values.yaml` + tạo resource `Telemetry`).

## 🔀 Cutover: thay Traefik bằng Istio

Chỉ làm khi Phase 3 đã chạy ngon. Các bước (mỗi bước verify trước khi sang bước sau):

1. **Chuyển HTTPRoute sang Istio ingress**: sửa `parentRefs` trong các route hiện có (argocd, rancher, traefik-dashboard, kong) từ `shared-gateway` → `istio-ingress`. Verify từng host qua port-forward như Phase 3.
2. **Chuyển "chủ sở hữu" Gateway API CRDs**: hiện CRDs được cài trong app `traefik-gateway` ([traefik-gateway/kustomization.yaml](../../apps/infra/traefik-gateway/kustomization.yaml) dòng `standard-install.yaml`). Trước khi gỡ Traefik, move dòng cài CRD này sang một app còn sống (vd `istio-ingress`) để không bị xoá mất.
3. **Trỏ Cloudflare tunnel sang Istio**: tunnel của bạn là **token-managed** → sửa ở **Cloudflare Zero Trust dashboard → Networks → Tunnels → (tunnel) → Public Hostnames**, đổi service đích sang `https://istio-ingress-istio.gateway-api.svc.cluster.local:443` (cloudflared chạy in-cluster nên dùng DNS ClusterIP được). Verify site public còn sống.
4. **Gỡ Traefik**: xoá thư mục `apps/infra/traefik-gateway/`, commit. ArgoCD prune.
   - ⚠️ TCP/UDP demo ([tcp-demo](../../apps/applications/tcp-demo/), [udp-demo](../../apps/applications/udp-demo/)) dùng `IngressRouteTCP/UDP` **riêng của Traefik** — Istio không có tương đương trực tiếp qua Gateway API TCP/UDPRoute. Migrate hoặc bỏ 2 demo này trước khi gỡ Traefik.

## Gỡ toàn bộ Istio (nếu cần)
Xoá các thư mục `apps/infra/istio-*` + 2 namespace (`istio-system`, `istio-demo`) trong `cluster-resources/default/namespace.yaml`, commit. Gỡ label `istio.io/dataplane-mode` khỏi namespace nào đã gắn.
