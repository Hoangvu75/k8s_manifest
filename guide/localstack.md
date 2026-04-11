## Port-forward (API edge)

```bash
kubectl port-forward -n localstack svc/localstack 4566:4566
```

Web console / `localhost.localstack.cloud:4566` trỏ tới cổng đã forward.

## Lỗi `Docker not available` (EC2, Lambda docker, …)

Trên Kubernetes, container LocalStack **không** có sẵn Docker. Các API như **EC2** (mô phỏng instance bằng container) hoặc **Lambda** với `lambda.executor: docker` cần **Docker daemon**.

Trong chart, bật **`mountDind`** (Docker-in-Docker sidecar). Đã cấu hình trong `apps/playground/localstack/chart/values.yaml`. Sau khi sync, pod sẽ nặng hơn và thường chạy **privileged** — cluster phải cho phép (PSP/Kyverno/Gatekeeper).

**Thay thế cho Lambda:** đặt `lambda.executor: kubernetes` và đảm bảo `role.create: true` (RBAC tạo pod Lambda trong cluster) nếu không cần EC2/Docker.
