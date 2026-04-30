# TCP / UDP Demo Testing Guide

This guide explains how to test the TCP and UDP demo apps (tcp-demo, udp-demo) created under `apps/applications/`, and how to observe them on the Traefik dashboard.

## Overview

Two echo-server apps have been created to demonstrate Traefik's Layer 4 routing capabilities:

| App | EntryPoint | NodePort | Container | Backend Port |
|-----|-----------|----------|-----------|-------------|
| tcp-demo | `tcp` (:9000) | **30900** | `alpine/socat` TCP echo (socat TCP-LISTEN) | 7777 |
| udp-demo | `udp` (:9001/UDP) | **30901** | `alpine/socat` UDP echo (socat UDP-LISTEN) | 7778 |

Both are routed via Traefik's **native CRDs** (`IngressRouteTCP`/`IngressRouteUDP`), not through the Gateway API Gateway. Traefik listens for TCP/UDP traffic on its `tcp` (:9000) and `udp` (:9001/UDP) entryPoints, and routes it directly to the backend services based on the CRD rules.

---

## 1. Testing via cluster-check (easiest — recommended)

The `cluster-check` pod is a persistent debug jump pod with all networking tools pre-installed (`curl`, `nc`, `telnet`, `dig`, `tcpdump`...). It's the simplest way to test from inside the cluster.

### Exec into the pod

```bash
kubectl exec -it -n cluster-check deploy/cluster-check -- bash
```

### Test TCP echo

```bash
echo "hello" | nc tcp-echo.tcp-demo 7777
```
Expected: `hello` echoed back.

### Test UDP echo

```bash
echo "hello" | nc -u udp-echo.udp-demo 7778
```

> UDP first packet may be lost — run twice if needed.

**Full session:**
```
cluster-check:~$ echo "hello" | nc tcp-echo.tcp-demo 7777
hello
cluster-check:~$ echo "hello" | nc -u udp-echo.udp-demo 7778
hello
```

---

## 2. Testing via NodePort (from outside the cluster)

For machines on the same network as the cluster:

```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# TCP (uses curl, works in Git Bash)
echo "hello" | curl -s telnet://$NODE_IP:30900

# UDP (uses Python)
python3 -c "import socket; s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.settimeout(3); s.sendto(b'hello',('$NODE_IP',30901)); print('Got:', s.recvfrom(1024)[0].decode())"
```

---

## 3. Quick one-shot test (no cluster-check needed)

```bash
# TCP
kubectl run -it --rm debug --image=nicolaka/netshoot -- bash -c "echo 'hello' | nc tcp-echo.tcp-demo 7777"

# UDP
kubectl run -it --rm debug --image=nicolaka/netshoot -- bash -c "echo 'hello' | nc -u udp-echo.udp-demo 7778"
```

---

## 4. Viewing Routes on the Traefik Dashboard

### Access via Cloudflare (if DNS is configured):

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
- Shows only HTTP routers/services (dashboard, rancher, argocd ingress routes)

#### TCP Section
- **tcp-echo-tcp-demo-tcp-echo** — routes TCP traffic from entryPoint `tcp` (:9000) to `tcp-echo:7777` service
- **tcp-echo-tcp-demo-tcp-echo** — the backend Service with 1 server (the tcp-echo pod)

#### UDP Section
- **udp-echo-udp-demo-udp-echo** — routes UDP traffic from entryPoint `udp` (:9001/UDP) to `udp-echo:7778` service
- **udp-echo-udp-demo-udp-echo** — the backend Service with 1 server (the udp-echo pod)

> After successful tests, these dashboard counters will show traffic data (connection counts, bytes transferred).

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

### Prometheus Metrics (via curl from cluster-check):

```bash
kubectl exec -it -n cluster-check deploy/cluster-check -- curl -s http://traefik.gateway-api:9082/metrics | grep "tcp\\|udp"
```

You'll see metrics like:
```
traefik_tcp_router_server_open_connections{router="tcp-echo-tcp-demo-tcp-echo"} 0
traefik_udp_router_server_open_connections{router="udp-echo-udp-demo-udp-echo"} 0
```
