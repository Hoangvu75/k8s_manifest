# TCP / UDP Demo Testing Guide

This guide explains how to test the TCP and UDP demo apps (tcp-demo, udp-demo) created under `apps/applications/`, and how to observe them on the Traefik dashboard.

## Overview

Two echo-server apps have been created to demonstrate Traefik's Layer 4 routing capabilities:

| App | EntryPoint | NodePort | Container | Backend Port |
|-----|-----------|----------|-----------|-------------|
| tcp-demo | `tcp` (:9000) | **30900** | `alpine/socat` TCP echo (socat TCP-LISTEN) | 7777 |
| udp-demo | `udp` (:9001/UDP) | **30901** | `alpine/socat` UDP echo (socat UDP-LISTEN) | 7778 |

Both are routed via the `shared-gateway` Gateway in `gateway-api` namespace. The Gateway's TCP/UDP listeners only accept routes from namespaces labeled `routing.hoangvu75.space/expose: "true"` — both `tcp-demo` and `udp-demo` namespaces have this label.

---

## 1. Testing TCP Echo (NodePort)

The Traefik NodePort service exposes TCP traffic on port **30900**.

### From a machine on the same network as the cluster:

First find the node IP:

```bash
kubectl get nodes -o wide
```

The `INTERNAL-IP` column shows each node's IP address. Pick one that's reachable from your machine.

Then test:

```bash
# Get first node's internal IP and test in one command
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
nc $NODE_IP 30900
```

Type anything and press Enter — the server echoes it back immediately.

**Example session:**
```
$ NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
$ nc $NODE_IP 30900
hello
hello
how are you?
how are you?
^C
```

### From inside the cluster (any pod):

```bash
kubectl run -it --rm debug --image=alpine -- sh
/ # apk add netcat-openbsd
/ # nc tcp-echo.tcp-demo 7777
hello
hello
```

---

## 2. Testing UDP Echo (NodePort)

The Traefik NodePort service exposes UDP traffic on port **30901**.

### From a machine on the same network as the cluster:

```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
nc -u $NODE_IP 30901
```

Type anything and press Enter — the server echoes it back.

**Example session:**
```
$ NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
$ nc -u $NODE_IP 30901
hello
hello
^C
```

### From inside the cluster (any pod):

```bash
kubectl run -it --rm debug --image=alpine -- sh
/ # apk add netcat-openbsd
/ # nc -u udp-echo.udp-demo 7778
hello
hello
```

**Note:** UDP is connectionless, so the first packet may be lost while socat sets up the listener. Send a couple of test messages if the first one doesn't echo.

---

## 3. Testing via ClusterIP (from any pod)

If you don't want to use NodePorts, test directly against the ClusterIP services:

```bash
# TCP
kubectl run -it --rm debug --image=alpine -- sh -c "apk add netcat-openbsd && nc tcp-echo.tcp-demo 7777"

# UDP
kubectl run -it --rm debug --image=alpine -- sh -c "apk add netcat-openbsd && nc -u udp-echo.udp-demo 7778"
```

---

## 4. Viewing Routes on the Traefik Dashboard

The Traefik dashboard shows all discovered routers (HTTP, TCP, UDP) and their backend services.

### Access via Cloudflare (if DNS is configured):

Open your browser and go to:

```
https://traefik.hoangvu75.space/dashboard/
```

### Access via Port-Forward (no DNS required):

```bash
kubectl port-forward -n gateway-api svc/traefik 8080:8080
```

Then open: [http://localhost:8080/dashboard/](http://localhost:8080/dashboard/)

### What to look for:

Once the tcp-demo and udp-demo apps are synced, the dashboard shows:

#### HTTP Section
- `tcp-echo-tcp-demo-tcp-echo` — TCP router (only if Traefik detects the IngressRouteTCP)
- `udp-echo-udp-demo-udp-echo` — UDP router (only if Traefik detects the IngressRouteUDP)

#### TCP Section
- **tcp-echo-tcp-demo-tcp-echo** (if shown here instead) — routes traffic to `tcp-echo:7777` service

#### UDP Section
- **udp-echo-udp-demo-udp-echo** — routes traffic to `udp-echo:7778` service

#### Services Section
- `tcp-echo-tcp-demo-tcp-echo` — backend service with 1 server (the tcp-echo pod)
- `udp-echo-udp-demo-udp-echo` — backend service with 1 server (the udp-echo pod)

> The exact section (HTTP vs TCP vs UDP) depends on how Traefik organizes its dashboard. The key point is that after syncing, you'll see new routers and services corresponding to these demo apps, confirming that Traefik has discovered and is routing TCP/UDP traffic correctly.

---

## 5. Verifying Access Logs & Metrics

Traefik is configured with JSON access logs and Prometheus metrics. After running TCP/UDP tests:

### Access Logs (via kubectl logs):

```bash
kubectl logs -n gateway-api deploy/traefik --tail=50 | grep tcp
```

You should see JSON log entries like:
```json
{"ClientAddr":"10.42.0.X:xxxxx","ClientHost":"10.42.0.X","DownstreamContentSize":5,..."RequestAddr":"tcp-echo.tcp-demo:7777","RouterName":"tcp-echo-tcp-demo-tcp-echo","ServiceName":"tcp-echo-tcp-demo-tcp-echo","StartUTC":"...","level":"info","msg":""}
```

### Prometheus Metrics (via curl):

```bash
kubectl run -it --rm debug --image=curlimages/curl -- sh
/ $ curl http://traefik.gateway-api:9082/metrics | grep "tcp"
```

You'll see metrics like:
```
traefik_tcp_router_server_open_connections{router="tcp-echo-tcp-demo-tcp-echo"} 0
traefik_tcp_service_open_connections{service="tcp-echo-tcp-demo-tcp-echo"} 0
```
