# K8s Manifest Structure

Cấu trúc thư mục để quản lý workload theo namespace:

```
k8s_manifest/
├── namespaces.yaml              # Định nghĩa các namespace
├── test1/                       # Namespace test1
│   └── nginx-workload/          # Tên workload
│       ├── deployment.yaml
│       └── service.yaml
└── test2/                       # Namespace test2
    └── demo-workload/           # Tên workload
        ├── deployment.yaml
        └── service.yaml
```

## Cách sử dụng

### 1. Thêm namespace mới
Chỉnh sửa file `namespaces.yaml` và thêm namespace mới:

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: test3
  labels:
    environment: production
    managed-by: argocd
```

### 2. Thêm workload mới
Tạo thư mục theo cấu trúc: `<namespace>/<workload-name>/`

Ví dụ: `k8s_manifest/test1/redis-workload/`

Sau đó tạo các file manifest (deployment.yaml, service.yaml, configmap.yaml, v.v.)

**Lưu ý:** Nhớ khai báo `namespace` trong metadata của mỗi resource!

### 3. Deploy với ArgoCD
ArgoCD sẽ tự động scan toàn bộ thư mục này và deploy theo đúng namespace đã khai báo.

## Ưu điểm

✅ Tổ chức rõ ràng theo namespace  
✅ Dễ dàng quản lý nhiều workload  
✅ Scale được khi dự án lớn  
✅ GitOps-friendly với ArgoCD

