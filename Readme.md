Để kết nối k8s tới rancher, cần thay đổi server-url thành
https://host.docker.internal

Cài ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Lấy password ArgoCD
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

Forward port ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

Apply ArgoCD app
kubectl apply -f argocd-applicationset.yaml