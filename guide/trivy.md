trivy k8s --report summary \
  --tolerations node-role.kubernetes.io/control-plane=:NoSchedule \
  --timeout 60m \
  --exclude-namespaces redis \
  -f table \
| sed -r 's/\x1B\[[0-9;]*[mK]//g' > trivy-summary-clean.txt