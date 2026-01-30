# Jenkins

## Truy cập

Mở trình duyệt: **https://jenkins.localhost**

---

## Lấy mật khẩu Unlock Jenkins (lần đầu)

Một lệnh duy nhất (trên Windows dùng Git Bash cần `MSYS_NO_PATHCONV=1` để đường dẫn `/var/...` không bị đổi thành path Windows):

```bash
MSYS_NO_PATHCONV=1 kubectl exec -n jenkins $(kubectl get pods -n jenkins -o jsonpath='{.items[0].metadata.name}') -- cat /var/jenkins_home/secrets/initialAdminPassword
```

Copy chuỗi mật khẩu in ra → dán vào ô **Administrator password** trên trang Unlock Jenkins → bấm **Continue**.

---

## Cài và cấu hình Kubernetes plugin (để dùng Kaniko)

Pipeline Kaniko cần Jenkins kết nối được tới Kubernetes cluster để tạo pod build. Làm hai bước sau trên Jenkins web.

### 1. Cài plugin Kubernetes

1. Đăng nhập Jenkins → **Manage Jenkins** → **Manage Plugins**.
2. Tab **Available** → ô tìm kiếm gõ **Kubernetes**.
3. Tick chọn **Kubernetes** (Kubernetes plugin).
4. Bấm **Install without restart** (hoặc **Download now and install after restart**).
5. Nếu bắt buột restart thì **Manage Jenkins** → **Restart**.

### 2. Tạo credential Kubernetes (Service Account token)

Jenkins cần quyền tạo/xóa pod trong namespace để chạy agent (Kaniko). ServiceAccount và RBAC đã nằm trong repo tại **`apps/playground/jenkins/chart/jenkins-sa.yaml`** — Argo CD sẽ tạo khi sync app `playground-jenkins`. Nếu chưa sync, đợi Argo CD sync xong hoặc apply thủ công: `kubectl apply -f apps/playground/jenkins/chart/jenkins-sa.yaml`.

**Bước 1 – Đảm bảo ServiceAccount đã có trên cluster** (đã có nếu Argo CD đã sync app Jenkins). Nếu cần apply thủ công, dùng file trong repo:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins-sa
  namespace: jenkins
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-agent-role
  namespace: jenkins
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/exec", "pods/attach"]
  verbs: ["create", "delete", "get", "list", "watch", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-agent-rolebinding
  namespace: jenkins
subjects:
- kind: ServiceAccount
  name: jenkins-sa
  namespace: jenkins
roleRef:
  kind: Role
  name: jenkins-agent-role
  apiGroup: rbac.authorization.k8s.io
```

**Bước 2 – Lấy token (Kubernetes 1.24+):**

```bash
kubectl create token jenkins-sa -n jenkins --duration=8760h
```

Copy toàn bộ chuỗi token in ra.

**Bước 3 – Thêm credential trong Jenkins:**

1. Trên trang **New cloud** (Kubernetes), ở ô **Credentials** bấm **Add**.
2. **Kind** chọn **Secret text**.
3. **Secret**: dán token vừa copy.
4. **ID**: đặt tên (ví dụ `jenkins-k8s-sa-token`).
5. **Description** (tùy chọn): ví dụ "Service Account token cho Jenkins agents".
6. Bấm **Add** → quay lại dropdown **Credentials** và chọn credential vừa tạo.

---

### 3. Cấu hình Kubernetes Cloud (các field)

1. **Manage Jenkins** → **Clouds** → **Configure Clouds** (hoặc **New Cloud**) → chọn **Kubernetes**.
2. Điền từng field:

| Field | Chọn / điền |
|-------|-------------|
| **Name** | `kubernetes` (giữ mặc định hoặc đặt tên khác). |
| **Kubernetes URL** | Jenkins trong cùng cluster: để **trống** hoặc `https://kubernetes.default.svc`. Ngoài cluster: URL API (ví dụ `https://<cluster-ip>:6443`). |
| **Use Jenkins Proxy** | Bỏ chọn (trừ khi Jenkins bắt buộc qua proxy để ra cluster). |
| **Kubernetes server certificate key** | Để trống (cluster dùng CA mặc định). |
| **Disable https certificate check** | Chỉ bật khi dev/test và gặp lỗi cert; production nên tắt. |
| **Kubernetes Namespace** | `jenkins` (namespace chạy agent, trùng nơi đã tạo ServiceAccount). |
| **Agent Docker Registry** | Để trống (Kaniko dùng image từ `gcr.io`). Nếu dùng registry riêng thì điền URL. |
| **Inject restricted PSS...** | Có thể bỏ chọn lúc đầu; bật nếu cluster bắt PSS. |
| **Credentials** | Chọn credential **Secret text** chứa token Service Account (đã tạo ở mục trên). Bấm **Test Connection** để kiểm tra. |
| **WebSocket** | Nên **bật** (agent kết nối Jenkins ổn định hơn). |
| **Direct Connection** | Tùy chọn; thường không cần nếu đã bật WebSocket. |
| **Jenkins URL** | `https://jenkins.localhost` (URL mà pod trong cluster gọi được tới Jenkins; phải resolve được từ trong cluster). |
| **Jenkins tunnel** | Để trống. |
| **Connection Timeout / Read Timeout** | Giữ mặc định (5, 15) trừ khi mạng chậm. |
| **Concurrency Limit** | Để trống (không giới hạn) hoặc điền số nếu muốn giới hạn pod agent cùng lúc. |

3. Phần **Pod Templates** để mặc định; pipeline Kaniko tự dùng `podTemplate` trong Jenkinsfile.
4. **Save**.

Sau khi cấu hình xong, chạy lại pipeline dùng Kaniko; Jenkins sẽ tạo pod trong namespace `jenkins` và chạy build trong container Kaniko.
