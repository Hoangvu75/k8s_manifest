# Demo Applications

<cite>
**Referenced Files in This Document**
- [values.yaml](file://apps/playground/hello-api/chart/values.yaml)
- [values-service.yaml](file://apps/playground/hello-api/chart/values-service.yaml)
- [values-httproute.yaml](file://apps/playground/hello-api/chart/values-httproute.yaml)
- [kustomization.yaml](file://apps/playground/hello-api/kustomization.yaml)
- [config.yaml](file://apps/playground/hello-api/config.yaml)
- [playground.yaml](file://projects/playground.yaml)
- [namespace.yaml](file://cluster-resources/default/namespace.yaml)
- [gateway.yaml](file://apps/infra/gateway-api/chart/gateway.yaml)
- [httproute-argocd.yaml](file://apps/playground/argocd-ingress/chart/httproute-argocd.yaml)
- [httproute-rancher.yaml](file://apps/playground/rancher/chart/httproute-rancher.yaml)
- [root.yaml](file://bootstrap/root.yaml)
- [argo_cd.md](file://guide/argocd/argo_cd.md)
- [kustomization.yaml](file://components/httproute-defaults/kustomization.yaml)
</cite>

## Update Summary
**Changes Made**
- Added documentation for the new HTTPRoute defaults component system
- Updated multi-value configuration approach to include component-based standardization
- Enhanced HTTPRoute setup section to explain centralized defaults management
- Added new section covering component-based routing standardization
- Updated dependency analysis to include component relationships

## Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Architecture Overview](#architecture-overview)
5. [Detailed Component Analysis](#detailed-component-analysis)
6. [Component-Based HTTPRoute Standardization](#component-based-httproute-standardization)
7. [Dependency Analysis](#dependency-analysis)
8. [Performance Considerations](#performance-considerations)
9. [Troubleshooting Guide](#troubleshooting-guide)
10. [Conclusion](#conclusion)
11. [Appendices](#appendices)

## Introduction
This document explains the demo applications deployed in the playground environment, focusing on the hello-api application. It covers configuration across multiple Helm values files (service, ingress via HTTPRoute, and deployment), ArgoCD-driven GitOps synchronization, namespace isolation, and practical update/rollback guidance. The document now includes the new HTTPRoute defaults component system that provides centralized routing behavior standardization across all demo applications.

## Project Structure
The playground is managed as an ArgoCD ApplicationSet that discovers and deploys demo applications from the repository. Each demo app defines its own Kustomization and Helm values, enabling modular configuration and safe separation of concerns. The new HTTPRoute defaults component provides centralized standardization for routing behavior across all demo applications.

```mermaid
graph TB
subgraph "ArgoCD Control Plane"
Root["Application 'root'"]
Proj["AppProject 'playground'"]
AS["ApplicationSet 'playground'"]
end
subgraph "Cluster Resources"
NS["Namespace 'hello-api'"]
GW["Gateway 'shared-gateway'"]
end
subgraph "Demo App: hello-api"
Kust["Kustomization<br/>namespace: hello-api<br/>+ HTTPRoute Defaults Component"]
Chart["Helm Chart Values<br/>deployment/service/httproute"]
end
Root --> Proj
Proj --> AS
AS --> Kust
Kust --> Chart
Chart --> NS
Chart --> GW
```

**Diagram sources**
- [root.yaml:10-19](file://bootstrap/root.yaml#L10-L19)
- [playground.yaml:23-45](file://projects/playground.yaml#L23-L45)
- [kustomization.yaml:4](file://apps/playground/hello-api/kustomization.yaml#L4)
- [gateway.yaml:1-27](file://apps/infra/gateway-api/chart/gateway.yaml#L1-L27)
- [kustomization.yaml:6-7](file://apps/playground/hello-api/kustomization.yaml#L6-L7)

**Section sources**
- [playground.yaml:1-90](file://projects/playground.yaml#L1-L90)
- [root.yaml:1-37](file://bootstrap/root.yaml#L1-L37)
- [kustomization.yaml:1-11](file://apps/playground/hello-api/kustomization.yaml#L1-L11)

## Core Components
- Application discovery and deployment: Managed by an ApplicationSet that scans the apps/playground/**/config.yaml files and generates per-app Application resources. Namespaces are created automatically during sync.
- hello-api module: Composed of three Helm values overlays—deployment, service, and HTTPRoute—to cleanly separate concerns and enable incremental updates.
- Ingress and routing: HTTPRoute resources attach to a shared Gateway, enabling path-based routing and header manipulation. Now standardized through the HTTPRoute defaults component.
- Namespace isolation: Each demo app runs in its own namespace, isolated from others for safety and experimentation.
- Component-based standardization: The HTTPRoute defaults component provides centralized routing behavior standardization across all demo applications.

Key configuration anchors:
- Deployment and container image/ports/resources
- Service exposure and port mapping
- HTTPRoute path matching, hostname, and backend routing
- Kustomization namespace binding and ArgoCD annotations
- Component-based HTTPRoute defaults management

**Section sources**
- [playground.yaml:33-59](file://projects/playground.yaml#L33-L59)
- [config.yaml:1-4](file://apps/playground/hello-api/config.yaml#L1-L4)
- [values.yaml:1-23](file://apps/playground/hello-api/chart/values.yaml#L1-L23)
- [values-service.yaml:1-6](file://apps/playground/hello-api/chart/values-service.yaml#L1-L6)
- [values-httproute.yaml:1-26](file://apps/playground/hello-api/chart/values-httproute.yaml#L1-L26)
- [kustomization.yaml:4](file://apps/playground/hello-api/kustomization.yaml#L4)
- [kustomization.yaml:6-7](file://apps/playground/hello-api/kustomization.yaml#L6-L7)

## Architecture Overview
The hello-api demo demonstrates a typical GitOps flow with component-based standardization:
- Changes are committed to the repository under apps/playground/hello-api.
- ArgoCD's ApplicationSet detects the change via a Git generator and creates/updates an Application.
- The Application applies Kustomization (including HTTPRoute defaults component) and Helm values to the target namespace.
- The HTTPRoute defaults component automatically standardizes routing behavior across all demo applications.
- A Gateway routes traffic to the HTTPRoute, which forwards to the Service and Pod.

```mermaid
sequenceDiagram
participant Dev as "Developer"
participant Repo as "Git Repository"
participant ArgoCD as "ArgoCD"
participant K8s as "Kubernetes API"
Dev->>Repo : Commit changes to apps/playground/hello-api
Repo-->>ArgoCD : Webhook/git poll
ArgoCD->>ArgoCD : ApplicationSet detects config.yaml
ArgoCD->>ArgoCD : Create/Update Application
ArgoCD->>K8s : Apply Kustomization + HTTPRoute Defaults Component + Helm values
K8s-->>ArgoCD : Status : Synced
Dev->>K8s : Access via Gateway -> HTTPRoute -> Service -> Pod
```

**Diagram sources**
- [playground.yaml:33-59](file://projects/playground.yaml#L33-L59)
- [config.yaml:1-4](file://apps/playground/hello-api/config.yaml#L1-L4)
- [kustomization.yaml:1-11](file://apps/playground/hello-api/kustomization.yaml#L1-L11)
- [gateway.yaml:1-27](file://apps/infra/gateway-api/chart/gateway.yaml#L1-L27)

## Detailed Component Analysis

### Multi-Value Configuration Approach
The hello-api module splits concerns across three values files:
- Deployment and container configuration: image, replicas, ports, args, and resource requests/limits.
- Service configuration: enabling the Service and mapping container ports to service ports.
- HTTPRoute configuration: enabling the route, attaching to a shared Gateway, setting hostnames, path matching, optional header filters, and backend references.

Benefits:
- Separation of concerns enables safer rollouts (e.g., update HTTPRoute without touching Deployment).
- Reusability across environments via Kustomization overlays.
- Predictable sync waves to control ordering.
- Component-based standardization through HTTPRoute defaults component.

```mermaid
flowchart TD
Start(["Values Load"]) --> LoadDeployment["Load values.yaml"]
Start --> LoadService["Load values-service.yaml"]
Start --> LoadHTTPRoute["Load values-httproute.yaml"]
LoadDeployment --> Merge["Merge Helm Values"]
LoadService --> Merge
LoadHTTPRoute --> Merge
Merge --> ApplyDefaults["Apply HTTPRoute Defaults Component"]
ApplyDefaults --> Render["Render Helm Templates"]
Render --> Apply["Apply to Namespace"]
Apply --> End(["Ready"])
```

**Diagram sources**
- [values.yaml:1-23](file://apps/playground/hello-api/chart/values.yaml#L1-L23)
- [values-service.yaml:1-6](file://apps/playground/hello-api/chart/values-service.yaml#L1-L6)
- [values-httproute.yaml:1-26](file://apps/playground/hello-api/chart/values-httproute.yaml#L1-L26)
- [kustomization.yaml:6-7](file://apps/playground/hello-api/kustomization.yaml#L6-L7)

**Section sources**
- [values.yaml:1-23](file://apps/playground/hello-api/chart/values.yaml#L1-L23)
- [values-service.yaml:1-6](file://apps/playground/hello-api/chart/values-service.yaml#L1-L6)
- [values-httproute.yaml:1-26](file://apps/playground/hello-api/chart/values-httproute.yaml#L1-L26)

### Service Definition
- Service is enabled and exposes the container port via targetPort to service port mapping.
- This decouples internal container ports from external exposure, simplifying changes.

Operational notes:
- Ensure the Service name matches the backendRef referenced by the HTTPRoute.
- Keep port numbers consistent across values-service.yaml and values-httproute.yaml.

**Section sources**
- [values-service.yaml:1-6](file://apps/playground/hello-api/chart/values-service.yaml#L1-L6)

### Ingress Routing via HTTPRoute
- HTTPRoute is enabled and attached to a shared Gateway via parentRefs.
- Hostname and path prefix define routing scope.
- Optional filters set forwarded headers for upstream compatibility.
- BackendRef targets the Service name and port.

**Updated** The HTTPRoute now benefits from automatic standardization through the HTTPRoute defaults component, which ensures consistent routing behavior across all demo applications.

Operational notes:
- The shared Gateway must exist in the gateway-api namespace.
- PathPrefix matching allows clean separation of routes across demo apps.
- The HTTPRoute defaults component automatically manages parentRef standardization and annotations.

**Section sources**
- [values-httproute.yaml:1-26](file://apps/playground/hello-api/chart/values-httproute.yaml#L1-L26)
- [gateway.yaml:1-27](file://apps/infra/gateway-api/chart/gateway.yaml#L1-L27)
- [kustomization.yaml:6-7](file://apps/playground/hello-api/kustomization.yaml#L6-L7)

### HTTPRoute Setup Example
- Parent reference to shared Gateway in the gateway-api namespace.
- Hostname configured for the route.
- Path match for a specific prefix.
- Header filters to simulate secure proxy headers.
- BackendRef pointing to the Service and port.

**Updated** The HTTPRoute setup now leverages the HTTPRoute defaults component for standardized behavior, reducing duplication and ensuring consistency across all demo applications.

**Section sources**
- [values-httproute.yaml:5-25](file://apps/playground/hello-api/chart/values-httproute.yaml#L5-L25)

### Kustomization and Namespace Binding
- Kustomization sets the target namespace to hello-api.
- ArgoCD annotations propagate through ApplicationSet templates to control sync ordering.
- **New**: Kustomization includes the HTTPRoute defaults component for centralized standardization.

Operational notes:
- Namespace creation is handled by ArgoCD sync options.
- Keep the namespace consistent across Kustomization and HTTPRoute backendRefs.
- The HTTPRoute defaults component is automatically applied to all HTTPRoute resources.

**Section sources**
- [kustomization.yaml:4](file://apps/playground/hello-api/kustomization.yaml#L4)
- [kustomization.yaml:6-7](file://apps/playground/hello-api/kustomization.yaml#L6-L7)
- [config.yaml:1-4](file://apps/playground/hello-api/config.yaml#L1-L4)

### Relationship to Playground Namespace Isolation
- Cluster-level namespaces for infrastructure are pre-provisioned with early sync waves.
- Demo app namespaces are created during Application sync with CreateNamespace enabled.
- This ensures isolation and predictable resource ownership.

**Section sources**
- [namespace.yaml:1-52](file://cluster-resources/default/namespace.yaml#L1-L52)
- [playground.yaml:72-74](file://projects/playground.yaml#L72-L74)

### ArgoCD Synchronization and GitOps Workflow
- ApplicationSet scans for config.yaml files under apps/playground/**/config.yaml.
- Templates derive Application names, destinations, and Kustomize paths.
- Sync policy automates pruning, self-healing, and retries.
- Sync waves coordinate order across cluster resources, gateways, and demo apps.

Practical implications:
- Use annotations to influence sync wave ordering.
- Leverage automated retry/backoff to handle transient failures.
- Self-healing keeps drift in check.
- Component-based standardization reduces configuration complexity.

**Section sources**
- [playground.yaml:33-74](file://projects/playground.yaml#L33-L74)
- [config.yaml:2-3](file://apps/playground/hello-api/config.yaml#L2-L3)

### Learning Tooling and Testing Scenarios
- Demonstrates GitOps end-to-end: commit → ArgoCD → Kubernetes.
- Exercises path-based routing, header forwarding, and backend binding.
- Provides a safe sandbox for experimenting with updates, rollbacks, and troubleshooting.
- **New**: Illustrates component-based configuration management and standardization practices.

## Component-Based HTTPRoute Standardization

### HTTPRoute Defaults Component System
The new HTTPRoute defaults component provides centralized standardization for routing behavior across all demo applications. This component ensures consistent HTTPRoute configuration patterns and reduces duplication across individual applications.

**Component Capabilities:**
- Automatic parentRef standardization to shared-gateway in gateway-api namespace
- Consistent annotation management for tooling visibility
- Strategic merge patching that enhances existing configurations
- Non-intrusive application that preserves custom settings

**Configuration Behavior:**
- Ensures parentRefs[0] always references shared-gateway in gateway-api namespace
- Adds the routing.hoangvu75.space/managed annotation for tooling visibility
- Uses strategic merge patching to enhance existing HTTPRoute configurations
- Preserves custom settings while applying standard defaults

**Integration Benefits:**
- Reduces configuration duplication across demo applications
- Ensures consistent routing behavior standards
- Simplifies maintenance and updates
- Provides centralized control for routing policies

```mermaid
flowchart TD
Component["HTTPRoute Defaults Component"] --> Patch["Strategic Merge Patch"]
Patch --> ParentRef["Standardize parentRefs[0]"]
Patch --> Annotation["Add managed annotations"]
ParentRef --> Apply["Apply to HTTPRoute Resources"]
Annotation --> Apply
Apply --> Result["Consistent Routing Behavior"]
```

**Diagram sources**
- [kustomization.yaml:15-32](file://components/httproute-defaults/kustomization.yaml#L15-L32)

**Section sources**
- [kustomization.yaml:1-32](file://components/httproute-defaults/kustomization.yaml#L1-L32)
- [kustomization.yaml:6-7](file://apps/playground/hello-api/kustomization.yaml#L6-L7)

### Component Integration Patterns
All demo applications now integrate the HTTPRoute defaults component through their Kustomization files. This creates a consistent pattern for managing routing behavior across the playground environment.

**Integration Examples:**
- hello-api: Includes component in kustomization.yaml
- argocd-ingress: Includes component in kustomization.yaml  
- rancher: Includes component in kustomization.yaml

**Section sources**
- [kustomization.yaml:6-7](file://apps/playground/hello-api/kustomization.yaml#L6-L7)
- [kustomization.yaml:7](file://apps/playground/argocd-ingress/kustomization.yaml#L7)
- [kustomization.yaml:7](file://apps/playground/rancher/kustomization.yaml#L7)

## Dependency Analysis
The hello-api demo depends on:
- Shared Gateway availability in the gateway-api namespace.
- Namespace existence and proper RBAC for the ApplicationSet to create namespaces and apply resources.
- Consistent naming between Service and HTTPRoute backendRefs.
- **New**: HTTPRoute defaults component for centralized standardization.

```mermaid
graph LR
GW["Gateway 'shared-gateway'"] --> HR["HTTPRoute 'hello-api'"]
HR --> SVC["Service 'hello-api'"]
SVC --> POD["Pods (from Deployment)"]
NS["Namespace 'hello-api'"] --> POD
NS --> SVC
NS --> HR
COMP["HTTPRoute Defaults Component"] --> HR
```

**Diagram sources**
- [gateway.yaml:1-27](file://apps/infra/gateway-api/chart/gateway.yaml#L1-L27)
- [values-httproute.yaml:24-25](file://apps/playground/hello-api/chart/values-httproute.yaml#L24-L25)
- [values-service.yaml:5-6](file://apps/playground/hello-api/chart/values-service.yaml#L5-L6)
- [kustomization.yaml:4](file://apps/playground/hello-api/kustomization.yaml#L4)
- [kustomization.yaml:6-7](file://apps/playground/hello-api/kustomization.yaml#L6-L7)

**Section sources**
- [gateway.yaml:1-27](file://apps/infra/gateway-api/chart/gateway.yaml#L1-L27)
- [values-httproute.yaml:24-25](file://apps/playground/hello-api/chart/values-httproute.yaml#L24-L25)
- [values-service.yaml:5-6](file://apps/playground/hello-api/chart/values-service.yaml#L5-L6)
- [kustomization.yaml:4](file://apps/playground/hello-api/kustomization.yaml#L4)
- [kustomization.yaml:6-7](file://apps/playground/hello-api/kustomization.yaml#L6-L7)

## Performance Considerations
- Resource requests and limits: The deployment defines small CPU and memory limits/requests suitable for playground usage. Increase cautiously for load testing while keeping the cluster balanced.
- Replicas: Single replica is appropriate for demos; scale up only when validating horizontal scaling behavior.
- Image choice: Lightweight static HTTP server image minimizes overhead.
- Network path: HTTPRoute and Gateway introduce minimal overhead; ensure listener protocols and TLS termination align with your testing needs.
- **New**: Component-based configuration reduces processing overhead through centralized standardization.

## Troubleshooting Guide
Common issues and resolutions:
- Route not reachable
  - Verify HTTPRoute exists in the hello-api namespace and attaches to the shared Gateway.
  - Confirm hostname and path prefix match client expectations.
  - Ensure the Service name and port match the HTTPRoute backendRef.
  - **New**: Check that the HTTPRoute defaults component is properly applied and not conflicting with custom settings.
- No traffic after sync
  - Check ArgoCD Application status and logs for sync errors.
  - Validate that the namespace exists and the ApplicationSet generated the Application.
  - **New**: Verify component integration in Kustomization and component application success.
- Rollback procedure
  - Adjust the Helm values to revert to a previous image/tag or configuration.
  - Trigger a manual sync or wait for auto-sync; ArgoCD self-healing will reconcile differences.
  - **New**: Remove or modify component references if component-related issues are suspected.
- Health checks
  - Use curl or browser to test the configured hostname and path.
  - Inspect pod logs and readiness/liveness probes if defined externally.
  - **New**: Monitor component application logs for patch conflicts or merge failures.

**Section sources**
- [values-httproute.yaml:1-26](file://apps/playground/hello-api/chart/values-httproute.yaml#L1-L26)
- [values-service.yaml:1-6](file://apps/playground/hello-api/chart/values-service.yaml#L1-L6)
- [playground.yaml:61-74](file://projects/playground.yaml#L61-L74)
- [kustomization.yaml:6-7](file://apps/playground/hello-api/kustomization.yaml#L6-L7)

## Conclusion
The hello-api demo illustrates a clean, modular approach to deploying and exposing applications in the playground using ArgoCD and Gateway API. The integration of the HTTPRoute defaults component provides centralized standardization that enhances consistency and reduces configuration complexity across all demo applications. By separating concerns across Helm values, leveraging namespace isolation, controlling sync order with waves, and utilizing component-based standardization, it serves as an excellent learning tool for GitOps workflows, routing, and safe experimentation.

## Appendices

### Appendix A: Typical Update and Rollback Workflow
- Update: Modify values in values.yaml or values-httproute.yaml, commit, and push.
- Sync: ArgoCD detects changes and reconciles the Application.
- Verification: Test the route and confirm pod rollout.
- Rollback: Revert to a known-good commit; ArgoCD self-heals to the previous state.
- **New**: Component updates: Modify the HTTPRoute defaults component to change centralized routing behavior.

**Section sources**
- [playground.yaml:61-74](file://projects/playground.yaml#L61-L74)

### Appendix B: Related Ingress Examples in the Playground
- ArgoCD UI exposed via HTTPRoute attached to the shared Gateway.
- Rancher UI similarly routed through HTTPRoute to the Rancher Service.
- **New**: All HTTPRoute resources benefit from the HTTPRoute defaults component for standardized behavior.

These demonstrate consistent patterns for multiple demo apps with centralized standardization.

**Section sources**
- [httproute-argocd.yaml:1-29](file://apps/playground/argocd-ingress/chart/httproute-argocd.yaml#L1-L29)
- [httproute-rancher.yaml:1-30](file://apps/playground/rancher/chart/httproute-rancher.yaml#L1-L30)
- [kustomization.yaml:6-7](file://apps/playground/argocd-ingress/kustomization.yaml#L6-L7)
- [kustomization.yaml:6-7](file://apps/playground/rancher/kustomization.yaml#L6-L7)

### Appendix C: Getting Started with ArgoCD
- Install ArgoCD, expose the UI, apply repository secrets, and bootstrap the root Application.

**Section sources**
- [argo_cd.md:1-34](file://guide/argocd/argo_cd.md#L1-L34)

### Appendix D: HTTPRoute Defaults Component Usage
**Component Integration:**
To use the HTTPRoute defaults component in your own applications:
1. Add the component reference to your Kustomization:
   ```yaml
   components:
     - ../../../components/httproute-defaults
   ```
2. Ensure your HTTPRoute resources are properly structured
3. The component will automatically apply standardization rules

**Component Customization:**
The component can be customized by modifying the kustomization.yaml file in the components/httproute-defaults directory to adjust:
- Default parentRef settings
- Annotation patterns
- Strategic merge patch configurations

**Section sources**
- [kustomization.yaml:1-32](file://components/httproute-defaults/kustomization.yaml#L1-L32)
- [kustomization.yaml:6-7](file://apps/playground/hello-api/kustomization.yaml#L6-L7)