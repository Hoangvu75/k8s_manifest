trivy k8s --report summary \
  --tolerations node-role.kubernetes.io/control-plane=:NoSchedule \
  --timeout 60m \
  -f table \
  -o trivy-summary.txt

sed -r 's/\x1B\[[0-9;]*[mK]//g' trivy-summary.txt > trivy-summary-clean.txt