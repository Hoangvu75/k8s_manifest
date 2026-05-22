Check the health of all pods in a Kubernetes namespace.

Namespace to check: $ARGUMENTS

Run the following kubectl commands and present a clear summary:

1. List all pods with their status, restarts, and age:
   `kubectl get pods -n <namespace> -o wide`

2. Show any pods that are NOT in Running or Completed state:
   `kubectl get pods -n <namespace> | grep -v -E "Running|Completed|NAME"`

3. For any pods that are CrashLoopBackOff, OOMKilled, Error, or Pending — describe them to show recent events and last exit reason:
   `kubectl describe pod <pod-name> -n <namespace>`

4. Show resource usage if metrics-server is available:
   `kubectl top pod -n <namespace> --sort-by=memory`

5. Show the 10 most recent events in the namespace:
   `kubectl get events -n <namespace> --sort-by='.lastTimestamp' | tail -10`

Present the output as:
- **Overall status**: X pods Running, Y pods with issues
- **Problem pods**: table listing pod name, status, restarts, issue summary
- **Recent events**: any Warning events
- **Recommendation**: what to investigate next if there are issues
