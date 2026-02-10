nếu nó bị stuck không delete được thì
$ kubectl patch application playground-rancher -n argocd \
  --type=json \
  -p='[{"op":"remove","path":"/metadata/finalizers"}]'
application.argoproj.io/playground-rancher patched