# Harbor
## Access

Open browser: **https://harbor.localhost** (uses `*.localhost`, no hosts file edit needed).

## Login

- **Username:** `admin`
- **Password:** default in values is `Harbor12345` — change immediately after login (User Profile → Change Password).

## Push / pull image

```bash
# Login
docker login harbor.localhost
# Username: admin, Password: (the password you changed)

# Tag and push
docker tag myimage:latest harbor.localhost/library/myimage:latest
docker push harbor.localhost/library/myimage:latest
```

Create a **Project** (e.g., `library` or custom name) on the Harbor portal before pushing images to it.
