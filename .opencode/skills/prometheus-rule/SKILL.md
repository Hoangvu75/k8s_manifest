---
name: prometheus-rule
description: Create and manage Prometheus alerting rules and recording rules with proper severity, labels, and annotations
compatibility: opencode
metadata:
  audience: devops
  stack: prometheus, grafana, monitoring, alertmanager
---

## What I Do
- Help create Prometheus alerting rules with proper severity levels and runbook URLs
- Design recording rules for precomputed metrics to improve dashboard performance
- Review existing rules for correctness, label hygiene, and alert fatigue
- Provide PromQL query patterns for common Kubernetes monitoring scenarios

## When to Use Me
Use this skill when you need to:
- Create new alerting rules for Kubernetes workloads
- Write PromQL queries for dashboards or alerts
- Set up ServiceMonitor or PodMonitor resources
- Review alert configurations for best practices

## PromQL Patterns

### Kubernetes Workload Monitoring
```promql
# Pod CPU throttling
rate(container_cpu_cfs_throttled_seconds_total{container!=""}[5m]) > 0

# Pod restart rate
rate(kube_pod_container_status_restarts_total[15m]) > 0

# Pod not ready
kube_pod_status_ready{condition="true"} == 0

# Deployment replicas mismatch
kube_deployment_spec_replicas != kube_deployment_status_replicas_available

# Node disk pressure
kube_node_status_condition{condition="DiskPressure",status="true"} == 1

# OOM kills
rate(kube_pod_container_status_terminated_reason{reason="OOMKilled"}[5m]) > 0

# PVC usage > 80%
kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.8
```

### Resource Monitoring
```promql
# Memory usage > 90% of limit
container_memory_working_set_bytes / container_spec_memory_limit_bytes > 0.9

# CPU usage > 80% of limit (for threshold alerts)
rate(container_cpu_usage_seconds_total[5m]) / container_spec_cpu_limit > 0.8
```

## Alert Rule Template
```yaml
groups:
  - name: <group-name>
    rules:
      - alert: <AlertName>
        expr: <PromQL expression>
        for: <duration>
        labels:
          severity: critical|warning|info
          component: <kubernetes|infrastructure|application>
        annotations:
          summary: "<human-readable summary>"
          description: "<detailed description with $labels>"
          runbook_url: "<link to runbook>"
```

## Severity Guidelines
- **critical** — Service down, data loss risk, requires immediate pager response
- **warning** — Degraded service, approaching limits, needs attention within hours
- **info** — Informational, no immediate action required

## ArgoCD Integration for PrometheusRules
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: <name>
  namespace: <namespace>
  labels:
    release: kube-prometheus-stack
spec:
  groups: [...]
```

## Best Practices
- Use `for:` duration to avoid flapping alerts (minimum 5m for warning, 15m for critical)
- Always include `summary` and `description` annotations with actionable information
- Include `runbook_url` annotation pointing to troubleshooting docs
- Use `absent()` to detect missing metrics (e.g., `absent(up{job="critical"})`)
- Group related alerts in logical rule groups
