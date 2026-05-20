# AI Agent — Claude Code CLI for Kubernetes Debugging

This guide describes the `ai-agent` — an AI-powered debug jump pod with **Claude Code CLI** (by Anthropic) configured to use DeepSeek's Anthropic-compatible API endpoint, giving you a powerful agentic assistant for troubleshooting and exploring the cluster.

## Overview

The `ai-agent` is a persistent pod in the `ai-agent` namespace that provides:

| Feature | Description |
|---------|-------------|
| **Claude Code CLI** | Full agentic AI assistant — autonomously reads files, runs `kubectl`/`helm` commands, analyzes output, and debugs cluster issues |
| **aider** | General-purpose AI coding assistant (optional, pre-configured for DeepSeek) |
| **kubectl + helm** | Full Kubernetes CLI tooling for manual debugging |
| **Read-only RBAC** | Cluster-wide read access to all resources (pods, events, nodes, logs, etc.) |

## Architecture

```
Claude Code (agentic CLI)
  ├── Runs kubectl commands autonomously
  ├── Reads pod logs, describe output, events
  ├── Analyzes cluster state and suggests fixes
  └── Backed by DeepSeek API via Anthropic endpoint
        └── ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic

Example workflow:
  ┌─ You exec into pod ─────────────────────────────┐
  │  claude                                          │
  │                                                   │
  │  > what's wrong with the cluster?                 │
  │                                                   │
  │  Claude Code reads /root/.kube/config            │
  │  Claude Code runs: kubectl get nodes              │
  │  Claude Code runs: kubectl get pods -A --sort-by  │
  │  Claude Code analyzes output from ALL commands    │
  │  Claude Code: "I see 3 issues: ..."              │
  └───────────────────────────────────────────────────┘
```

## Why Claude Code?

Claude Code is a **full agentic CLI** built specifically for terminal environments. Unlike the custom `k8s-ai.py` assistant it replaces, Claude Code can:

- **Read any file** in the environment (configs, logs, manifests)
- **Run any command** autonomously (kubectl, helm, curl, jq, git)
- **Chain multiple commands** together based on what it discovers
- **Edit files** and suggest fixes
- **Search code** and navigate the filesystem
- **Maintain context** across a long conversation

DeepSeek provides an Anthropic-compatible API endpoint (`https://api.deepseek.com/anthropic`), so Claude Code works seamlessly with DeepSeek's models.

## Component Files

Located in `apps/infra/ai-agent/`:

| File | Purpose |
|------|---------|
| `config.yaml` | ApplicationSet discovery (destNamespace: ai-agent, wave: 2) |
| `kustomization.yaml` | Parent kustomize with `namespace: ai-agent` |
| `chart/kustomization.yaml` | Chart-level kustomize (deployment + configmap) |
| `chart/deployment.yaml` | Deployment + ServiceAccount + ClusterRole (read-only) + ClusterRoleBinding |
| `chart/configmap.yaml` | Entrypoint script (installs Claude Code, kubectl, helm, tools) |

## Getting Started

### 1. Prerequisites

- The `ai-agent` namespace must exist (synced via `cluster-resources/default/namespace.yaml`, wave: -1)
- The `registry-credentials` imagePullSecret must exist in the `ai-agent` namespace (for pulling `node:20-alpine`)
- The `ai-agent-secrets` secret must exist in the `ai-agent` namespace with the DeepSeek API key

### 2. Set Up the DeepSeek API Key

The pod needs a DeepSeek API key. Add this secret to the **private secrets repo** (`k8s_manifest_secrets`):

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

The `DEEPSEEK_API_KEY` is automatically mapped to `ANTHROPIC_AUTH_TOKEN` in the deployment. Commit and push — ArgoCD syncs it automatically.

### 3. Exec Into the Pod

```bash
kubectl exec -it -n ai-agent deploy/ai-agent -- bash
```

The first startup installs Node.js dependencies, kubectl, helm, and tools. This takes about 30-60 seconds. Once you see:

```
[ai-agent] Setup complete.
[ai-agent] Just run: claude
[ai-agent] Also available: aider, kubectl, helm, curl, jq
```

...you're ready.

## Using Claude Code

### Start the interactive session

```bash
claude
# or claude --dangerous-skip-permissions
```

This launches Claude Code in your terminal. It will automatically use the DeepSeek API (configured via environment variables).

### Debugging Examples

**1. General cluster health check**

```
claude> check the cluster health and report any issues
```

Claude Code will autonomously:
- Run `kubectl get nodes` to check node status
- Run `kubectl get pods -A` to find problem pods
- Run `kubectl get events -A --sort-by='.lastTimestamp'` to find recent issues
- Analyze all results together and give you a comprehensive report

**2. Investigate a specific problem pod**

```
claude> find all CrashLoopBackOff pods and tell me why they're failing
```

Claude Code will:
- Find all pods not in Running state
- Run `kubectl describe pod` on each failing pod
- Run `kubectl logs` on each to see error messages
- Cross-reference events
- Give you root cause analysis for each one

**3. Network debugging**

```
claude> check if the gateway-api services are reachable and all ingress routes work
```

**4. Read and analyze manifests**

```
claude> read the deployment manifest and tell me if there are any configuration issues
```

### Non-interactive (one-shot)

```bash
claude -p "check cluster health and report issues"
```

The `-p` flag sends a single prompt without starting an interactive session.

## Using aider

`aider` is also available for general AI coding tasks:

```bash
aider --model deepseek-chat
```

Pre-configured via `~/.aider.conf.yml` with `api-key: env:DEEPSEEK_API_KEY`.

## Available Tooling

| Tool | Installed via | Use Case |
|------|--------------|----------|
| `claude` | npm (`@anthropic-ai/claude-code`) | Agentic AI debugging assistant |
| `kubectl` | Binary download | Full cluster management |
| `helm` | get-helm.sh | Helm chart inspection |
| `aider` | pip | General AI coding assistant |
| `git` | apk | Git operations |
| `jq` | apk | JSON parsing |
| `curl` | apk | HTTP requests |
| `openssl` | apk | TLS cert inspection |

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
| `ai` | `claude` |

## Environment Variables

The following environment variables are pre-set in the deployment to connect Claude Code to DeepSeek:

| Variable | Value | Purpose |
|----------|-------|---------|
| `ANTHROPIC_AUTH_TOKEN` | _same as `DEEPSEEK_API_KEY`_ | Auth for DeepSeek Anthropic API |
| `ANTHROPIC_BASE_URL` | `https://api.deepseek.com/anthropic` | DeepSeek's Claude-compatible endpoint |
| `ANTHROPIC_MODEL` | `deepseek-v4-pro` | Main model |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `deepseek-v4-pro` | Heavy tasks (cluster analysis) |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `deepseek-v4-pro` | Standard tasks |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `deepseek-v4-flash` | Lightweight / fast tasks |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `deepseek-v4-flash` | Sub-agents (file search, etc.) |
| `CLAUDE_CODE_EFFORT_LEVEL` | `max` | Maximum reasoning effort |
| `DEEPSEEK_API_KEY` | _from secret_ | Fallback for aider / direct API |

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
| Missing API key | Claude Code auth error | Create `ai-agent-secrets` in private repo with `DEEPSEEK_API_KEY` |
| Setup timed out | Pod in CrashLoopBackOff at startup | Check logs — `kubectl logs -n ai-agent deploy/ai-agent` |
| Claude Code install failed | `claude: command not found` | Exec into pod and run: `npm install -g @anthropic-ai/claude-code` |
| kubectl not found | `kubectl not found` | Run manually: `curl -sLO https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin/kubectl` |
| helm not found | `helm not found` | Run: `VERIFY_CHECKSUM=false ./get_helm.sh` |
| Image pull failure | Pod stuck at `ImagePullBackOff` | Ensure `registry-credentials` exists in `ai-agent` namespace |
