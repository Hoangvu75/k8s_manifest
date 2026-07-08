# 🕸️ Istio Service Mesh (Sidecar mode)

Học Istio service mesh trên cụm này, **giữ nguyên luồng north-south hiện tại** (Cloudflare → Traefik → Kong). Istio chỉ làm **mesh east-west** (traffic pod↔pod): mTLS tự động + authorization + observability, **không đụng** Traefik/Kong/cloudflared.

> ⚠️ **Vì sao sidecar chứ không ambient?**
> Kernel WSL2 của Docker Desktop (`*-microsoft-standard-WSL2`) **thiếu module netfilter `CONNMARK`** mà Ambient mode (istio-cni + ztunnel) cần để redirect traffic → istio-cni fail `AddPodToMesh ... exit status 2` và **không pod nào enroll được**. Sidecar mode dùng interception REDIRECT (không cần CONNMARK) nên chạy được trên kernel này.
> Muốn dùng Ambient: đổi kernel WSL2 (build có CONNMARK) hoặc chuyển sang minikube.

## Kiến trúc

```
North-south (giữ nguyên):  Internet → Cloudflare → cloudflared → Traefik → Kong → app
East-west  (Istio thêm):   mỗi pod có 1 sidecar Envoy -> mTLS + AuthorizationPolicy giữa các service
```

## Thành phần (đã tối giản)

| App (ArgoCD) | Chart | Vai trò |
|--------------|-------|---------|
| `infra-istio-base` | istio/base | CRDs + cluster roles (ServerSideApply=true) |
| `infra-istiod` | istio/istiod (profile mặc định) | Control plane + mutating webhook tiêm sidecar |
| `infra-istio-demo` | httpbin + client + AuthorizationPolicy | Sân chơi học tập |

> Đã **bỏ** `istio-cni`, `istio-ztunnel` (chỉ dùng cho ambient), `istio-ingress` và waypoint (giữ luồng Traefik).
> 4 chart core dùng version **1.30.2** — kiểm tra bản mới tại https://github.com/istio/istio/releases.

## Bật mesh cho một namespace

Gắn nhãn `istio-injection: enabled` cho namespace (đã set sẵn cho `helloworld-api`, `kong-gateway`, `istio-demo` trong [namespace.yaml](../../cluster-resources/default/namespace.yaml)).

⚠️ **Sidecar chỉ được tiêm khi pod ĐƯỢC TẠO** → pod cũ phải **restart** mới có sidecar:
```bash
kubectl rollout restart deploy -n <namespace>
# pod chuyển từ 1/1 -> 2/2 (thêm container istio-proxy) là thành công
```

## Ứng dụng thực tế: bịt lỗ bypass Kong

Kong chỉ chặn đường qua Traefik (`api.hoangvu75.space`). Trong cluster, bất kỳ pod nào cũng gọi thẳng `helloworld-api:5678` được, **bỏ qua key-auth**:
```bash
kubectl exec -n cluster-check deploy/cluster-check -- curl -s -o /dev/null -w "%{http_code}\n" http://helloworld-api.helloworld-api:5678/helloworld   # 200 (hở!)
```
[AuthorizationPolicy](../../apps/applications/helloworld-api/chart/authorization-policy.yaml) chỉ cho principal `cluster.local/ns/kong-gateway/sa/kong` gọi helloworld-api → sau khi cả 2 ns có sidecar, lệnh trên thành **403**, còn đường qua Kong (có API key) vẫn 200.

## Triển khai

```bash
git add -A && git commit -m "istio: switch to sidecar mode, drop ambient components" && git push
```
Sau khi ArgoCD sync (prune ztunnel/cni/ingress, istiod về profile mặc định), **restart pod** ở các ns đã bật injection:
```bash
kubectl rollout restart deploy -n istio-system istiod       # đảm bảo webhook mới
kubectl rollout restart deploy -n helloworld-api
kubectl rollout restart deploy -n kong-gateway
kubectl rollout restart deploy -n istio-demo
```

## Verify

```bash
# 1) Sidecar đã tiêm chưa (pod phải 2/2)
kubectl get pods -n istio-demo -n helloworld-api -n kong-gateway

# 2) Bịt bypass Kong: gọi thẳng -> 403 (trước là 200)
kubectl exec -n cluster-check deploy/cluster-check -- curl -s -o /dev/null -w "bypass -> %{http_code}\n" http://helloworld-api.helloworld-api:5678/helloworld

# 3) Đường hợp lệ qua Kong (có key) -> 200
kubectl exec -n cluster-check deploy/cluster-check -- curl -s -o /dev/null -w "via Kong -> %{http_code}\n" -H "X-API-Key: dev-api-key-123" http://kong-proxy.kong-gateway:80/helloworld

# 4) Demo authz: GET 200, POST 403
kubectl exec -n istio-demo deploy/demo-client -- curl -s -o /dev/null -w "GET  -> %{http_code}\n" httpbin:8000/get
kubectl exec -n istio-demo deploy/demo-client -- curl -s -o /dev/null -w "POST -> %{http_code}\n" -X POST httpbin:8000/post
```

Nếu pod **không lên 2/2** (initContainer `istio-init` CrashLoop báo lỗi iptables/CONNMARK) → kernel WSL2 chặn cả sidecar → phải chuyển minikube hoặc sửa kernel WSL2.

## Rollback

Bỏ nhãn `istio-injection: enabled` khỏi namespace + `rollout restart` → pod tạo lại không có sidecar, về như cũ.
