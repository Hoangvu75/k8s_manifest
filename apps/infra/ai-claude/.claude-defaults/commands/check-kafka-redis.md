Test Kafka broker and Redis connectivity from a pod inside the cluster.

Arguments: $ARGUMENTS

Parse as: first word = namespace, second word = pod name (or service label to find a pod).
If only one argument is given, treat it as a namespace and find any running pod in it.

Known addresses:
- Kafka UAT:        10.40.80.236:9092
- Kafka STG:        10.40.82.41:9092, 10.40.82.42:9092, 10.40.82.43:9092
- Kafka PROD:       10.40.43.154:9092, 10.40.43.155:9092, 10.40.43.156:9092
- Redis UAT:        10.40.80.236:6379  (password: kafi@2024)
- Redis PROD Sentinel: 10.40.43.154:26379, 10.40.43.155:26379, 10.40.43.156:26379

Steps:

1. Find a running pod to use as the test source:
   `kubectl get pods -n <namespace> --field-selector=status.phase=Running -o name | head -1`

2. Test UAT Kafka broker connectivity:
   `kubectl exec -n <namespace> <pod> -- nc -zv -w 5 10.40.80.236 9092`

3. Test STG Kafka brokers:
   `kubectl exec -n <namespace> <pod> -- nc -zv -w 5 10.40.82.41 9092`
   `kubectl exec -n <namespace> <pod> -- nc -zv -w 5 10.40.82.42 9092`
   `kubectl exec -n <namespace> <pod> -- nc -zv -w 5 10.40.82.43 9092`

4. Test UAT Redis connectivity:
   `kubectl exec -n <namespace> <pod> -- nc -zv -w 5 10.40.80.236 6379`

5. If nc is available, also do a Redis PING to verify the service responds (not just TCP):
   `kubectl exec -n <namespace> <pod> -- sh -c "echo -e '*1\r\n\$4\r\nPING\r\n' | nc -w 3 10.40.80.236 6379"`
   Expected response: `+PONG`

6. Test UAT Redis Sentinel port (if applicable):
   `kubectl exec -n <namespace> <pod> -- nc -zv -w 5 10.40.80.236 26379`

7. Test PROD Redis Sentinel ports:
   `kubectl exec -n <namespace> <pod> -- nc -zv -w 5 10.40.43.154 26379`
   `kubectl exec -n <namespace> <pod> -- nc -zv -w 5 10.40.43.155 26379`
   `kubectl exec -n <namespace> <pod> -- nc -zv -w 5 10.40.43.156 26379`

8. Check DNS resolution for cluster-internal services:
   `kubectl exec -n <namespace> <pod> -- nslookup rest.kx-customers.svc.cluster.local`

9. If nc is not available, fall back to curl:
   `kubectl exec -n <namespace> <pod> -- curl -s --connect-timeout 5 telnet://10.40.80.236:9092`
   `kubectl exec -n <namespace> <pod> -- curl -s --connect-timeout 5 telnet://10.40.80.236:6379`

Present results as:
- **Kafka connectivity table**: broker address → reachable/unreachable
- **Redis connectivity table**: Redis/Sentinel address → reachable/unreachable + PONG response
- **DNS resolution**: working/failing
- **Diagnosis**: network issue, service down, or all healthy
- **Context**: if unreachable, check Cilium agent status (`kubectl get po -n kube-system -l k8s-app=cilium -o wide`) and network policies
