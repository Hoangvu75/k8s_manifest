# Kubernetes Dashboard

## Truy cập

Mở trình duyệt: **https://kubedashboard.localhost** (không cần sửa file hosts).

---

## Đăng nhập bằng Token

Trên màn hình đăng nhập chọn **Token**, rồi dán token lấy từ lệnh dưới.

**Tạo ServiceAccount và lấy Bearer Token:**

```bash
# Tạo tài khoản admin cho Dashboard
kubectl -n kubernetes-dashboard create serviceaccount dashboard-admin
kubectl -n kubernetes-dashboard create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:dashboard-admin

# Lấy token (K8s 1.24+ không tự tạo Secret; dùng lệnh sau — copy output, dán vào ô "Enter token")
kubectl -n kubernetes-dashboard create token dashboard-admin --duration=8760h
```

Chạy xong lệnh cuối, copy chuỗi token in ra → dán vào ô **Enter token** trên trang https://kubedashboard.localhost/#/login → bấm **Sign in**.
