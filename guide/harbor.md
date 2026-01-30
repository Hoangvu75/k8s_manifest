# Harbor

## Truy cập

Mở trình duyệt: **https://harbor.localhost** (dùng `*.localhost`, không cần sửa file hosts).

## Đăng nhập lần đầu

- **Username:** `admin`
- **Password:** mặc định trong values là `Harbor12345` — nên đổi ngay sau khi đăng nhập (User Profile → Change Password).

## Push / pull image

```bash
# Login
docker login harbor.localhost
# Username: admin, Password: (mật khẩu đã đổi)

# Tag và push
docker tag myimage:latest harbor.localhost/library/myimage:latest
docker push harbor.localhost/library/myimage:latest
```

Tạo **Project** (ví dụ `library` hoặc tên riêng) trên portal Harbor trước khi push image vào project đó.
