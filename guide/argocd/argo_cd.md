## 🐙 ArgoCD Installation

### 1. Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Enable Helm for Kustomize (required for apps using helmCharts) — run again after cluster reset
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'
kubectl rollout restart deployment argocd-repo-server -n argocd
```
### 2. Expose UI

**Ingress (GitOps):** The `playground-argocd` app deploys Ingress automatically. The Service keeps **ClusterIP** (default). Access via **https://argocd.localhost** — no port-forward needed. If previously patched to NodePort, revert: `kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"ClusterIP"}}'`

**port-forward (manual):** Use ClusterIP, no service change needed:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward -n argocd svc/argocd-server 8080:443
```
Then open https://localhost:8080

**NodePort:** Only if direct access via NodeIP:Port is needed (without Ingress):
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
```

---

## Sau khi restart K8s (Docker Desktop / KinD): repo “Failed”, không cần xóa repo

Có **hai chuyện khác nhau**:

1. **Pod `argocd-repo-server` kẹt** (init `copyutil` lỗi `ln: Already exists` sau khi sandbox/container bị recreate) → Service `argocd-repo-server:8081` không có backend Ready → UI/API báo lỗi, tab Settings → Repositories dễ hiện **Failed** dù Secret repo vẫn còn.
2. **Trạng thái “Connection” trên UI** là kết quả test gần nhất; không đồng nghĩa Secret đã mất. **Không nên** xóa repo và connect lại chỉ để “làm mới” — làm mất thời gian và dễ lệch URL (`.git` / không `.git`).

**Một lần xử lý nhanh sau khi cluster đã lên:**

```bash
kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-repo-server --wait=false
kubectl rollout restart deployment/argocd-server -n argocd
```

Đợy `kubectl get pods -n argocd` tất cả Ready, rồi **Settings → Repositories → REFRESH LIST** (và F5 trình duyệt). Kiểm tra sync: `kubectl get applications -n argocd`.

---

## Giảm phiền lâu dài: khai báo repo bằng Git (declarative), không phụ thuộc UI

Repo đăng ký qua UI là các **Secret** trong `argocd` (`argocd.argoproj.io/secret-type: repository`). Chúng **nằm trong etcd** của cluster — bình thường **không** mất khi chỉ stop/start K8s; việc bạn phải “connect lại” thường là do **sửa triệu chứng** (UI Failed) chứ không phải mất cấu hình.

**Quan trọng:** không gửi PAT vào chat, không commit PAT vào `k8s_manifest` (repo có thể public). Nếu PAT đã lộ → **thu hồi trên GitHub** và tạo token mới (`repo` cho private).

### Các bước thực hiện

1. **GitHub:** thu hồi token cũ (nếu đã lộ), tạo **Fine-grained PAT** hoặc classic PAT với quyền truy cập hai repo `k8s_manifest` và `k8s_manifest_secrets`.
2. Trong repo **private** `k8s_manifest_secrets`, thêm file (copy từ mẫu):
   - [`argocd-repository-secrets.example.yaml`](argocd-repository-secrets.example.yaml) → đổi tên thành ví dụ `argocd-repositories.yaml`, thay placeholder bằng username + **PAT mới**, commit & push `main`.
3. Application **`secrets`** (`bootstrap/secrets.yaml`) đã sync `path: .` — file mới trong root (hoặc thư mục con nếu bạn chỉnh `path`) sẽ được apply vào cluster; mỗi Secret phải có `metadata.namespace: argocd`.
4. **Sau khi Argo CD sync xong**, xoá các Secret repo cũ tạo từ UI (tên kiểu `repo-2685071424`) để **không trùng** hai bộ credential cho cùng một URL:
   ```bash
   kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=repository
   kubectl delete secret -n argocd repo-XXXXXXXX   # chỉ các secret hash cũ từ UI
   ```
5. **Settings → Repositories → REFRESH LIST**; nếu repo-server vừa restart xong mà vẫn đỏ, chạy lệnh ở mục “Sau khi restart K8s” phía trên.

Nếu sau này bạn dùng **SOPS** hoặc **SealedSecrets**, giữ file mã hoá trong `k8s_manifest_secrets` thay vì `stringData` thuần.

Nâng cấp phiên bản Argo CD theo thời gian cũng giúp giảm lỗi edge-case sau restart (theo dõi release note / issue liên quan `copyutil` / repo-server).
