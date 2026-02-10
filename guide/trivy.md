trivy k8s --report summary \
  --tolerations node-role.kubernetes.io/control-plane=:NoSchedule \
  --timeout 60m \
  -f table \
  -o trivy-summary.txt