## Ingress (khuyến nghị — dashboard không cần port-forward)

Chart bật **Ingress** (`ingressClassName: nginx`) tới Service edge **4566**:

- Host: **`localstack.hoangvu75.space`** (đổi trong `chart/values.yaml` nếu cần).
- Alias: **`localstack.localhost`** (thêm `127.0.0.1 localstack.localhost` trong `hosts` nếu truy cập Ingress qua IP máy bạn / Docker Desktop).

**Cloudflare Tunnel + DNS (hay gặp lỗi):**

1. Trong **Zero Trust → Networks → Tunnels → [tunnel] → Public Hostname**, thêm `localstack.hoangvu75.space` → `http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80` (giống Argo CD) là **chưa đủ** nếu DNS public không biết subdomain này.
2. **`DNS_PROBE_FINISHED_NXDOMAIN`:** tên `localstack.hoangvu75.space` **chưa có bản ghi DNS**. Vào **Cloudflare Dashboard → DNS → Records** của zone `hoangvu75.space`, thêm bản ghi mà Tunnel yêu cầu (thường **CNAME** `localstack` → `<id-tunnel>.cfargotunnel.com`, **Proxied**). Khi tạo Public Hostname, Cloudflare thường có nút **Save** kèm tùy chọn tự tạo DNS — bật / xác nhận bản ghi đã xuất hiện. So sánh với subdomain **đang chạy** (vd. `argocd`): nếu `argocd` có CNAME còn `localstack` không có → đúng bệnh NXDOMAIN.
3. **`404 nginx`:** DNS đã tới Ingress nhưng **không có Ingress rule** khớp `Host` (chưa deploy Ingress cho app đó, hoặc host gõ sai). Với LocalStack, kiểm tra Argo CD: Ingress `localstack` có host `localstack.hoangvu75.space`.

**Web dashboard (`app.localstack.cloud`):**

- Trang dashboard là **HTTPS** → endpoint phải là **`https://localstack.hoangvu75.space`** (hoặc domain bạn dùng). **Không** dùng `http://...` (mixed content, trình duyệt chặn).
- **Không** thêm **`:4566`** trên URL public: Ingress/Cloudflare lắng nghe **443** (và 80); cổng **4566** chỉ trong cluster. `https://...:4566` từ Internet hầu như luôn thất bại.
- `LOCALSTACK_HOST` trong `values.yaml` đã set **`localstack.hoangvu75.space:443`** để LocalStack trả URL đúng khi đi qua reverse proxy.

**Kiểm tra nhanh:** `curl -sS -o /dev/null -w "%{http_code}" https://localstack.hoangvu75.space/_localstack/health` → kỳ vọng **200**. Nếu timeout / DNS lỗi → chưa có **Public Hostname** trên Cloudflare Tunnel (hoặc DNS) trỏ tới Ingress giống `argocd.hoangvu75.space`.

**Ingress vs NodePort:** Nên giữ **Ingress** (cùng pattern Argo CD / Tunnel). **NodePort** không giải quyết CORS/dashboard; chỉ đổi cách expose cổng. Nếu tắt app LocalStack mà vẫn thấy **404 nginx**, thường là **không còn Ingress rule** hoặc **default backend** — chứng tỏ request đã tới Ingress controller.

**S3 / API sau khi health OK:** nếu OPTIONS 204 nhưng PUT bucket vẫn đỏ → mở request **OPTIONS** cho `/my-bucket`, xem **Request Headers → access-control-request-headers**; mọi tên đó phải nằm trong `cors-allow-headers` của Ingress (đã mở rộng cho `x-amz-acl`, `amz-sdk-*`, checksum, …).

**S3 / API sau khi health OK:** OPTIONS 204 nhưng PUT tạo bucket vẫn lỗi → thường do **preflight** không cho phép hết header AWS SDK (vd. `x-amz-acl`, `amz-sdk-invocation-id`). Xem OPTIONS tới `/my-bucket` → `access-control-request-headers`; bổ sung vào `cors-allow-headers` trên Ingress nếu thiếu (manifest đã mở rộng + `cors-expose-headers` cho ETag).

**Dashboard `app.localstack.cloud` không connect:** lỗi **preflight OPTIONS** (“No content available for preflight request”) → CORS xử lý tại **Ingress nginx** (`enable-cors`, origin `https://app.localstack.cloud`); LocalStack dùng **`DISABLE_CORS_HEADERS=1`** để không trùng header với nginx. Giữ **`websocket-services`**. Trong UI stack có thể cần **API key** (token Pro). F12 → request **OPTIONS** `/_localstack/health` phải trả **204** và header `Access-Control-Allow-Origin`.

**Port-forward (dự phòng):**

```bash
kubectl port-forward -n localstack svc/localstack 4566:4566
```

## DinD + Lambda (docker)

- **`mountDind.enabled: true`** và **`lambda.executor: docker`**: EC2/Lambda dùng Docker trong pod (sidecar privileged).
- Image DinD dùng **`public.ecr.aws/docker/library/docker:24-dind`** (mirror Docker Official trên ECR Public) để tránh lỗi pull **`unexpected EOF`** từ Docker Hub. RAM nên đủ (trong `values.yaml` đã tăng **limit ~4Gi**).

## Nếu vẫn `ImagePullBackOff`

- Thử pull tay: `docker pull public.ecr.aws/docker/library/docker:24-dind`
- **`localstack-pro`** vẫn từ Docker Hub: có thể thêm **`imagePullSecrets`** (Secret kiểu `kubernetes.io/dockerconfigjson` trong namespace `localstack`) nếu bị rate limit.

## Hướng thay thế (không cần DinD)

- **`mountDind.enabled: false`** + **`lambda.executor: kubernetes`**: Lambda chạy bằng Pod (cần `role.create: true` trên chart); EC2 kiểu container có thể không dùng được như với Docker.
