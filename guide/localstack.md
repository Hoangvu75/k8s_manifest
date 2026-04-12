## Port-forward (API edge)

```bash
kubectl port-forward -n localstack svc/localstack 4566:4566
```

Web console / `localhost.localstack.cloud:4566` trỏ tới cổng đã forward.

## DinD + Lambda (docker)

- **`mountDind.enabled: true`** và **`lambda.executor: docker`**: EC2/Lambda dùng Docker trong pod (sidecar privileged).
- Image DinD dùng **`public.ecr.aws/docker/library/docker:24-dind`** (mirror Docker Official trên ECR Public) để tránh lỗi pull **`unexpected EOF`** từ Docker Hub. RAM nên đủ (trong `values.yaml` đã tăng **limit ~4Gi**).

## Nếu vẫn `ImagePullBackOff`

- Thử pull tay: `docker pull public.ecr.aws/docker/library/docker:24-dind`
- **`localstack-pro`** vẫn từ Docker Hub: có thể thêm **`imagePullSecrets`** (Secret kiểu `kubernetes.io/dockerconfigjson` trong namespace `localstack`) nếu bị rate limit.

## Hướng thay thế (không cần DinD)

- **`mountDind.enabled: false`** + **`lambda.executor: kubernetes`**: Lambda chạy bằng Pod (cần `role.create: true` trên chart); EC2 kiểu container có thể không dùng được như với Docker.
