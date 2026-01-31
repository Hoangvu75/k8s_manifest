# Kubeseal - Mã hóa Secrets cho GitOps

## Tổng quan

**Sealed Secrets** cho phép mã hóa Kubernetes Secrets để push lên Git an toàn. Chỉ cluster có private key mới decrypt được.

```
Secret (plaintext) → kubeseal → SealedSecret (encrypted) → Git → ArgoCD → Secret (decrypted)
```

---

## Cài đặt kubeseal CLI

### Windows
```powershell
# Download từ GitHub releases
# https://github.com/bitnami-labs/sealed-secrets/releases

# Thêm vào PATH
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\kubeseal", "User")
```

### Linux/macOS
```bash
# Homebrew
brew install kubeseal

# Hoặc download binary
curl -L https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.27.3/kubeseal-0.27.3-linux-amd64.tar.gz | tar xz
sudo mv kubeseal /usr/local/bin/
```

---

## Sử dụng

### 1. Tạo Secret thường (không commit file này!)

```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
  namespace: my-namespace
type: Opaque
stringData:
  API_KEY: "your-secret-value"
  DATABASE_URL: "postgres://user:pass@host:5432/db"
```

### 2. Seal secret

```bash
kubeseal \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets \
  
example

```bash
kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets --format yaml < apps/infra/cloudflared/chart/secret.yaml > apps/infra/cloudflared/chart/sealed-secret.yaml
```

### 3. Kết quả: SealedSecret (an toàn để commit)
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: my-secret
  namespace: my-namespace
spec:
  encryptedData:
    API_KEY: AgBy8hCJ...  # Đã mã hóa
    DATABASE_URL: AgCx9...  # Đã mã hóa
```

### 4. Cập nhật kustomization.yaml

```yaml
resources:
  - sealed-secret.yaml  # Thay vì secret.yaml
  - deployment.yaml
```

---

## Ví dụ: Cloudflared

```bash
cd k8s_manifest

# Seal secret
kubeseal \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets \
  --format yaml \
  < apps/infra/cloudflared/chart/secret.yaml \
  > apps/infra/cloudflared/chart/sealed-secret.yaml

# Commit và push
git add apps/infra/cloudflared/chart/sealed-secret.yaml
git commit -m "feat: add sealed secret for cloudflared"
git push
```

---

## Lưu ý quan trọng

> ⚠️ **Namespace-scoped**: SealedSecret mặc định chỉ decrypt được trong namespace đã seal. Nếu đổi namespace, phải seal lại.

> ⚠️ **Backup private key**: Nếu mất controller, mất luôn khả năng decrypt. Backup key:
> ```bash
> kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml
> ```

> ⚠️ **Xóa file plaintext**: Sau khi seal xong, xóa hoặc gitignore file `secret.yaml` gốc.

---

## Troubleshooting

### Lỗi "cannot fetch certificate"
```bash
# Kiểm tra controller đang chạy
kubectl get pods -n sealed-secrets

# Kiểm tra kết nối cluster
kubectl cluster-info
```

### Seal lại khi đổi namespace
```bash
# SealedSecret namespace-scoped, phải seal lại nếu đổi namespace
kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets --format yaml < secret.yaml > sealed-secret.yaml
```
