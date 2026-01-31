# Kubernetes Dashboard
## Access

Open browser: **https://kubedashboard.localhost** (no hosts file edit needed).

---

## Log in with Token

On the login screen, select **Token**, then paste the token obtained from the command below.

**Create ServiceAccount and Get Bearer Token:**

```bash
# Create admin account for Dashboard
kubectl -n kubernetes-dashboard create serviceaccount dashboard-admin
kubectl -n kubernetes-dashboard create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:dashboard-admin

# Get token (K8s 1.24+ does not auto-create Secret; use the following command — copy output, paste into "Enter token" box)
kubectl -n kubernetes-dashboard create token dashboard-admin --duration=24h
```

After running the last command, copy the printed token string → paste into the **Enter token** box at https://kubedashboard.localhost/#/login → click **Sign in**.
