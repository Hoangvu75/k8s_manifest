Show recent errors and warnings in a Kubernetes namespace.

Namespace: $ARGUMENTS

If no namespace is provided, check kx-customers (the highest-traffic namespace).

Run these commands:

1. Get all Warning events in the namespace sorted by time:
   `kubectl get events -n <namespace> --field-selector type=Warning --sort-by='.lastTimestamp'`

2. Find pods that are not healthy (not Running/Completed):
   `kubectl get pods -n <namespace> | grep -v -E "^NAME|Running|Completed"`

3. For each unhealthy pod, get last 50 log lines:
   `kubectl logs -n <namespace> <pod-name> --tail=50`

4. For any pod with restartCount > 0, get previous container logs:
   `kubectl logs -n <namespace> <pod-name> --previous --tail=50`

5. Scan running pods for recent errors (last 5 minutes worth of logs):
   Check the highest-restart-count pods first:
   `kubectl get pods -n <namespace> --sort-by='.status.containerStatuses[0].restartCount' -o wide | tail -5`

6. Check node-level issues that might affect pods:
   `kubectl get events -n kube-system --field-selector type=Warning --sort-by='.lastTimestamp' | tail -10`

Present as:
- **Unhealthy pods**: list with status and restart count
- **Warning events**: grouped by reason (OOMKilled, BackOff, Failed, etc.)
- **Error log snippets**: key error messages from affected pods
- **Pattern**: is this isolated (one pod) or systemic (multiple pods/nodes)?
- **Recommended action**: based on known issues in this platform
