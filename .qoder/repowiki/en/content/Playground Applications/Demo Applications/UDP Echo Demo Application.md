# UDP Echo Demo Application

<cite>
**Referenced Files in This Document**
- [ingressrouteudp.yaml](file://apps/applications/udp-demo/chart/ingressrouteudp.yaml)
- [service.yaml](file://apps/applications/udp-demo/chart/service.yaml)
- [deployment.yaml](file://apps/applications/udp-demo/chart/deployment.yaml)
- [config.yaml](file://apps/applications/udp-demo/config.yaml)
- [kustomization.yaml](file://apps/applications/udp-demo/kustomization.yaml)
- [ingressroutetcp.yaml](file://apps/applications/tcp-demo/chart/ingressroutetcp.yaml)
- [gateway.yaml](file://apps/infra/gateway-api/chart/gateway.yaml)
- [gatewayclass.yaml](file://apps/infra/gateway-api/chart/gatewayclass.yaml)
- [README.md](file://guide/tcp-udp-demo/README.md)
- [README.md](file://README.md)
- [applications.yaml](file://projects/applications.yaml)
- [infra.yaml](file://projects/infra.yaml)
</cite>

## Update Summary
**Changes Made**
- Updated architecture overview to reflect CRD-based routing approach using Traefik's native IngressRouteUDP CRDs
- Enhanced testing procedures with improved troubleshooting guidance
- Clarified that UDP demo uses direct CRD routing instead of Gateway API Gateway
- Updated performance considerations to reflect UDP connectionless nature
- Revised troubleshooting guide with specific UDP testing scenarios

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
This document describes the UDP Echo Demo Application, a demonstration of Traefik's Layer 4 routing capabilities using the Gateway API. The demo deploys a UDP echo service backed by a simple container that listens on a UDP port and echoes received packets back to clients. It is designed to be tested via NodePort and verified through the Traefik dashboard and metrics.

The application follows a GitOps workflow using ArgoCD, Kustomize, and Helm. It leverages Traefik's native CRDs to route UDP traffic directly from the cluster's entry points to the demo service without requiring the Gateway API Gateway resource.

**Updated** The UDP demo now uses Traefik's native IngressRouteUDP CRD directly, following the same architectural pattern as the TCP demo.

## Project Structure
The UDP Echo Demo is organized as a standard ArgoCD application with a Kustomize base that renders Kubernetes manifests. The application is discovered and deployed by ApplicationSets defined in the projects configuration.

```mermaid
graph TB
subgraph "ArgoCD Projects"
APPSET["ApplicationSet 'applications'"]
INFRA_APPSET["ApplicationSet 'infra'"]
end
subgraph "Discovery"
GIT["Git Generator<br/>apps/applications/**/config.yaml"]
end
subgraph "Kustomize Base"
KCONFIG["Kustomization<br/>namespace: udp-demo"]
RESOURCES["Resources<br/>chart/"]
end
subgraph "Manifests"
DEPLOYMENT["Deployment 'udp-echo'<br/>Container: alpine/socat"]
SERVICE["Service 'udp-echo'<br/>ClusterIP, UDP:7778"]
INGRESS["IngressRouteUDP 'udp-echo'<br/>entryPoints: udp → port 7778"]
end
APPSET --> GIT
GIT --> KCONFIG
KCONFIG --> RESOURCES
RESOURCES --> DEPLOYMENT
RESOURCES --> SERVICE
RESOURCES --> INGRESS
```

**Diagram sources**
- [applications.yaml:33-58](file://projects/applications.yaml#L33-L58)
- [kustomization.yaml:1-8](file://apps/applications/udp-demo/kustomization.yaml#L1-L8)
- [deployment.yaml:1-29](file://apps/applications/udp-demo/chart/deployment.yaml#L1-L29)
- [service.yaml:1-15](file://apps/applications/udp-demo/chart/service.yaml#L1-L15)
- [ingressrouteudp.yaml:1-20](file://apps/applications/udp-demo/chart/ingressrouteudp.yaml#L1-L20)

**Section sources**
- [README.md:106-119](file://README.md#L106-L119)
- [applications.yaml:33-58](file://projects/applications.yaml#L33-L58)
- [kustomization.yaml:1-8](file://apps/applications/udp-demo/kustomization.yaml#L1-L8)

## Core Components
The UDP Echo Demo consists of three primary Kubernetes resources:

- Deployment: Runs a container that listens on UDP port 7778 and echoes incoming packets back to clients.
- Service: Exposes the Deployment internally as a ClusterIP service on UDP port 7778.
- IngressRouteUDP: Routes inbound UDP traffic from Traefik's UDP entry point directly to the Service.

These components work together to provide a simple UDP echo service accessible via NodePort 30901.

**Section sources**
- [deployment.yaml:1-29](file://apps/applications/udp-demo/chart/deployment.yaml#L1-L29)
- [service.yaml:1-15](file://apps/applications/udp-demo/chart/service.yaml#L1-L15)
- [ingressrouteudp.yaml:1-20](file://apps/applications/udp-demo/chart/ingressrouteudp.yaml#L1-L20)

## Architecture Overview
The UDP Echo Demo integrates with Traefik's native CRDs to route Layer 4 UDP traffic directly. Clients connect to Traefik via NodePort 30901, which is handled by Traefik's UDP listener. The IngressRouteUDP selects the appropriate backend service, and the Service targets the Deployment pods.

**Updated** Unlike the Gateway API approach, this demo uses Traefik's native IngressRouteUDP CRD to route traffic directly without requiring a Gateway resource.

```mermaid
graph TB
INTERNET["Internet Client"] --> NODEPORT["NodePort 30901 (UDP)"]
NODEPORT --> TRAEFIK["Traefik Controller<br/>EntryPoints: udp:9001"]
TRAEFIK --> INGRESS["IngressRouteUDP 'udp-echo'<br/>routes to Service 'udp-echo'"]
INGRESS --> SVC["Service 'udp-echo'<br/>ClusterIP: UDP:7778"]
SVC --> POD["Pod(s)<br/>Container: socat UDP-LISTEN:7778"]
```

**Diagram sources**
- [ingressrouteudp.yaml:14-20](file://apps/applications/udp-demo/chart/ingressrouteudp.yaml#L14-L20)
- [service.yaml:7-15](file://apps/applications/udp-demo/chart/service.yaml#L7-L15)
- [deployment.yaml:17-22](file://apps/applications/udp-demo/chart/deployment.yaml#L17-L22)

## Detailed Component Analysis

### Deployment: UDP Echo Pod
The Deployment runs a single replica of a container that listens on UDP port 7778 using socat. The container configuration ensures the pod receives and echoes UDP packets. Resource requests and limits are set to constrain CPU and memory usage.

Key characteristics:
- Container image: alpine/socat
- Listen port: 7778 (UDP)
- Arguments: socat UDP-LISTEN with fork and reuseaddr
- Resources: requests and limits defined

**Section sources**
- [deployment.yaml:17-29](file://apps/applications/udp-demo/chart/deployment.yaml#L17-L29)

### Service: ClusterIP Exposure
The Service exposes the Deployment internally as a ClusterIP service. It matches pods labeled with app=udp-echo and forwards traffic to UDP port 7778.

Key characteristics:
- Type: ClusterIP
- Selector: app=udp-echo
- Ports: name=udp-echo, port=7778, targetPort=7778, protocol=UDP

**Section sources**
- [service.yaml:7-15](file://apps/applications/udp-demo/chart/service.yaml#L7-L15)

### IngressRouteUDP: UDP Routing
The IngressRouteUDP binds Traefik's UDP entry point directly to the Service. It specifies the entryPoints and routes traffic to the Service named udp-echo on port 7778.

Key characteristics:
- Kind: IngressRouteUDP
- entryPoints: udp
- routes.services: udp-echo port 7778
- Annotation: sync-wave 3 for ordering

**Section sources**
- [ingressrouteudp.yaml:14-20](file://apps/applications/udp-demo/chart/ingressrouteudp.yaml#L14-L20)

### Comparison with TCP Demo
The TCP demo demonstrates equivalent behavior for TCP traffic using IngressRouteTCP. Both demos share the same Traefik infrastructure and follow the same sync-wave ordering to ensure proper resource creation order.

Key characteristics:
- TCP demo: IngressRouteTCP routes to Service 'tcp-echo' port 7777
- UDP demo: IngressRouteUDP routes to Service 'udp-echo' port 7778
- Both use sync-wave 3 for ordering
- Both use Traefik's native CRDs directly

**Section sources**
- [ingressroutetcp.yaml:14-21](file://apps/applications/tcp-demo/chart/ingressroutetcp.yaml#L14-L21)
- [ingressrouteudp.yaml:14-20](file://apps/applications/udp-demo/chart/ingressrouteudp.yaml#L14-L20)

## Dependency Analysis
The UDP Echo Demo depends on Traefik's native CRDs and ApplicationSet discovery. The following diagram shows the dependency chain from discovery to manifest rendering and resource creation.

```mermaid
graph TB
GEN["Git Generator<br/>apps/applications/**/config.yaml"] --> APPSET["ApplicationSet 'applications'"]
APPSET --> KUSTOMIZE["Kustomize Build<br/>--enable-helm"]
KUSTOMIZE --> MANIFESTS["Rendered Manifests"]
MANIFESTS --> DEPLOYMENT["Deployment 'udp-echo'"]
MANIFESTS --> SERVICE["Service 'udp-echo'"]
MANIFESTS --> INGRESS["IngressRouteUDP 'udp-echo'"]
INGRESS --> TRAEFIK["Traefik Controller"]
```

**Diagram sources**
- [applications.yaml:33-58](file://projects/applications.yaml#L33-L58)
- [kustomization.yaml:4-7](file://apps/applications/udp-demo/kustomization.yaml#L4-L7)
- [ingressrouteudp.yaml:1-20](file://apps/applications/udp-demo/chart/ingressrouteudp.yaml#L1-L20)

**Section sources**
- [applications.yaml:33-58](file://projects/applications.yaml#L33-L58)
- [kustomization.yaml:4-7](file://apps/applications/udp-demo/kustomization.yaml#L4-L7)
- [README.md:76-86](file://README.md#L76-L86)

## Performance Considerations
- UDP is connectionless, which can cause the first packet to be dropped during listener initialization. Sending a few test messages helps mitigate this.
- The Deployment runs a single replica. For production scenarios, consider scaling the Deployment to increase availability and throughput.
- Resource limits are set to constrain memory usage. Monitor pod resource consumption during load testing.
- UDP traffic is processed directly by Traefik's native CRDs without Gateway API overhead, providing efficient Layer 4 routing.

## Troubleshooting Guide
Common verification steps and diagnostics for the UDP Echo Demo:

- Verify Traefik UDP entry point:
  - Confirm Traefik is running and listening on UDP entry point 9001
  - Check that the IngressRouteUDP 'udp-echo' exists in the udp-demo namespace
  - Confirm entryPoints includes 'udp' and routes to the correct Service and port

- Validate IngressRouteUDP:
  - Check that the IngressRouteUDP 'udp-echo' exists in the udp-demo namespace
  - Confirm entryPoints includes 'udp' and routes to the correct Service and port

- Test connectivity:
  - From outside the cluster, use a UDP client to send messages to NodePort 30901
  - From inside the cluster, use a pod to send UDP messages to udp-echo.udp-demo:7778
  - Note: UDP is connectionless, so the first packet may be lost while socat sets up the listener

- Observe Traefik dashboard:
  - Navigate to the Traefik dashboard to confirm the UDP router and backend service appear after sync completes

- Review metrics and logs:
  - Use kubectl logs on the Traefik deployment to inspect access logs for UDP traffic
  - Query Prometheus metrics endpoints for Traefik to verify router and service metrics

**Updated** Enhanced troubleshooting guidance with specific UDP testing scenarios and connectionless nature considerations.

**Section sources**
- [README.md:115-184](file://guide/tcp-udp-demo/README.md#L115-L184)
- [ingressrouteudp.yaml:1-20](file://apps/applications/udp-demo/chart/ingressrouteudp.yaml#L1-L20)

## Conclusion
The UDP Echo Demo Application demonstrates Traefik's Layer 4 routing capabilities using the Gateway API. By leveraging Traefik's native IngressRouteUDP CRD, the demo provides a straightforward UDP echo service accessible via NodePort without requiring a Gateway API Gateway resource. The GitOps workflow ensures predictable deployments through ArgoCD, Kustomize, and Helm, with clear ordering guarantees to maintain reliable routing.