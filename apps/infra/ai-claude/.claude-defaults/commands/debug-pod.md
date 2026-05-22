Debug a specific service in a Kubernetes namespace. Provide: <namespace> <service-label>

Arguments: $ARGUMENTS

Parse the arguments as: first word = namespace, second word = service name (used as app label).

Run these steps in order:

1. Find the pods for this service:
   `kubectl get pods -n <namespace> -l app=<service> -o wide`

2. Pick the most recent (or only) pod. Describe it to show resource limits, liveness/readiness probes, last state, and events:
   `kubectl describe pod <pod-name> -n <namespace>`

3. Show the last 150 log lines from the running container:
   `kubectl logs -n <namespace> <pod-name> --tail=150`

4. If the pod has restarted, also show logs from the previous container:
   `kubectl logs -n <namespace> <pod-name> --previous --tail=100`

5. Check resource usage:
   `kubectl top pod -n <namespace> -l app=<service>`

6. Show Warning events specifically for this pod:
   `kubectl get events -n <namespace> --field-selector involvedObject.name=<pod-name>`

Present findings as:
- **Pod status**: current state, restart count, uptime
- **Recent logs**: highlight any ERROR, WARN, panic, fatal, exception lines
- **Resource usage**: current CPU/memory vs limits
- **Events**: any Warning events
- **Diagnosis**: likely root cause based on the evidence
- **Next steps**: recommended actions (check Kafka broker, check AAA, check dependent service, etc.)
