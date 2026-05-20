# AI Agent — Kubernetes AI Debug Pods

This guide describes the AI-powered debug jump pods in the `ai-agent` namespace. There are **two** deployments, each backed by a different AI provider:

| Deployment | Image | AI Backend | Auth Method | Use Case |
|-----------|-------|-----------|-------------|----------|
| `ai-agent-deepseek` | `ghcr.io/hoangvu75/ai-agent-deepseek` | DeepSeek API via Anthropic-compatible endpoint | `DEEPSEEK_API_KEY` | Free/cheap cluster debugging |
| `ai-agent-claude` | `ghcr.io/hoangvu75/ai-agent-claude` | Real Anthropic Claude API | `ANTHROPIC_API_KEY` (or OAuth) | Full Claude Code agentic capabilities |

Both provide:
- **Claude Code CLI** — agentic AI assistant that autonomously runs `kubectl`/`helm`, reads logs, analyzes events
- **kubectl + helm** — full Kubernetes CLI tooling
- **Read-only RBAC** — cluster-wide read access (pods, events, nodes, logs, etc.)

## Architecture

### ai-agent-deepseek
```
Claude Code CLI → DeepSeek Anthropic API (https://api.deepseek.com/anthropic)
                   └── Uses deepseek-v4-flash model
                   └── ANTHROPIC_AUTH_TOKEN = DEEPSEEK_API_KEY
```

### ai-agent-claude
```
Claude Code CLI → Real Anthropic API (https://api.anthropic.com)
                   └── Uses Claude models (Sonnet/Opus/Haiku)
                   └── ANTHROPIC_API_KEY from your Anthropic account
```

## Component Files

```
apps/infra/ai-agent/
├── deepseek/                              ← DeepSeek-powered deployment
│   ├── config.yaml                        (destNamespace: ai-agent, wave: 2)
│   ├── kustomization.yaml                 (namespace: ai-agent)
│   ├── Dockerfile                         (node:20-alpine)
│   └── chart/
│       ├── kustomization.yaml
│       └── deployment.yaml                (ai-agent-deepseek SA/CR/CRB)
│
├── claude/                                ← Real Anthropic Claude Code deployment
│   ├── config.yaml                        (destNamespace: ai-agent, wave: 2)
│   ├── kustomization.yaml                 (namespace: ai-agent)
│   ├── Dockerfile                         (ubuntu:22.04)
│   └── chart/
│       ├── kustomization.yaml
│       └── deployment.yaml                (ai-agent-claude SA/CR/CRB)
```

## Getting Started

### 1. Prerequisites

- The `ai-agent` namespace exists (synced via `cluster-resources/default/namespace.yaml`, wave: -1)
- `registry-credentials` imagePullSecret exists in `ai-agent` namespace
- `ai-agent-secrets` secret exists in `ai-agent` namespace

### 2. Set Up Secrets

The shared `ai-agent-secrets` secret holds API keys for both deployments:

```yaml
# k8s_manifest_secrets/ai-agent-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-secrets
  namespace: ai-agent
type: Opaque
stringData:
  DEEPSEEK_API_KEY: sk-your-deepseek-api-key     # for ai-agent-deepseek
  ANTHROPIC_API_KEY: sk-ant-your-anthropic-api-key # for ai-agent-claude
```

- **For `ai-agent-deepseek`**: Set `DEEPSEEK_API_KEY` — get one at https://platform.deepseek.com/
- **For `ai-agent-claude`**: Set `ANTHROPIC_API_KEY` — get one at https://console.anthropic.com/

Commit and push to the private repo — ArgoCD syncs automatically.

### 3. Build & Push Docker Images

```bash
# DeepSeek image (Alpine-based)
docker build -t ghcr.io/hoangvu75/ai-agent-deepseek:latest -f apps/infra/ai-agent/deepseek/Dockerfile apps/infra/ai-agent/deepseek/
docker push ghcr.io/hoangvu75/ai-agent-deepseek:latest

# Claude image (Ubuntu-based)
docker build -t ghcr.io/hoangvu75/ai-agent-claude:latest -f apps/infra/ai-agent/claude/Dockerfile apps/infra/ai-agent/claude/
docker push ghcr.io/hoangvu75/ai-agent-claude:latest
```

### 4. Exec Into a Pod

```bash
# DeepSeek version
kubectl exec -it -n ai-agent deploy/ai-agent-deepseek -- bash

# Real Claude version
kubectl exec -it -n ai-agent deploy/ai-agent-claude -- bash
```

## Using Claude Code

### Start interactive session

```bash
claude
```

If you're using `ai-agent-claude` with `ANTHROPIC_API_KEY` set, no OAuth is needed. If you prefer OAuth (first-time browser login), auth manually:

```bash
claude
# Follow the OAuth URL it prints → Authorize in browser → paste the code back
```

### Debugging Examples

```bash
# Check cluster health
claude> check the cluster health and report any issues

# Investigate failing pods
claude> find all CrashLoopBackOff pods and tell me why they're failing

# Network debugging
claude> show me all services and check which ones have endpoints

# Read and analyze manifests
claude> read all deployments in the kong-gateway namespace and check for issues
```

### One-shot mode

```bash
claude -p "check cluster health and report issues"
```

## When to Use Which

| Situation | Recommended |
|-----------|-------------|
| Quick cluster diagnostic (free) | `ai-agent-deepseek` |
| Complex debugging needing full Claude intelligence | `ai-agent-claude` |
| Limited API budget | `ai-agent-deepseek` |
| Working with sensitive manifests | `ai-agent-claude` (better reasoning) |
| Testing / experimentation | `ai-agent-deepseek` |

## Available Tooling

| Tool | deepseek | claude | Use Case |
|------|----------|--------|----------|
| `claude` | ✅ | ✅ | Agentic AI debugging assistant |
| `kubectl` | ✅ | ✅ | Full cluster management |
| `helm` | ✅ | ✅ | Helm chart inspection |
| `git` | ✅ | ✅ | Git operations |
| `curl` | ✅ | ✅ | HTTP requests |
| `jq` | ✅ | ❌ | JSON parsing |
| `openssl` | ✅ | ❌ | TLS cert inspection |
| `python3` | ✅ | ❌ | Python scripting |

### Bash Aliases (both)

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

### ai-agent-deepseek

| Variable | Value | Purpose |
|----------|-------|---------|
| `DEEPSEEK_API_KEY` | _from secret_ | DeepSeek API authentication |
| `ANTHROPIC_AUTH_TOKEN` | _same as DEEPSEEK_API_KEY_ | Auth for DeepSeek Anthropic API |
| `ANTHROPIC_BASE_URL` | `https://api.deepseek.com/anthropic` | DeepSeek's Claude-compatible endpoint |
| `ANTHROPIC_MODEL` | `deepseek-v4-flash` | Main model |
| `CLAUDE_CODE_EFFORT_LEVEL` | `max` | Maximum reasoning effort |

### ai-agent-claude

| Variable | Value | Purpose |
|----------|-------|---------|
| `ANTHROPIC_API_KEY` | _from secret_ | Real Anthropic API authentication |

## RBAC Permissions

Each deployment has its own ServiceAccount with an identical read-only ClusterRole:

| Resource | Verbs |
|----------|-------|
| All API groups and resources | `get`, `list`, `watch` |
| Pod logs, pod status, node stats | `get`, `list`, `watch` |
| Cluster health endpoints (`/healthz`, `/livez`, etc.) | `get` |

No write or delete permissions. The agents can observe but not modify the cluster.

## Troubleshooting

| Issue | Symptom | Fix |
|-------|---------|-----|
| Missing DeepSeek API key | `ai-agent-deepseek` auth error | Add `DEEPSEEK_API_KEY` to `ai-agent-secrets` in private repo |
| Missing Anthropic API key | `ai-agent-claude` auth error | Add `ANTHROPIC_API_KEY` to `ai-agent-secrets` in private repo |
| Image pull failure | Pod stuck at `ImagePullBackOff` | Build & push the Docker image to GHCR first |
| Claude Code CLI missing | `claude: command not found` | Rebuild Docker image with `npm install -g @anthropic-ai/claude-code` |
