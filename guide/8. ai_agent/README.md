# AI Agent — Kubernetes AI Debug Assistant

This guide describes the `ai-agent` — an AI-powered debug jump pod that integrates directly with your cluster, giving you an intelligent assistant for troubleshooting, diagnostics, and cluster exploration.

## Overview

The `ai-agent` is a persistent pod in the `ai-agent` namespace that provides:

| Feature | Description |
|---------|-------------|
| **k8s-ai assistant** | Interactive AI CLI using DeepSeek API — answers questions, runs commands, analyzes output |
| **aider** | General-purpose AI coding assistant (optional, pre-configured for DeepSeek) |
| **kubectl + helm** | Full Kubernetes CLI tooling for manual debugging |
| **Read-only RBAC** | Cluster-wide read access to all resources (pods, events, nodes, logs, etc.) |

## Workflow

```
You exec into pod ──► ask a question ──► AI decides what commands to run
                                              │
                                              ▼
                                    Runs kubectl commands
                                              │
                                              ▼
                                    Analyzes real output ──► gives you answers
```

## Component Files

Located in `apps/infra/ai-agent/`:

| File | Purpose |
|------|---------|
| `config.yaml` | ApplicationSet discovery (destNamespace: ai-agent, wave: 2) |
| `kustomization.yaml` | Parent kustomize with `namespace: ai-agent` |
| `chart/kustomization.yaml` | Chart-level kustomize (deployment + configmap) |
| `chart/deployment.yaml` | Deployment + ServiceAccount + ClusterRole (read-only) + ClusterRoleBinding |
| `chart/configmap.yaml` | Entrypoint script + `k8s-ai.py` Python assistant |

## Getting Started

### 1. Prerequisites

- The `ai-agent` namespace must exist (synced via `cluster-resources/default/namespace.yaml`, wave: -1)
- The `registry-credentials` imagePullSecret must exist in the `ai-agent` namespace (for pulling `python:3.12-alpine`)
- The `ai-agent-secrets` secret must exist in the `ai-agent` namespace with the `DEEPSEEK_API_KEY`

### 2. Set Up the DeepSeek API Key

The pod needs a `DEEPSEEK_API_KEY` to function. Add this secret to the **private secrets repo** (`k8s_manifest_secrets`):

```yaml
# k8s_manifest_secrets/ai-agent-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-secrets
  namespace: ai-agent
type: Opaque
stringData:
  DEEPSEEK_API_KEY: sk-your-deepseek-api-key
```

Commit and push — ArgoCD syncs it automatically (wave: 1).

### 3. Exec Into the Pod

```bash
kubectl exec -it -n ai-agent deploy/ai-agent -- bash
```

The first startup installs kubectl, helm, and Python packages. This takes ~30 seconds. Once you see:

```
[ai-agent] Setup complete. Ready for debugging.
[ai-agent] Commands: k8s-ai (interactive), aider (AI coding), kubectl/helm (k8s tools)
```

...you're ready.

## Using k8s-ai Assistant

### Interactive Mode

```bash
k8s-ai
```

Starts an interactive session. Three input modes:

#### A. Auto-Run Mode (just ask)

Type a question and the AI decides what commands to run:

```
k8s-ai> what issues do you see in the cluster?
Asking AI what commands to run...
  $ kubectl get nodes -o wide
  $ kubectl get pods -A --field-selector status.phase!=Running,status.phase!=Succeeded
  $ kubectl get events -A --sort-by='.lastTimestamp' --tail 20

Analyzing results...
[AI gives analysis based on real cluster data]
```

```
k8s-ai> why is my pod CrashLoopBackOff?
Asking AI what commands to run...
  $ kubectl get pods -A | grep CrashLoopBackOff
  $ kubectl describe pod -n <ns> <pod-name>
  $ kubectl logs -n <ns> <pod-name>

Analyzing results...
[AI explains the root cause from logs and events]
```

#### B. Manual Command Mode (!)

Run a specific command and have the AI analyze its output:

```
k8s-ai> !kubectl describe pod -n kong-gateway kong-abc123
Running: kubectl describe pod -n kong-gateway kong-abc123...

Analyzing...
[AI analyzes the describe output — image pull errors, probe failures, etc.]
```

#### C. Raw Command Mode (!raw:)

Run a command and see raw output with no AI processing:

```
k8s-ai> !raw:kubectl get pods -A
```

Useful when you just want to see output quickly.

### One-Shot Mode

Ask a question directly without entering interactive mode:

```bash
k8s-ai "check cluster health"
```

The AI auto-runs diagnostic commands and prints the final analysis.

```bash
k8s-ai "analyze all CrashLoopBackOff pods"
```

## Using aider

`aider` is also pre-installed and configured for DeepSeek:

```bash
# Chat interactively about code/config
aider --model deepseek-chat

# Ask about a specific file
aider --model deepseek-chat --message "review this helm chart" /path/to/values.yaml
```

## Available Tooling

| Tool | Installed via | Use Case |
|------|--------------|----------|
| `kubectl` | Binary download | Full cluster management |
| `helm` | get-helm.sh | Helm chart inspection |
| `k8s-ai` | Python script (ConfigMap) | AI-assisted debugging |
| `aider` | pip | General AI coding assistant |
| `git` | apk | Git operations |
| `jq` | apk | JSON parsing |
| `curl` | apk | HTTP requests |
| `openssl` | apk | TLS cert inspection |
| `bash` | apk | Shell scripting |

### Bash Aliases (pre-configured)

Once inside the pod:

| Alias | Command |
|-------|---------|
| `k` | `kubectl` |
| `kg` | `kubectl get` |
| `kd` | `kubectl describe` |
| `kl` | `kubectl logs` |
| `kgp` | `kubectl get pods` |
| `kgn` | `kubectl get nodes` |
| `kgs` | `kubectl get svc` |
| `kga` | `kubectl get all --all-namespaces` |
| `ai` | `k8s-ai` |

## RBAC Permissions

The ai-agent uses a dedicated ServiceAccount with a ClusterRole granting **read-only** access:

| Resource | Verbs |
|----------|-------|
| All API groups and resources | `get`, `list`, `watch` |
| Pod logs, pod status, node stats | `get`, `list`, `watch` |
| Cluster health endpoints (`/healthz`, `/livez`, etc.) | `get` |

No write or delete permissions are granted. The agent can observe but not modify the cluster.

## Troubleshooting

| Issue | Symptom | Fix |
|-------|---------|-----|
| Missing API key | `k8s-ai` exits with "DEEPSEEK_API_KEY not set" | Create `ai-agent-secrets` in private repo |
| Setup timed out | Pod in CrashLoopBackOff at startup | Check logs: install commands may fail (network, disk) |
| kubectl not found | `kubectl not found` | Pod started before download completed — wait or exec in and retry |
| helm not found | `helm not found` | Install manually: `VERIFY_CHECKSUM=false ./get_helm.sh` |
| Python packages missing | `ModuleNotFoundError: openai` | Run `pip install openai` inside the pod |
| Image pull failure | Pod stuck at `ImagePullBackOff` | Ensure `registry-credentials` exists in `ai-agent` namespace |
