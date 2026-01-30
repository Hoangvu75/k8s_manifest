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
