nếu nó bị stuck không delete được thì
$ kubectl patch application playground-rancher -n argocd \
  --type=json \
  -p='[{"op":"remove","path":"/metadata/finalizers"}]'
application.argoproj.io/playground-rancher patched

kubectl -n cattle-system exec -it $(kubectl -n cattle-system get pods -l app=rancher --no-headers | head -1 | awk '{print $1}') -c rancher -- reset-password