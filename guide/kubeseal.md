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
kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets --format yaml < secret.yaml > sealed-secret.yaml
```

**Ví dụ thực tế:**
```bash
kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets --format yaml < apps/infra/cloudflared/chart/secret.yaml > apps/infra/cloudflared/chart/sealed-secret.yaml
```

### 3. Kết quả: SealedSecret (an toàn để commit)

```yaml
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

## Backup & Restore Private Key

> ⚠️ **QUAN TRỌNG**: Nếu mất private key, tất cả SealedSecrets sẽ không decrypt được!

### Backup (làm ngay sau khi cài controller!)

```bash
kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml
```

### Restore (apply TRƯỚC khi cài lại controller)

```bash
kubectl apply -f sealed-secrets-key-backup.yaml
```

### Khi nào cần restore?

| Hành động | Private key | Cần restore? |
|-----------|-------------|--------------|
| Restart Pod | Giữ nguyên | ❌ Không |
| Upgrade Helm chart | Giữ nguyên | ❌ Không |
| Delete + reinstall (giữ Secret) | Giữ nguyên | ❌ Không |
| **Delete namespace + reinstall** | **Mất** | ✅ **Cần restore** |
| **Rebuild cluster** | **Mất** | ✅ **Cần restore** |

---

## Lưu ý quan trọng

> ⚠️ **Namespace-scoped**: SealedSecret mặc định chỉ decrypt được trong namespace đã seal. Nếu đổi namespace, phải seal lại.

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

### Xem public key
```bash
kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets --fetch-cert
```

### Seal lại khi đổi namespace
```bash
kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets --format yaml < secret.yaml > sealed-secret.yaml
```
