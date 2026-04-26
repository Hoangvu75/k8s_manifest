---
name: k8s-debug
description: Debug Kubernetes resources using read-only kubectl commands — diagnostic only, no mutations allowed
compatibility: opencode
metadata:
  audience: devops
  stack: kubernetes, kubectl, debugging
---

## What I Do
- Provide safe, read-only kubectl commands for diagnosing Kubernetes issues
- Interpret pod statuses, resource usage, events, and logs
- Troubleshoot common K8s problems (CrashLoopBackOff, ImagePullBackOff, OOMKilled, Pending pods)
- Check ArgoCD sync status and identify drift

## When to Use Me
Use this skill when you need to:
- Investigate why a pod is failing or not starting
- Check resource utilization (CPU/Memory)
- Verify network connectivity between services
- Inspect ArgoCD sync status and health
- Debug Gateway API / HTTPRoute routing issues

## Allowed Commands (Read-Only)
```
kubectl get <resource> [-n <namespace>] [-o wide|yaml|json]
kubectl describe <resource> <name> [-n <namespace>]
kubectl logs <pod> [-n <namespace>] [-c <container>] [--tail=N] [--previous]
kubectl top pods/nodes [-n <namespace>]
kubectl explain <resource> [--recursive]
kubectl api-resources | api-versions
kubectl get events [-n <namespace>] [--sort-by='.lastTimestamp']
kubectl port-forward <pod> <local>:<remote> [-n <namespace>]
kubectl auth can-i <verb> <resource> [-n <namespace>]
```

## CRITICAL: Never Mutate
- NEVER use `kubectl apply`, `kubectl edit`, `kubectl patch`, `kubectl create`, `kubectl delete`, `kubectl scale`, `kubectl rollout`, `kubectl set`
- ALL changes must go through Git commits + ArgoCD sync
- If a fix is needed, explain the YAML changes required and let the user commit them

## Common Diagnostic Patterns
1. **Pod not starting**: `kubectl describe pod` → check Events, `kubectl logs` → check app errors
2. **Service unreachable**: `kubectl get endpoints` → verify selector matches, `kubectl get svc` → check ports
3. **ArgoCD out of sync**: `kubectl get applications -n argocd` → check sync status
4. **Gateway API routing**: `kubectl get httproute -A` → check backendRefs, `kubectl get gateway -A` → verify listeners
5. **Cert-manager issues**: `kubectl get certificaterequests,certificates,orders,challenges -A` → trace the chain
