## 🐙 ArgoCD Installation

### 1. Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'
kubectl rollout restart deployment argocd-repo-server -n argocd
```
### 2. Expose ArgoCD UI
Wait for all the pods of ArgoCD ready, then run
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward -n argocd svc/argocd-server 8080:80
```
Then open http://localhost:8080

### 3. Apply secrets to allow using private repo
```bash
kubectl apply -f argocd-repository-secrets.yaml
```
This will allow ArgoCD access the repositories in case the repositories are private

### 4. Apply bootstrap
```bash
kubectl kustomize . | kubectl apply -f -
```

### 5. In case need to delete bootstrap
```bash
kubectl patch application bootstrap -n argocd --type=merge -p '{"metadata":{"finalizers":null}}'
kubectl delete application bootstrap -n argocd --force --grace-period=0
```
