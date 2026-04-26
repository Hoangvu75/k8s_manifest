---
name: gitops-sync
description: Manage ArgoCD sync operations, troubleshoot sync failures, and verify GitOps bootstrap chain integrity
compatibility: opencode
metadata:
  audience: devops
  stack: argocd, gitops, kubernetes
---

## What I Do
- Help diagnose ArgoCD sync failures and application health issues
- Validate the GitOps bootstrap chain (bootstrap → root → projects → apps)
- Guide proper ArgoCD Application/ApplicationSet manifest creation
- Check sync-wave ordering and dependency resolution
- Verify repository credentials and private repo access

## When to Use Me
Use this skill when you need to:
- Debug ArgoCD sync failures or degraded applications
- Add new ArgoCD Applications or ApplicationSets
- Verify the bootstrap chain is correctly wired
- Check sync-wave ordering between infrastructure and application deployments
- Review ApplicationSet generator configurations

## Bootstrap Chain (This Project)
```
bootstrap.yaml (root Application)
  └── bootstrap/
      ├── root.yaml (Application → projects/)
      │   └── projects/
      │       ├── infra.yaml (AppProject + ApplicationSet → apps/infra/**/config.yaml)
      │       └── playground.yaml (AppProject + ApplicationSet → apps/playground/**/config.yaml)
      ├── cluster-resources.yaml (ApplicationSet → cluster-resources/)
      └── secrets.yaml (Application → private secrets repo)
```

## Key ArgoCD Check Commands
```bash
# Check all applications
kubectl get applications -n argocd

# Detailed sync status of one app
kubectl get application <name> -n argocd -o yaml | grep -A20 status

# List ApplicationSets
kubectl get applicationsets -n argocd

# Check sync waves (lower = earlier)
kubectl get applications -n argocd -o json | jq '.items[] | {name: .metadata.name, wave: .metadata.annotations["argocd.argoproj.io/sync-wave"]}'

# View recent sync operations
kubectl get applications -n argocd -o json | jq '.items[] | {name: .metadata.name, syncStatus: .status.sync.status, health: .status.health.status}'
```

## Common ArgoCD Issues & Fixes
1. **"ComparisonError"** → Check repo URL, branch name, and path exist in git
2. **"Unknown" health** → Verify CRDs are installed first (e.g., Gateway API CRDs)
3. **"OutOfSync"** → Check for drift: `kubectl get application <name> -n argocd -o yaml | grep -A50 "reconciliationResult"`
4. **Sync-wave ordering wrong** → Lower sync-wave numbers deploy first; infra should be 0-2, apps 3+
5. **Private repo unreachable** → Verify `argocd-repository-secrets` Secret exists in argocd namespace

## Application Config Pattern
```yaml
# apps/<project>/<app>/config.yaml
labels:
  app: <app-name>
  project: <project-name>
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```
