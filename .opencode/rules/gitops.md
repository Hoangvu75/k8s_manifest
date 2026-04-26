# GitOps Rules

## No Direct kubectl Updates
- NEVER use `kubectl apply`, `kubectl edit`, `kubectl patch`, `kubectl create`, or any kubectl command that modifies cluster state
- ALL changes to Kubernetes resources MUST go through GitOps: commit YAML manifests to the repository, and ArgoCD will sync them to the cluster
- Read-only kubectl commands (e.g., `kubectl get`, `kubectl describe`, `kubectl logs`, `kubectl top`) are allowed for debugging and inspection

## Helm Chart Source
- When adding or updating Helm charts, prefer using the OCI Helm repository at `ghcr.io/hoangvu75/helm_application`
- The chart is published as a Helm OCI chart via GitHub Container Registry
- Reference it in Kustomize `helmCharts` blocks like:
  ```yaml
  helmCharts:
    - name: <chart-name>
      repo: oci://ghcr.io/hoangvu75/helm_application
      version: <semver>
  ```
