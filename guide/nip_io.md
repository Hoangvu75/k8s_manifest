# nip.io — truy cập app qua mạng (LAN / Internet)

Các Ingress đã cấu hình host dạng `<app>.192.168.56.200.nip.io`. [nip.io](https://nip.io) resolve `<anything>.<IP>.nip.io` về đúng IP — không cần mua domain hay sửa file hosts.

## URL các app

| App | URL |
|-----|-----|
| Argo CD | https://argocd.192.168.56.200.nip.io |
| Jenkins | https://jenkins.192.168.56.200.nip.io |
| n8n | https://n8n.192.168.56.200.nip.io |
| Harbor | https://harbor.192.168.56.200.nip.io |
| sample-gitops-web | https://sample-gitops-web.192.168.56.200.nip.io |
| Kubernetes Dashboard | https://kubedashboard.192.168.56.200.nip.io |

## Đổi IP

IP mặc định: **192.168.56.200** (LoadBalancer của ingress-nginx). Nếu IP của bạn khác:

1. **Trong cluster (LAN):** Dùng IP nội bộ của ingress-nginx LoadBalancer.
   ```bash
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   ```

2. **Từ Internet:** Dùng IP public (sau khi forward port 80/443 từ router về LoadBalancer).

3. **Cập nhật manifest:** Tìm và thay `192.168.56.200` trong các file:
   - `apps/playground/argocd/chart/ingress.yaml`
   - `apps/playground/jenkins/chart/values.yaml`
   - `apps/playground/n8n/chart/values.yaml`
   - `apps/playground/harbor/chart/values.yaml`
   - `apps/playground/sample-gitops-web/chart/values.yaml`
   - `apps/infra/kubernetes-dashboard/ingress.yaml`
   - `source-code/sample_gitops_web/Jenkinsfile` (biến `HARBOR_NIP_HOST` hoặc giá trị mặc định)

## Truy cập từ Internet

1. Mở port **80** và **443** trên router/firewall, forward về IP của ingress-nginx (LoadBalancer).
2. Dùng **IP public** thay cho 192.168.56.200 trong URL, ví dụ: `https://argocd.<PUBLIC_IP>.nip.io`.

## Lưu ý TLS

nip.io không cung cấp TLS. Ingress-nginx thường dùng cert tự ký. Trình duyệt sẽ cảnh báo — chọn "Advanced" → "Proceed" để tiếp tục.
