# Application Structure and Organization

<cite>
**Referenced Files in This Document**
- [README.md](file://README.md)
- [kustomization.yaml](file://kustomization.yaml)
- [bootstrap.yaml](file://bootstrap.yaml)
- [bootstrap/kustomization.yaml](file://bootstrap/kustomization.yaml)
- [bootstrap/root.yaml](file://bootstrap/root.yaml)
- [bootstrap/cluster-resources.yaml](file://bootstrap/cluster-resources.yaml)
- [projects/kustomization.yaml](file://projects/kustomization.yaml)
- [projects/infra.yaml](file://projects/infra.yaml)
- [projects/applications.yaml](file://projects/applications.yaml)
- [cluster-resources/default/namespace.yaml](file://cluster-resources/default/namespace.yaml)
- [apps/infra/cloudflared/config.yaml](file://apps/infra/cloudflared/config.yaml)
- [apps/infra/cloudflared/kustomization.yaml](file://apps/infra/cloudflared/kustomization.yaml)
- [apps/infra/cloudflared/chart/kustomization.yaml](file://apps/infra/cloudflared/chart/kustomization.yaml)
- [apps/infra/cloudflared/chart/values.yaml](file://apps/infra/cloudflared/chart/values.yaml)
- [apps/infra/gateway-api/config.yaml](file://apps/infra/gateway-api/config.yaml)
- [apps/infra/rancher/config.yaml](file://apps/infra/rancher/config.yaml)
- [apps/infra/rancher/kustomization.yaml](file://apps/infra/rancher/kustomization.yaml)
- [apps/infra/rancher/chart/kustomization.yaml](file://apps/infra/rancher/chart/kustomization.yaml)
- [apps/infra/rancher/chart/values-cert-manager.yaml](file://apps/infra/rancher/chart/values-cert-manager.yaml)
- [apps/applications/hello-api/config.yaml](file://apps/applications/hello-api/config.yaml)
- [apps/applications/hello-api/kustomization.yaml](file://apps/applications/hello-api/kustomization.yaml)
- [apps/applications/hello-api/chart/kustomization.yaml](file://apps/applications/hello-api/chart/kustomization.yaml)
- [components/repo-url/kustomization.yaml](file://components/repo-url/kustomization.yaml)
</cite>

## Update Summary
**Changes Made**
- Updated directory structure references from apps/playground/ to apps/applications/
- Added documentation for the new apps/infra/ directory containing platform infrastructure components
- Updated ApplicationSet generators to reflect the new directory organization
- Added comprehensive coverage of the consolidated rancher application with integrated cert-manager
- Updated examples to show the distinction between infrastructure and user-facing applications

## Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Architecture Overview](#architecture-overview)
5. [Detailed Component Analysis](#detailed-component-analysis)
6. [Dependency Analysis](#dependency-analysis)
7. [Performance Considerations](#performance-considerations)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Conclusion](#conclusion)

## Introduction
This document explains the standard application structure used in this GitOps system. It covers:
- The mandatory config.yaml format and its role in ApplicationSet discovery and per-app configuration
- The role of kustomization.yaml in defining namespaces and composing resources
- The optional chart/ directory pattern for Helm-based deployments
- How applications are organized by type (infrastructure vs applications) and how this affects configuration patterns
- Examples of minimal application setups and the purpose of each configuration file
- Namespace isolation principles and how applications inherit from base configurations

**Updated** The repository now organizes applications into two distinct categories: platform infrastructure components in apps/infra/ and user-facing demonstration applications in apps/applications/.

## Project Structure
The repository follows a layered GitOps structure with a clear separation between infrastructure and application components:
- Root Kustomize composes bootstrap artifacts and injects repository URLs
- Bootstrap installs the root Application pointing to projects/
- projects/ defines AppProjects and ApplicationSets that discover apps under apps/**
- apps/infra/ contains platform infrastructure components with shared namespaces and early synchronization
- apps/applications/ contains user-facing demonstration applications with isolated namespaces

```mermaid
graph TB
A["Root Kustomize<br/>kustomization.yaml"] --> B["bootstrap.yaml"]
A --> C["components/repo-url<br/>repo-config"]
B --> D["bootstrap/root.yaml"]
D --> E["projects/infra.yaml"]
D --> F["projects/applications.yaml"]
E --> G["apps/infra/**/config.yaml"]
F --> H["apps/applications/**/config.yaml"]
G --> I["apps/infra/**/kustomization.yaml"]
H --> J["apps/applications/**/kustomization.yaml"]
I --> K["apps/infra/**/chart/*"]
J --> L["apps/applications/**/chart/*"]
M["cluster-resources/default/namespace.yaml"] --> N["Namespaces created with sync-wave -1"]
O["apps/infra/rancher/chart/kustomization.yaml"] --> P["Integrated cert-manager + rancher deployment"]
Q["apps/applications/hello-api/chart/kustomization.yaml"] --> R["User-facing demo application"]
```

**Diagram sources**
- [kustomization.yaml:1-21](file://kustomization.yaml#L1-L21)
- [bootstrap.yaml:1-26](file://bootstrap.yaml#L1-L26)
- [bootstrap/root.yaml:1-37](file://bootstrap/root.yaml#L1-L37)
- [projects/infra.yaml:1-85](file://projects/infra.yaml#L1-L85)
- [projects/applications.yaml:1-85](file://projects/applications.yaml#L1-L85)
- [apps/infra/cloudflared/config.yaml:1-4](file://apps/infra/cloudflared/config.yaml#L1-L4)
- [apps/infra/rancher/chart/kustomization.yaml:1-20](file://apps/infra/rancher/chart/kustomization.yaml#L1-L20)
- [apps/applications/hello-api/chart/kustomization.yaml:1-14](file://apps/applications/hello-api/chart/kustomization.yaml#L1-L14)
- [cluster-resources/default/namespace.yaml:1-52](file://cluster-resources/default/namespace.yaml#L1-L52)

**Section sources**
- [README.md:87-118](file://README.md#L87-L118)
- [README.md:128-134](file://README.md#L128-L134)

## Core Components
- Root Kustomize: Composes bootstrap.yaml and injects repo URLs from components/repo-url
- Bootstrap: Creates the root Application and applies cluster-resources and secrets
- Projects: Defines AppProjects and ApplicationSets that scan for config.yaml files in separate directories
- Apps: Per-application folders with config.yaml and kustomization.yaml; optional Helm via chart/

Key responsibilities:
- config.yaml: Declares destination namespace and optional sync-wave annotation for ordering
- kustomization.yaml: Sets namespace and includes chart/ or raw resources
- chart/: Optional Helm chart packaged with helmCharts and values

**Section sources**
- [README.md:57-75](file://README.md#L57-L75)
- [README.md:136-143](file://README.md#L136-L143)
- [README.md:144-147](file://README.md#L144-L147)

## Architecture Overview
The GitOps pipeline and sync order are orchestrated by sync-wave annotations and ApplicationSet generators, with clear separation between infrastructure and application components.

```mermaid
sequenceDiagram
participant Dev as "Developer"
participant Repo as "Git Repo"
participant Argo as "ArgoCD"
participant KS as "Kustomize"
participant Helm as "Helm"
participant K8s as "Kubernetes"
Dev->>Repo : Push changes
Repo-->>Argo : Webhook/refresh
Argo->>KS : Build root kustomization.yaml
KS-->>Argo : bootstrap.yaml with repo URLs
Argo->>K8s : Apply bootstrap/root.yaml
Argo->>KS : Build projects/infra.yaml and applications.yaml
KS-->>Argo : AppProject + ApplicationSet manifests
Argo->>Argo : Discover apps via config.yaml (infra/applications)
Argo->>KS : Build app kustomization.yaml (--enable-helm)
KS->>Helm : Render helmCharts (optional)
Helm-->>KS : Rendered manifests
KS-->>Argo : Final manifests
Argo->>K8s : Sync with sync-wave ordering
Note over Argon : Infrastructure first (-2 to 3)<br/>Applications later (3)
```

**Diagram sources**
- [README.md:57-86](file://README.md#L57-L86)
- [kustomization.yaml:1-21](file://kustomization.yaml#L1-L21)
- [bootstrap/root.yaml:1-37](file://bootstrap/root.yaml#L1-L37)
- [projects/infra.yaml:33-60](file://projects/infra.yaml#L33-L60)
- [projects/applications.yaml:33-60](file://projects/applications.yaml#L33-L60)
- [apps/infra/cloudflared/kustomization.yaml:1-8](file://apps/infra/cloudflared/kustomization.yaml#L1-L8)
- [apps/infra/rancher/chart/kustomization.yaml:1-20](file://apps/infra/rancher/chart/kustomization.yaml#L1-L20)
- [apps/applications/hello-api/chart/kustomization.yaml:1-14](file://apps/applications/hello-api/chart/kustomization.yaml#L1-L14)

## Detailed Component Analysis

### config.yaml: Application Discovery and Destination Namespace
Purpose:
- Provides destination namespace for the Application
- Optionally sets sync-wave for ordering
- Supports arbitrary annotations passed into ApplicationSet templatePatch

Typical fields:
- destNamespace: overrides the default derived namespace
- annotations: map of annotations applied to generated Application
- syncPolicy: additional sync options like CreateNamespace=true

Example references:
- Infrastructure app with explicit namespace and sync-wave
  - [apps/infra/cloudflared/config.yaml:1-4](file://apps/infra/cloudflared/config.yaml#L1-L4)
  - [apps/infra/gateway-api/config.yaml:1-6](file://apps/infra/gateway-api/config.yaml#L1-L6)
- Infrastructure app with namespace creation policy
  - [apps/infra/gateway-api/config.yaml:1-6](file://apps/infra/gateway-api/config.yaml#L1-L6)
- User-facing application with its own namespace and late sync
  - [apps/applications/hello-api/config.yaml:1-4](file://apps/applications/hello-api/config.yaml#L1-L4)

How it integrates:
- ApplicationSet generators match apps/**/config.yaml and pass fields into templates
  - [projects/infra.yaml:38-39](file://projects/infra.yaml#L38-L39)
  - [projects/applications.yaml:38-39](file://projects/applications.yaml#L38-L39)
- Template uses destNamespace to set destination.namespace
  - [projects/infra.yaml:51-53](file://projects/infra.yaml#L51-L53)
  - [projects/applications.yaml:51-53](file://projects/applications.yaml#L51-L53)

**Section sources**
- [README.md:136-143](file://README.md#L136-L143)
- [projects/infra.yaml:38-58](file://projects/infra.yaml#L38-L58)
- [projects/applications.yaml:38-58](file://projects/applications.yaml#L38-L58)
- [apps/infra/cloudflared/config.yaml:1-4](file://apps/infra/cloudflared/config.yaml#L1-L4)
- [apps/infra/gateway-api/config.yaml:1-6](file://apps/infra/gateway-api/config.yaml#L1-L6)
- [apps/applications/hello-api/config.yaml:1-4](file://apps/applications/hello-api/config.yaml#L1-L4)

### kustomization.yaml: Namespace and Resource Composition
Purpose:
- Sets the namespace for the app (used by ArgoCD destination if not overridden)
- Includes chart/ directory for Helm rendering
- Can include raw resources or overlays

Examples:
- Infrastructure app with namespace and chart inclusion
  - [apps/infra/cloudflared/kustomization.yaml:1-8](file://apps/infra/cloudflared/kustomization.yaml#L1-L8)
- Infrastructure app with integrated cert-manager and rancher
  - [apps/infra/rancher/kustomization.yaml:1-9](file://apps/infra/rancher/kustomization.yaml#L1-L9)
- User-facing application with namespace and chart inclusion
  - [apps/applications/hello-api/kustomization.yaml:1-8](file://apps/applications/hello-api/kustomization.yaml#L1-L8)

Helm integration:
- Helm charts are declared via helmCharts in chart/kustomization.yaml
  - [apps/infra/rancher/chart/kustomization.yaml:1-20](file://apps/infra/rancher/chart/kustomization.yaml#L1-L20)
  - [apps/applications/hello-api/chart/kustomization.yaml:1-14](file://apps/applications/hello-api/chart/kustomization.yaml#L1-L14)

**Section sources**
- [apps/infra/cloudflared/kustomization.yaml:1-8](file://apps/infra/cloudflared/kustomization.yaml#L1-L8)
- [apps/infra/rancher/kustomization.yaml:1-9](file://apps/infra/rancher/kustomization.yaml#L1-L9)
- [apps/applications/hello-api/kustomization.yaml:1-8](file://apps/applications/hello-api/kustomization.yaml#L1-L8)
- [apps/infra/rancher/chart/kustomization.yaml:1-20](file://apps/infra/rancher/chart/kustomization.yaml#L1-L20)
- [apps/applications/hello-api/chart/kustomization.yaml:1-14](file://apps/applications/hello-api/chart/kustomization.yaml#L1-L14)

### chart/ Directory Pattern: Helm-Based Deployments
Pattern:
- chart/kustomization.yaml declares helmCharts with repo, releaseName, version, and valuesFile
- chart/values.yaml supplies chart-specific values (e.g., images, args, envFrom)

Example:
- Integrated cert-manager and rancher deployment with shared cert-manager namespace
  - [apps/infra/rancher/chart/kustomization.yaml:1-20](file://apps/infra/rancher/chart/kustomization.yaml#L1-L20)
  - [apps/infra/rancher/chart/values-cert-manager.yaml:1-6](file://apps/infra/rancher/chart/values-cert-manager.yaml#L1-L6)
- User-facing hello-api application with service and HTTPRoute values
  - [apps/applications/hello-api/chart/kustomization.yaml:1-14](file://apps/applications/hello-api/chart/kustomization.yaml#L1-L14)

Rendering:
- ApplicationSet enables Helm via Kustomize buildOptions
  - [projects/infra.yaml:59-60](file://projects/infra.yaml#L59-L60)
  - [projects/applications.yaml:59-60](file://projects/applications.yaml#L59-L60)

**Section sources**
- [apps/infra/rancher/chart/kustomization.yaml:1-20](file://apps/infra/rancher/chart/kustomization.yaml#L1-L20)
- [apps/infra/rancher/chart/values-cert-manager.yaml:1-6](file://apps/infra/rancher/chart/values-cert-manager.yaml#L1-L6)
- [apps/applications/hello-api/chart/kustomization.yaml:1-14](file://apps/applications/hello-api/chart/kustomization.yaml#L1-L14)
- [projects/infra.yaml:59-60](file://projects/infra.yaml#L59-L60)
- [projects/applications.yaml:59-60](file://projects/applications.yaml#L59-L60)

### Application Organization: Infrastructure vs Applications
The repository now organizes applications into two distinct categories:

**Infrastructure Applications (apps/infra/):**
Platform components that require shared namespaces and earlier synchronization:
- Gateway API with CRDs and HTTPRoute support
  - [apps/infra/gateway-api/config.yaml:1-6](file://apps/infra/gateway-api/config.yaml#L1-L6)
- Cloudflared tunnel ingress controller
  - [apps/infra/cloudflared/config.yaml:1-4](file://apps/infra/cloudflared/config.yaml#L1-L4)
- Datadog monitoring agent
  - [apps/infra/datadog/config.yaml:1-6](file://apps/infra/datadog/config.yaml#L1-L6)
- ArgoCD ingress controller
  - [apps/infra/argocd-ingress/config.yaml:1-4](file://apps/infra/argocd-ingress/config.yaml#L1-L4)
- Consolidated Rancher with integrated cert-manager
  - [apps/infra/rancher/config.yaml:1-5](file://apps/infra/rancher/config.yaml#L1-L5)

**User-Facing Applications (apps/applications/):**
Experimental or demonstration applications like hello-api:
- Hello API demonstration service
  - [apps/applications/hello-api/config.yaml:1-4](file://apps/applications/hello-api/config.yaml#L1-L4)

ApplicationSet generators:
- Infra scans apps/infra/**/config.yaml
  - [projects/infra.yaml:38-39](file://projects/infra.yaml#L38-L39)
- Applications scans apps/applications/**/config.yaml
  - [projects/applications.yaml:38-39](file://projects/applications.yaml#L38-L39)

**Section sources**
- [README.md:148-159](file://README.md#L148-L159)
- [projects/infra.yaml:38-39](file://projects/infra.yaml#L38-L39)
- [projects/applications.yaml:38-39](file://projects/applications.yaml#L38-L39)
- [apps/infra/gateway-api/config.yaml:1-6](file://apps/infra/gateway-api/config.yaml#L1-L6)
- [apps/infra/rancher/config.yaml:1-5](file://apps/infra/rancher/config.yaml#L1-L5)
- [apps/applications/hello-api/config.yaml:1-4](file://apps/applications/hello-api/config.yaml#L1-L4)

### Minimal Application Setup Examples
- Minimal infrastructure app:
  - Folder: apps/infra/<app>/
  - Files: config.yaml, kustomization.yaml, optional chart/
  - Reference: [apps/infra/cloudflared/config.yaml:1-4](file://apps/infra/cloudflared/config.yaml#L1-L4), [apps/infra/cloudflared/kustomization.yaml:1-8](file://apps/infra/cloudflared/kustomization.yaml#L1-L8)
- Minimal user-facing application:
  - Folder: apps/applications/<app>/
  - Files: config.yaml, kustomization.yaml, optional chart/
  - Reference: [apps/applications/hello-api/config.yaml:1-4](file://apps/applications/hello-api/config.yaml#L1-L4), [apps/applications/hello-api/kustomization.yaml:1-8](file://apps/applications/hello-api/kustomization.yaml#L1-L8)

What each file does:
- config.yaml: Declares destNamespace and optional annotations (e.g., sync-wave)
- kustomization.yaml: Sets namespace and includes chart/ or raw resources
- chart/kustomization.yaml: Declares helmCharts and valuesFile
- chart/values.yaml: Supplies chart values

**Section sources**
- [README.md:128-134](file://README.md#L128-L134)
- [apps/infra/cloudflared/config.yaml:1-4](file://apps/infra/cloudflared/config.yaml#L1-L4)
- [apps/infra/cloudflared/kustomization.yaml:1-8](file://apps/infra/cloudflared/kustomization.yaml#L1-L8)
- [apps/infra/rancher/chart/kustomization.yaml:1-20](file://apps/infra/rancher/chart/kustomization.yaml#L1-L20)
- [apps/applications/hello-api/config.yaml:1-4](file://apps/applications/hello-api/config.yaml#L1-L4)
- [apps/applications/hello-api/kustomization.yaml:1-8](file://apps/applications/hello-api/kustomization.yaml#L1-L8)
- [apps/applications/hello-api/chart/kustomization.yaml:1-14](file://apps/applications/hello-api/chart/kustomization.yaml#L1-L14)

### Namespace Isolation and Base Configuration Inheritance
- Shared namespaces are provisioned early (sync-wave -1) via cluster-resources/default/namespace.yaml
  - [cluster-resources/default/namespace.yaml:1-52](file://cluster-resources/default/namespace.yaml#L1-L52)
- ApplicationSet cluster-resources ApplicationSet deploys these namespaces
  - [bootstrap/cluster-resources.yaml:1-33](file://bootstrap/cluster-resources.yaml#L1-L33)
- Applications inherit base configuration through:
  - Root Kustomize injecting repo URLs into bootstrap/root.yaml and projects/*
    - [kustomization.yaml:10-21](file://kustomization.yaml#L10-L21)
    - [bootstrap/kustomization.yaml:12-38](file://bootstrap/kustomization.yaml#L12-L38)
    - [projects/kustomization.yaml:11-22](file://projects/kustomization.yaml#L11-L22)
  - components/repo-url providing centralized repo-config
    - [components/repo-url/kustomization.yaml:1-11](file://components/repo-url/kustomization.yaml#L1-L11)

**Section sources**
- [README.md:76-86](file://README.md#L76-L86)
- [README.md:144-147](file://README.md#L144-L147)
- [bootstrap/cluster-resources.yaml:1-33](file://bootstrap/cluster-resources.yaml#L1-L33)
- [cluster-resources/default/namespace.yaml:1-52](file://cluster-resources/default/namespace.yaml#L1-L52)
- [kustomization.yaml:10-21](file://kustomization.yaml#L10-L21)
- [bootstrap/kustomization.yaml:12-38](file://bootstrap/kustomization.yaml#L12-L38)
- [projects/kustomization.yaml:11-22](file://projects/kustomization.yaml#L11-L22)
- [components/repo-url/kustomization.yaml:1-11](file://components/repo-url/kustomization.yaml#L1-L11)

## Dependency Analysis
Relationships between key files and their roles in the GitOps chain with the new directory structure:

```mermaid
graph LR
RepoURL["components/repo-url/kustomization.yaml"] --> RootKs["kustomization.yaml"]
RootKs --> BootstrapApp["bootstrap.yaml"]
BootstrapApp --> RootApp["bootstrap/root.yaml"]
RootApp --> ProjInfra["projects/infra.yaml"]
RootApp --> ProjApps["projects/applications.yaml"]
ProjInfra --> InfraApps["apps/infra/**/config.yaml"]
ProjApps --> AppApps["apps/applications/**/config.yaml"]
InfraApps --> InfraKs["apps/infra/**/kustomization.yaml"]
AppApps --> AppKs["apps/applications/**/kustomization.yaml"]
InfraKs --> ChartInfra["apps/infra/**/chart/*"]
AppKs --> ChartApps["apps/applications/**/chart/*"]
NS["cluster-resources/default/namespace.yaml"] --> Waves["Sync waves -2..3"]
Rancher["apps/infra/rancher/chart/kustomization.yaml"] --> CertManager["Integrated cert-manager + rancher"]
HelloAPI["apps/applications/hello-api/chart/kustomization.yaml"] --> DemoApp["User-facing demo application"]
```

**Diagram sources**
- [components/repo-url/kustomization.yaml:1-11](file://components/repo-url/kustomization.yaml#L1-L11)
- [kustomization.yaml:1-21](file://kustomization.yaml#L1-L21)
- [bootstrap.yaml:1-26](file://bootstrap.yaml#L1-L26)
- [bootstrap/root.yaml:1-37](file://bootstrap/root.yaml#L1-L37)
- [projects/infra.yaml:1-85](file://projects/infra.yaml#L1-L85)
- [projects/applications.yaml:1-85](file://projects/applications.yaml#L1-L85)
- [apps/infra/cloudflared/config.yaml:1-4](file://apps/infra/cloudflared/config.yaml#L1-L4)
- [apps/infra/rancher/chart/kustomization.yaml:1-20](file://apps/infra/rancher/chart/kustomization.yaml#L1-L20)
- [apps/applications/hello-api/chart/kustomization.yaml:1-14](file://apps/applications/hello-api/chart/kustomization.yaml#L1-L14)
- [cluster-resources/default/namespace.yaml:1-52](file://cluster-resources/default/namespace.yaml#L1-L52)

**Section sources**
- [README.md:57-86](file://README.md#L57-L86)
- [projects/infra.yaml:33-60](file://projects/infra.yaml#L33-L60)
- [projects/applications.yaml:34-60](file://projects/applications.yaml#L34-L60)

## Performance Considerations
- Use sync-wave to avoid race conditions during creation of dependent resources (e.g., namespaces before apps, Gateway before HTTPRoutes)
- Infrastructure components benefit from earlier synchronization (-2 to 3) while user-facing applications sync later (3)
- Prefer OCI Helm charts for reproducibility and faster rendering
- Keep chart/values minimal and centralized via components/repo-url to reduce duplication
- The consolidated rancher application with integrated cert-manager reduces namespace complexity and improves deployment reliability

## Troubleshooting Guide
Common issues and resolutions:
- Missing namespaces: Ensure cluster-resources ApplicationSet runs with sync-wave 0 and namespaces with wave -1
  - [bootstrap/cluster-resources.yaml:1-33](file://bootstrap/cluster-resources.yaml#L1-L33)
  - [cluster-resources/default/namespace.yaml:1-52](file://cluster-resources/default/namespace.yaml#L1-L52)
- Wrong destination namespace: Verify destNamespace in config.yaml and ApplicationSet template
  - [projects/infra.yaml:51-53](file://projects/infra.yaml#L51-L53)
  - [projects/applications.yaml:51-53](file://projects/applications.yaml#L51-L53)
- Helm rendering errors: Confirm helmCharts presence and valuesFile path in chart/kustomization.yaml
  - [apps/infra/rancher/chart/kustomization.yaml:1-20](file://apps/infra/rancher/chart/kustomization.yaml#L1-L20)
  - [apps/applications/hello-api/chart/kustomization.yaml:1-14](file://apps/applications/hello-api/chart/kustomization.yaml#L1-L14)
- Repo URL placeholders not replaced: Check replacements in root and project kustomizations
  - [kustomization.yaml:10-21](file://kustomization.yaml#L10-L21)
  - [bootstrap/kustomization.yaml:12-38](file://bootstrap/kustomization.yaml#L12-L38)
  - [projects/kustomization.yaml:11-22](file://projects/kustomization.yaml#L11-L22)
- ApplicationSet generator path issues: Verify paths in projects/infra.yaml and projects/applications.yaml
  - [projects/infra.yaml:38-39](file://projects/infra.yaml#L38-L39)
  - [projects/applications.yaml:38-39](file://projects/applications.yaml#L38-L39)

**Section sources**
- [README.md:76-86](file://README.md#L76-L86)
- [bootstrap/cluster-resources.yaml:1-33](file://bootstrap/cluster-resources.yaml#L1-L33)
- [cluster-resources/default/namespace.yaml:1-52](file://cluster-resources/default/namespace.yaml#L1-L52)
- [projects/infra.yaml:51-53](file://projects/infra.yaml#L51-L53)
- [projects/applications.yaml:51-53](file://projects/applications.yaml#L51-L53)
- [apps/infra/rancher/chart/kustomization.yaml:1-20](file://apps/infra/rancher/chart/kustomization.yaml#L1-L20)
- [apps/applications/hello-api/chart/kustomization.yaml:1-14](file://apps/applications/hello-api/chart/kustomization.yaml#L1-L14)
- [kustomization.yaml:10-21](file://kustomization.yaml#L10-L21)
- [bootstrap/kustomization.yaml:12-38](file://bootstrap/kustomization.yaml#L12-L38)
- [projects/kustomization.yaml:11-22](file://projects/kustomization.yaml#L11-L22)

## Conclusion
This GitOps structure enforces predictable application organization and deployment with clear separation between infrastructure and user-facing applications:
- config.yaml drives discovery and per-app configuration for both infrastructure and applications
- kustomization.yaml controls namespace and resource composition
- chart/ standardizes Helm-based deployments with integrated services like cert-manager
- ApplicationSet generators and sync-wave annotations enforce safe ordering with infrastructure components syncing first (-2 to 3) and applications later (3)
- Shared namespaces and centralized repo configuration ensure consistency and isolation
- The consolidated rancher application demonstrates best practices for integrating multiple services in a single deployment while maintaining proper namespace isolation