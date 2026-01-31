# k8s_manifest

Repo GitOps chứa toàn bộ manifest Kubernetes, đồng bộ lên cluster bằng **Argo CD**. Git là nguồn sự thật; Argo CD so sánh Git với cluster và apply thay đổi (auto-sync).

---

## Cấu trúc thư mục

| Thư mục / file | Mô tả |
|----------------|--------|
| **bootstrap/** | Application “bootstrap” sync thư mục này → tạo Application **root** và ApplicationSet **cluster-resources** trên cluster. |
| **bootstrap.yaml** | Định nghĩa Application “bootstrap” (sync path `bootstrap/`). Cài thủ công một lần hoặc apply bằng `kubectl apply -f`. |
| **projects/** | Application **root** sync thư mục này → chứa AppProject + ApplicationSet **playground**, **infra** (tự tạo Application con từ `apps/`). |
| **cluster-resources/default/** | ApplicationSet **cluster-resources** tạo app **cluster-resources-default** sync thư mục này → chủ yếu **namespace** (sync-wave -1, tạo trước các app). |
| **apps/<project>/<app>/** | Mỗi app có `config.yaml` (metadata), `kustomization.yaml` (+ Helm chart trong `chart/` nếu dùng). ApplicationSet **playground** / **infra** quét `apps/playground/**/config.yaml` và `apps/infra/**/config.yaml` → tạo một Application cho mỗi app. |
| **guide/** | Tài liệu nhanh: Argo CD, Jenkins, Kubernetes Dashboard (URL, lấy mật khẩu / token). |

---

## Luồng đồng bộ (tóm tắt)

1. **Bootstrap** (Application, cấu hình một lần) sync `bootstrap/`:
   - Tạo Application **root** (sync `projects/`).
   - Tạo ApplicationSet **cluster-resources** → sinh Application **cluster-resources-default** (sync `cluster-resources/default/` → namespace, v.v.).

2. **Root** sync `projects/`:
   - Áp dụng AppProject + ApplicationSet **playground** và **infra** lên cluster.

3. **ApplicationSet playground / infra**:
   - Quét Git theo pattern `apps/playground/**/config.yaml` và `apps/infra/**/config.yaml`.
   - Mỗi file `config.yaml` tương ứng một Application (tên dạng `playground-<app>`, `infra-<app>`), sync path chứa app đó (Kustomize ± Helm).

4. **cluster-resources-default** sync `cluster-resources/default/`:
   - Apply `namespace.yaml` (và file khác nếu có) → tạo Namespace với sync-wave -1 để có sẵn trước khi app deploy.

---

## Projects và apps hiện có

### playground (9 apps)
| App | Host (LAN) | Public URL |
|-----|------------|------------|
| ingress-nginx | - | - |
| metallb | - | - |
| argocd | argocd.localhost | argocd.hoangvu75.space |
| harbor | harbor.localhost | harbor.hoangvu75.space |
| jenkins | jenkins.localhost | jenkins.hoangvu75.space |
| n8n | n8n.localhost | n8n.hoangvu75.space |
| cloudflared | - | (tunnel connector) |
| sample-gitops-web | - | - |

### infra (2 apps)
| App | Host (LAN) | Public URL |
|-----|------------|------------|
| kubernetes-dashboard | kubedashboard.localhost | dashboard.hoangvu75.space |
| metallb-system | - | - |

Thêm app: tạo thư mục `apps/<project>/<tên-app>/` với `config.yaml` + `kustomization.yaml` (và `chart/` nếu dùng Helm). Thêm Namespace (nếu cần) vào `cluster-resources/default/namespace.yaml`. Push Git → Argo CD tự tạo Application và sync.

---

## Hướng dẫn nhanh

- **Network Flow (DNS → K8s):** [guide/network_flow.md](guide/network_flow.md)
- **Argo CD:** [guide/argo_cd.md](guide/argo_cd.md)
- **Jenkins (Unlock password):** [guide/jenkins.md](guide/jenkins.md)
- **Kubernetes Dashboard (token):** [guide/kube_dashboard.md](guide/kube_dashboard.md)
- **Harbor (registry):** [guide/harbor.md](guide/harbor.md)
