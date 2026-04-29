# ArgoCD Installation Guide

<cite>
**Referenced Files in This Document**
- [README.md](file://guide/argocd/README.md)
- [argocd-repository-secrets.yaml](file://guide/argocd/argocd-repository-secrets.yaml)
- [bootstrap.yaml](file://bootstrap.yaml)
- [root.yaml](file://bootstrap/root.yaml)
- [cluster-resources.yaml](file://bootstrap/cluster-resources.yaml)
- [secrets.yaml](file://bootstrap/secrets.yaml)
- [kustomization.yaml](file://bootstrap/kustomization.yaml)
- [kustomization.yaml](file://kustomization.yaml)
- [argocd-ingress-kustomization.yaml](file://apps/playground/argocd-ingress/kustomization.yaml)
- [argocd-ingress-values.yaml](file://apps/playground/argocd-ingress/chart/values.yaml)
- [argocd-cmd-params-cm.yaml](file://apps/playground/argocd-ingress/chart/argocd-cmd-params-cm.yaml)
- [httproute-argocd.yaml](file://apps/playground/argocd-ingress/chart/httproute-argocd.yaml)
- [playground.yaml](file://projects/playground.yaml)
- [infra.yaml](file://projects/infra.yaml)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Installation Steps](#installation-steps)
4. [Initial Configuration](#initial-configuration)
5. [Private Repository Setup](#private-repository-setup)
6. [Bootstrap Process](#bootstrap-process)
7. [Application Management](#application-management)
8. [Ingress Configuration](#ingress-configuration)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Introduction

This guide provides a comprehensive walkthrough for installing and configuring ArgoCD in a Kubernetes cluster using GitOps principles. The installation follows a structured approach that leverages Kustomize for configuration management and ArgoCD's native capabilities for declarative infrastructure management.

ArgoCD serves as the GitOps engine for managing Kubernetes applications through automated synchronization from Git repositories. This implementation demonstrates enterprise-grade deployment patterns with proper separation of concerns, security considerations, and scalable application management.

## Prerequisites

Before beginning the ArgoCD installation, ensure you have the following prerequisites in place:

- **Kubernetes Cluster**: Access to a working Kubernetes cluster with administrative privileges
- **kubectl**: Properly configured with cluster credentials
- **Git Repositories**: Two separate repositories - one for manifests and another for secrets
- **Network Access**: DNS resolution and network connectivity for external services
- **Certificate Management**: Proper SSL/TLS certificate handling for secure communications

**Section sources**
- [README.md:1-34](file://guide/argocd/README.md#L1-L34)

## Installation Steps

The ArgoCD installation follows a systematic approach that ensures proper initialization and configuration of all components.

### Step 1: Namespace Creation and Base Installation

Create the dedicated namespace and deploy the core ArgoCD components using the official manifest:

```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

This command establishes the foundational ArgoCD infrastructure including deployments, services, and required RBAC permissions.

### Step 2: Kustomize Configuration Enablement

Enable Helm support for Kustomize builds to enhance package management capabilities:

```bash
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'
kubectl rollout restart deployment argocd-repo-server -n argocd
```

This configuration allows ArgoCD to handle Helm charts within the Kustomize pipeline, expanding deployment flexibility.

### Step 3: Access Configuration

Configure secure access to the ArgoCD dashboard through port forwarding:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

**Section sources**
- [README.md:3-16](file://guide/argocd/README.md#L3-L16)

## Initial Configuration

The initial configuration establishes the foundation for GitOps operations and repository access management.

### Repository Secret Management

Configure secrets for accessing private Git repositories through dedicated Secret resources:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: repo-github-k8s-manifest
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/Hoangvu75/k8s_manifest.git
  username: "Hoangvu75"
  password: "GITHUB_PAT"
```

This approach separates sensitive credential management from the main manifest repository, enhancing security through dedicated secret management.

**Section sources**
- [argocd-repository-secrets.yaml:1-30](file://guide/argocd/argocd-repository-secrets.yaml#L1-L30)

## Private Repository Setup

The private repository configuration enables secure access to protected Git repositories while maintaining separation between public and private content.

### Multi-Repository Architecture

The implementation supports dual repository architecture:
- **Public Manifest Repository**: Contains non-sensitive Kubernetes manifests
- **Private Secrets Repository**: Houses sensitive configuration and credentials

### Repository Secret Structure

Each repository requires corresponding Secret entries with specific metadata:

| Field | Description | Example |
|-------|-------------|---------|
| `type` | Repository type (always git) | git |
| `url` | Complete HTTPS URL with credentials | https://user:token@github.com/org/repo.git |
| `username` | Git provider username or service account | Hoangvu75 |
| `password` | Personal Access Token or credentials | GITHUB_PAT |

**Section sources**
- [argocd-repository-secrets.yaml:12-29](file://guide/argocd/argocd-repository-secrets.yaml#L12-L29)

## Bootstrap Process

The bootstrap process establishes the foundational ArgoCD Applications that orchestrate the entire GitOps workflow.

### Root Application Configuration

The root Application defines the primary entry point for the entire infrastructure:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: argocd
spec:
  source:
    path: projects
    repoURL: PLACEHOLDER
    targetRevision: PLACEHOLDER
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  syncPolicy:
    automated:
      allowEmpty: true
      prune: true
      selfHeal: true
```

### Cluster Resources Management

The cluster-resources ApplicationSet dynamically manages cluster-wide resources across multiple environments:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cluster-resources
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - name: default
  template:
    spec:
      source:
        path: cluster-resources/{{name}}
        repoURL: PLACEHOLDER
        targetRevision: PLACEHOLDER
```

### Secrets Management

The secrets Application provides secure management of sensitive configurations:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: secrets
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  source:
    path: .
    repoURL: PLACEHOLDER
    targetRevision: PLACEHOLDER
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**Section sources**
- [root.yaml:1-37](file://bootstrap/root.yaml#L1-L37)
- [cluster-resources.yaml:1-33](file://bootstrap/cluster-resources.yaml#L1-L33)
- [secrets.yaml:1-24](file://bootstrap/secrets.yaml#L1-L24)

## Application Management

The application management system leverages ArgoCD's advanced features for scalable infrastructure orchestration.

### Project Configuration

Each environment maintains dedicated AppProject configurations with appropriate resource permissions:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: playground
  namespace: argocd
spec:
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  destinations:
    - namespace: '*'
      server: '*'
  sourceRepos:
    - '*'
```

### ApplicationSet Templates

The ApplicationSet framework enables dynamic generation of applications based on Git repository structure:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: playground
  namespace: argocd
spec:
  generators:
    - git:
        repoURL: PLACEHOLDER
        revision: PLACEHOLDER
        files:
          - path: "apps/playground/**/config.yaml"
  template:
    spec:
      source:
        kustomize:
          buildOptions: "--enable-helm"
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

**Section sources**
- [playground.yaml:1-85](file://projects/playground.yaml#L1-L85)
- [infra.yaml:1-85](file://projects/infra.yaml#L1-L85)

## Ingress Configuration

The ingress configuration provides secure, externally accessible ArgoCD UI through modern Kubernetes networking standards.

### HTTPRoute Definition

The HTTPRoute resource defines traffic routing with advanced header manipulation:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: argocd
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "3"
spec:
  parentRefs:
    - name: shared-gateway
      namespace: gateway-api
  hostnames:
    - "argocd.hoangvu75.space"
  rules:
    - backendRefs:
        - name: argocd-server
          port: 80
```

### Gateway Integration

The configuration integrates with the Gateway API for modern ingress management:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmd-params-cm
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "2"
data:
  server.insecure: "true"
```

**Section sources**
- [httproute-argocd.yaml:1-29](file://apps/playground/argocd-ingress/chart/httproute-argocd.yaml#L1-L29)
- [argocd-cmd-params-cm.yaml:1-13](file://apps/playground/argocd-ingress/chart/argocd-cmd-params-cm.yaml#L1-L13)

## Dependency Analysis

The ArgoCD installation demonstrates sophisticated dependency management through Kustomize replacements and strategic ordering.

### Configuration Replacement Flow

```mermaid
flowchart TD
RepoConfig[Repo Configuration] --> Bootstrap[Bootstrap Kustomization]
RepoConfig --> RootApp[Root Application]
RepoConfig --> SecretsApp[Secrets Application]
RepoConfig --> ClusterAS[Cluster ApplicationSet]
Bootstrap --> BootstrapApp[Bootstrap Application]
RootApp --> Projects[Projects Directory]
SecretsApp --> SecretRepo[Secrets Repository]
ClusterAS --> ClusterApps[Cluster Applications]
RepoConfig --> AllApps[All Managed Applications]
```

**Diagram sources**
- [kustomization.yaml:10-31](file://kustomization.yaml#L10-L31)
- [bootstrap/kustomization.yaml:12-63](file://bootstrap/kustomization.yaml#L12-L63)

### Application Synchronization Order

The synchronization order ensures proper dependency resolution:

1. **Wave -2**: AppProject configurations
2. **Wave -1**: Cluster resources preparation  
3. **Wave 0**: Core infrastructure setup
4. **Wave 1**: Secret management
5. **Wave 2**: Application configurations
6. **Wave 3**: Ingress and routing

**Section sources**
- [playground.yaml:5-6](file://projects/playground.yaml#L5-L6)
- [cluster-resources.yaml:4-5](file://bootstrap/cluster-resources.yaml#L4-L5)
- [secrets.yaml:6-7](file://bootstrap/secrets.yaml#L6-L7)

## Troubleshooting

Common issues and their resolutions during ArgoCD installation and operation.

### Installation Issues

**Problem**: ArgoCD pods fail to start
**Solution**: Check namespace creation and RBAC permissions
```bash
kubectl get pods -n argocd
kubectl describe pod -n argocd <pod-name>
```

**Problem**: Repository access failures
**Solution**: Verify secret configuration and network connectivity
```bash
kubectl get secret -n argocd | grep repository
kubectl logs -n argocd deployment/argocd-repo-server
```

### Configuration Validation

**Problem**: Applications not syncing properly
**Solution**: Review sync policies and repository URLs
```bash
kubectl get application -n argocd
kubectl describe application <app-name> -n argocd
```

**Section sources**
- [README.md:29-33](file://guide/argocd/README.md#L29-L33)

## Best Practices

### Security Considerations

- **Separation of Concerns**: Maintain distinct repositories for public and private content
- **Credential Rotation**: Regularly update Personal Access Tokens and rotate secrets
- **Network Security**: Implement proper firewall rules and TLS termination
- **RBAC Management**: Restrict permissions to least privilege principle

### Operational Excellence

- **Automated Sync**: Configure appropriate sync policies for different environments
- **Monitoring**: Implement health checks and alerting for critical components
- **Backup Strategy**: Regular snapshots of ArgoCD state and repository contents
- **Documentation**: Maintain comprehensive documentation of all configurations

### Scalability Patterns

- **Modular Design**: Keep configurations modular and reusable across environments
- **Environment Segmentation**: Separate development, staging, and production environments
- **Resource Management**: Implement proper resource quotas and limits
- **Performance Optimization**: Monitor and optimize sync frequencies and retry policies