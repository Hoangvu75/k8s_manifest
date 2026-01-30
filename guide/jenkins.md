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
| **Jenkins URL** | **Phải dùng URL nội bộ** để pod agent (chạy trong cluster) gọi được: `http://jenkins.jenkins.svc.cluster.local:8080`. Không dùng `https://jenkins.localhost` — từ trong cluster tên đó thường không resolve đúng, agent không kết nối được và Jenkins báo "offline". |
| **Jenkins tunnel** | Để trống. |
| **Connection Timeout / Read Timeout** | Giữ mặc định (5, 15) trừ khi mạng chậm. |
| **Concurrency Limit** | Để trống (không giới hạn) hoặc điền số nếu muốn giới hạn pod agent cùng lúc. |

**Phần cấu hình phía dưới (Pod Retention, timeouts, …):**

| Field | Chọn / điền |
|-------|-------------|
| **Add Pod Label** | Không bắt buộc; có thể bỏ qua (pipeline Kaniko tự định nghĩa pod trong Jenkinsfile). |
| **Pod Retention** | Giữ **Never** — pod agent bị xóa ngay sau khi build xong (tiết kiệm tài nguyên). |
| **Max connections to Kubernetes API** | Giữ mặc định **32** (hoặc để trống). |
| **Seconds to wait for pod to be running** | Đặt **900** hoặc **1200** (15–20 phút) — lần đầu pull image jnlp (~150MB) + Kaniko (~40MB) có thể mất vài phút; nếu để 600 có thể timeout trước khi pod Ready. |
| **Container Cleanup Timeout** | Giữ **5** (phút) — thời gian chờ dọn container sau khi pod kết thúc. |
| **Transfer proxy related environment variables...** | Bỏ chọn (trừ khi agent cần dùng proxy). |
| **Restrict pipeline support to authorized folders** | Bỏ chọn (trừ khi muốn giới hạn folder được dùng K8s agent). |
| **Defaults Provider Template Name** | Để trống. |
| **Enable garbage collection** | Có thể **bật** — plugin tự dọn pod/volume cũ. |

3. Phần **Pod Templates** để mặc định; pipeline Kaniko tự dùng `podTemplate` trong Jenkinsfile.
4. **Save**.

Sau khi cấu hình xong, chạy lại pipeline dùng Kaniko; Jenkins sẽ tạo pod trong namespace `jenkins` và chạy build trong container Kaniko.

---

### 4. Pod kẹt "ContainerCreating" / agent "offline" — stuck rất lâu

Nếu console báo pod **Pending**, container **ContainerCreating**, agent **offline** và **Still waiting to schedule task** (build kẹt nhiều phút):

**Bước 1 – Tăng timeout (bắt buộc):**  
**Manage Jenkins** → **Clouds** → bấm **kubernetes** → tìm **Seconds to wait for pod to be running** → đổi thành **1200** (20 phút) → **Save**. Nếu để 600, Jenkins dừng chờ trước khi pod kịp pull xong image.

**Bước 2 – Chờ một lần, không cancel:**  
Chạy **Build Now** và **để chạy 5–10 phút** (không bấm Cancel). Lần đầu cluster phải pull image jnlp (~150MB) và Kaniko (~40MB) nên chậm. Khi pod Ready, build sẽ chạy tiếp. Build sau image đã có trên node sẽ nhanh hơn.

**Bước 3 – Pre-pull để lần sau không chờ:**  
Để các build sau lên pod nhanh, pull sẵn hai image lên node (chỉ cần làm một lần):

- **Cách A – Có SSH vào node (worker):**  
  SSH vào máy node (ví dụ `desktop-worker2`), chạy:  
  `crictl pull jenkins/inbound-agent:3355.v388858a_47b_33-3-jdk21` và  
  `crictl pull gcr.io/kaniko-project/executor:v1.6.0-debug`  
  (nếu node dùng Docker thì dùng `docker pull` thay cho `crictl pull`.)

- **Cách B – Không SSH được vào node:**  
  Tạo Job tạm để cluster tự pull hai image khi tạo pod. Lưu file sau rồi chạy `kubectl apply -f jenkins-agent-prepull.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: jenkins-agent-prepull
  namespace: jenkins
spec:
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: jnlp
        image: jenkins/inbound-agent:3355.v388858a_47b_33-3-jdk21
        command: ["sleep", "60"]
      - name: kaniko
        image: gcr.io/kaniko-project/executor:v1.6.0-debug
        command: ["sleep", "60"]
```

  Job này tạo một pod dùng đúng hai image → kubelet sẽ pull về node. Sau vài phút pod Complete; xóa Job: `kubectl delete job jenkins-agent-prepull -n jenkins`. Build Jenkins sau trên **cùng node** đó sẽ nhanh hơn (nếu cluster có nhiều node, có thể chạy Job vài lần hoặc dùng nodeSelector trùng node Jenkins hay dùng).

**Kiểm tra pod:**  
`kubectl get pods -n jenkins` và `kubectl describe pod -n jenkins <tên-pod>`. Phần Events nếu thấy **Pulled**, **Started** là pod đã chạy; nếu Jenkins vẫn báo offline thì thường do đã hết timeout — tăng lên 1200 rồi chạy lại build.

---

### 5. Pod đã Running nhưng agent vẫn "offline" / chưa build

Nếu Dashboard thấy pod **Running** nhưng Jenkins vẫn báo **Still waiting to schedule task**, **agent offline** và build không chạy tiếp:

**Nguyên nhân:** Container **jnlp** (Jenkins agent) không kết nối được về Jenkins. Thường do **Jenkins URL** đang dùng `https://jenkins.localhost` — từ **trong cluster** tên `jenkins.localhost` không resolve đúng (hoặc trỏ về 127.0.0.1 của chính pod), nên agent không tìm thấy Jenkins.

**Cách sửa:**  
**Manage Jenkins** → **Clouds** → bấm **kubernetes** → tìm **Jenkins URL** → đổi thành **URL Service nội bộ**:

- `http://jenkins.jenkins.svc.cluster.local:8080`

(Service Jenkins trong namespace `jenkins` thường tên `jenkins`, port 8080.)  
Lưu **Save** → chạy lại **Build Now**. Pod mới sẽ dùng URL nội bộ và agent kết nối được, build chạy tiếp.

---

### 6. Push Harbor báo lỗi token "harbor.localhost" / connection refused

Nếu Kaniko báo lỗi dạng: `Get "https://harbor.localhost/service/token?...": dial tcp [::1]:443: connection refused`:

**Nguyên nhân:** Harbor trả token URL về `https://harbor.localhost`. Từ trong pod, `harbor.localhost` resolve về 127.0.0.1 nên không tới được Harbor.

**Cách sửa:** Pipeline đã thêm **hostAliases** để pod resolve `harbor.localhost` về Ingress. Cần cấu hình **INGRESS_CLUSTER_IP** trong Jenkins:

1. Lấy ClusterIP của Ingress (Harbor qua Ingress):
   ```bash
   kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}'
   ```
   (Nếu Ingress ở namespace/name khác thì đổi cho đúng.)

2. Trong Jenkins: **Manage Jenkins** → **System** → **Global properties** → tick **Environment variables** → **Add**:
   - **Name:** `INGRESS_CLUSTER_IP`
   - **Value:** dán ClusterIP vừa lấy (ví dụ `10.96.123.45`).

3. **Save** → chạy lại **Build Now**.

Pod agent sẽ dùng hostAliases để resolve `harbor.localhost` về Ingress → request token tới Ingress:443 → Ingress forward tới Harbor Core → push thành công.
