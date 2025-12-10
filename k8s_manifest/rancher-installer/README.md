# Rancher Installer Pod

Pod này dùng để cài đặt Rancher vào K8s cluster.

## Bước 1: Deploy Pod

```bash
kubectl apply -f k8s_manifest/rancher-installer/
```

## Bước 2: Kiểm tra Pod đã chạy

```bash
kubectl get pod rancher-installer -n rancher-installer
```

## Bước 3: Exec vào Pod

```bash
kubectl exec -it rancher-installer -n rancher-installer -- /bin/sh
```

## Bước 4: Cài Cert-Manager (Bắt buộc cho Rancher)

Trong shell của pod, chạy:

```sh
# Thêm repo Cert-Manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Cài Cert-Manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

# Kiểm tra cert-manager đã ready
kubectl -n cert-manager get pods
kubectl -n cert-manager rollout status deploy/cert-manager
```

Đợi cho đến khi tất cả pods của cert-manager ở trạng thái `Running` (khoảng 1-2 phút).

## Bước 5: Cài Rancher

```sh
# Thêm repo Rancher
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

# Cài Rancher
# Thay 'rancher.local' bằng domain của bạn nếu có
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --create-namespace \
  --set hostname=rancher.local \
  --set bootstrapPassword=admin \
  --set replicas=1

# Kiểm tra Rancher deployment
kubectl -n cattle-system rollout status deploy/rancher
kubectl -n cattle-system get pods
```

Đợi khoảng 3-5 phút để Rancher khởi động hoàn toàn.

## Bước 6: Kiểm tra CRD Projects đã được tạo

```sh
kubectl get crd projects.management.cattle.io
```

Nếu thấy CRD này → Rancher đã cài thành công! ✅

## Bước 7: Expose Rancher Service (để truy cập từ browser)

```sh
# Xem service hiện tại
kubectl -n cattle-system get svc rancher

# Patch để expose qua NodePort
kubectl -n cattle-system patch svc rancher --type='json' -p='[{"op":"replace","path":"/spec/type","value":"NodePort"}]'

# Xem port được expose
kubectl -n cattle-system get svc rancher
```

Truy cập Rancher qua: `https://<node-ip>:<nodeport>`

## Bước 8: Thoát khỏi Pod và dọn dẹp

```sh
# Thoát khỏi pod
exit

# Xóa pod installer (nếu muốn)
kubectl delete -f k8s_manifest/rancher-installer/
```

## Lưu ý

- Username mặc định: `admin`
- Password: `admin` (hoặc giá trị bạn set trong `--set bootstrapPassword=`)
- Nếu dùng `rancher.local`, cần thêm vào file hosts: `<node-ip> rancher.local`
- Sau khi cài Rancher xong, bạn mới có thể sync Application `rancher-projects` thành công!

