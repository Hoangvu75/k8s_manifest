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

### 2. Cấu hình Kubernetes Cloud

1. **Manage Jenkins** → **Manage Nodes and Clouds** → **Configure Clouds**.
2. **Add a new cloud** → chọn **Kubernetes**.
3. Điền:
   - **Name**: `kubernetes` (hoặc tên bất kỳ).
   - **Kubernetes URL**:
     - Nếu Jenkins chạy **trong cùng cluster**: để trống hoặc `https://kubernetes.default.svc`.
     - Nếu Jenkins chạy **ngoài cluster**: nhập URL API của cluster (ví dụ `https://<cluster-ip>:6443`).
   - **Kubernetes server certificate key**: thường bỏ trống nếu dùng cert mặc định.
   - **Credentials**: chọn credential kết nối cluster:
     - **Jenkins chạy trong cluster**: **Add** → **Kubernetes Service Account** → ID đặt tên (ví dụ `k8s-jenkins`) → **Add**. Sau đó chọn credential vừa tạo.
     - **Jenkins chạy ngoài cluster**: **Add** → **Secret file** (upload kubeconfig) hoặc **Username and password** / **Certificate** tùy cluster.
   - **Jenkins URL**: URL để agent trong pod gọi về Jenkins, ví dụ `https://jenkins.localhost` (phải truy cập được từ trong cluster).
   - **Jenkins tunnel** (nếu có): thường để trống hoặc điền nếu agent không resolve được Jenkins URL.
4. Phần **Pod Templates** có thể để mặc định; pipeline sẽ dùng `podTemplate` trong Jenkinsfile.
5. **Save**.

Sau khi cài plugin và cấu hình Cloud, chạy lại pipeline dùng Kaniko; Jenkins sẽ tạo pod có container Kaniko và chạy build trong đó.
