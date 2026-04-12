## Ingress (khuyến nghị — dashboard không cần port-forward)

Chart bật **Ingress** (`ingressClassName: nginx`) tới Service edge **4566**:

- Host: **`localstack.hoangvu75.space`** (đổi trong `chart/values.yaml` nếu cần).
- Alias: **`localstack.localhost`** (thêm `127.0.0.1 localstack.localhost` trong `hosts` nếu truy cập Ingress qua IP máy bạn / Docker Desktop).

**Cloudflare Tunnel / DNS:** tạo hostname public trỏ tới cùng Ingress nginx như Argo CD (ví dụ public hostname → `http://ingress-nginx-controller.ingress-nginx.svc:80` với header `Host: localstack.hoangvu75.space`).

**Web dashboard (`app.localstack.cloud`):** `localhost.localstack.cloud:4566` chỉ về **127.0.0.1**, không tới cluster. Trong cấu hình instance đổi endpoint thành URL bạn expose, ví dụ **`https://localstack.hoangvu75.space`** (không thêm `:4566` nếu đi qua 443). Ingress đã bật CORS cho `https://app.localstack.cloud`.

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
