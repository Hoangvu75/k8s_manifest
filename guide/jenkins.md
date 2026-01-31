# Jenkins

## Access

Open browser: **https://jenkins.localhost**

---

## Get Unlock Password (First Time)

One-liner (on Windows using Git Bash, `MSYS_NO_PATHCONV=1` is needed so `/var/...` paths aren't converted to Windows paths):

```bash
MSYS_NO_PATHCONV=1 kubectl exec -n jenkins $(kubectl get pods -n jenkins -o jsonpath='{.items[0].metadata.name}') -- cat /var/jenkins_home/secrets/initialAdminPassword
```

Copy the printed password string → paste into the **Administrator password** box on the Jenkins Unlock page → click **Continue**.

---

## Install and Configure Kubernetes Plugin (for Kaniko)

Kaniko pipelines need Jenkins to connect to the Kubernetes cluster to create build pods. Perform the following two steps on the Jenkins web UI.

### 1. Install Kubernetes Plugin

1. Login to Jenkins → **Manage Jenkins** → **Manage Plugins**.
2. **Available** tab → search for **Kubernetes**.
3. Select **Kubernetes** (Kubernetes plugin).
4. Click **Install without restart** (or **Download now and install after restart**).
5. If restart is required: **Manage Jenkins** → **Restart**.

### 2. Create Kubernetes Credential (Service Account Token)

Jenkins needs permission to create/delete pods in the namespace to run agents (Kaniko). The ServiceAccount and RBAC are in the repo at **`apps/playground/jenkins/chart/jenkins-sa.yaml`** — Argo CD will create these when syncing the `playground-jenkins` app. If not yet synced, wait for Argo CD or apply manually: `kubectl apply -f apps/playground/jenkins/chart/jenkins-sa.yaml`.

**Step 1 – Ensure ServiceAccount exists** (exists if Argo CD synced the Jenkins app). If creating manually, use the file in the repo:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins-sa
  namespace: jenkins
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-agent-role
  namespace: jenkins
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/exec", "pods/attach"]
  verbs: ["create", "delete", "get", "list", "watch", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-agent-rolebinding
  namespace: jenkins
subjects:
- kind: ServiceAccount
  name: jenkins-sa
  namespace: jenkins
roleRef:
  kind: Role
  name: jenkins-agent-role
  apiGroup: rbac.authorization.k8s.io
```

**Step 2 – Get Token (Kubernetes 1.24+):**

```bash
kubectl create token jenkins-sa -n jenkins --duration=8760h
```

Copy the complete token string printed.

**Step 3 – Add Credential in Jenkins:**

1. On the **New cloud** (Kubernetes) page, in the **Credentials** field click **Add**.
2. **Kind**: select **Secret text**.
3. **Secret**: paste the token copied above.
4. **ID**: set a name (e.g., `jenkins-k8s-sa-token`).
5. **Description** (optional): e.g., "Service Account token for Jenkins agents".
6. Click **Add** → go back to the **Credentials** dropdown and select the newly created credential.

---

### 3. Configure Kubernetes Cloud (Fields)

1. **Manage Jenkins** → **Clouds** → **Configure Clouds** (or **New Cloud**) → select **Kubernetes**.
2. Fill in each field:

| Field | Select / Value |
|-------|----------------|
| **Name** | `kubernetes` (keep default or rename). |
| **Kubernetes URL** | Jenkins in same cluster: leave **empty** or `https://kubernetes.default.svc`. External: API URL (e.g., `https://<cluster-ip>:6443`). |
| **Use Jenkins Proxy** | Unchecked (unless Jenkins must use proxy to reach cluster). |
| **Kubernetes server certificate key** | Leave empty (cluster uses default CA). |
| **Disable https certificate check** | Only check if dev/test and cert errors occur; uncheck for production. |
| **Kubernetes Namespace** | `jenkins` (namespace running agents, matching where ServiceAccount was created). |
| **Agent Docker Registry** | Leave empty (Kaniko uses images from `gcr.io`). Fill if using private registry. |
| **Inject restricted PSS...** | Uncheck initially; check if cluster enforces PSS. |
| **Credentials** | Select the **Secret text** credential containing the Service Account token. Click **Test Connection** to verify. |
| **WebSocket** | **Check** (agent connection to Jenkins is more stable). |
| **Direct Connection** | Optional; usually not needed if WebSocket is enabled. |
| **Jenkins URL** | **Must use internal Service URL** so pod agent (in cluster) can call it: `http://jenkins.jenkins.svc.cluster.local:8080`. Do NOT use `https://jenkins.localhost` — from inside cluster it won't resolve correctly, causing agent to fail and Jenkins reporting "offline". |
| **Jenkins tunnel** | Leave empty. |
| **Connection Timeout / Read Timeout** | Keep defaults (5, 15) unless network is slow. |
| **Concurrency Limit** | Empty (unlimited) or set a number to limit concurrent agent pods. |

**Configuration below (Pod Retention, timeouts, ...):**

| Field | Select / Value |
|-------|----------------|
| **Add Pod Label** | Optional; can be ignored (Kaniko pipeline defines pod in Jenkinsfile). |
| **Pod Retention** | Keep **Never** — agent pod is deleted immediately after build (saves resources). |
| **Max connections to Kubernetes API** | Keep default **32** (or empty). |
| **Seconds to wait for pod to be running** | Set **900** or **1200** (15–20 mins) — initial pull of jnlp (~150MB) + Kaniko (~40MB) images may take minutes; 600 might timeout before pod is ready. |
| **Container Cleanup Timeout** | Keep **5** (minutes) — wait time to clean up container after pod finishes. |
| **Transfer proxy related environment variables...** | Unchecked (unless agent needs proxy). |
| **Restrict pipeline support to authorized folders** | Unchecked (unless limiting K8s agents to specific folders). |
| **Defaults Provider Template Name** | Leave empty. |
| **Enable garbage collection** | **Check** — plugin cleans up old pods/volumes. |

3. Leave **Pod Templates** section empty; Kaniko pipeline uses `podTemplate` in Jenkinsfile.
4. **Save**.

After configuration, run the Kaniko pipeline; Jenkins will create a pod in `jenkins` namespace and run build in Kaniko container.

---

### 4. Pod Stuck "ContainerCreating" / Agent "Offline" — Stuck for Long Time

If console shows pod **Pending**, container **ContainerCreating**, agent **offline** and **Still waiting to schedule task** (build stuck for minutes):

**Step 1 – Increase Timeout (Mandatory):**
**Manage Jenkins** → **Clouds** → click **kubernetes** → find **Seconds to wait for pod to be running** → change to **1200** (20 mins) → **Save**. If kept at 600, Jenkins stops waiting before pod finishes pulling images.

**Step 2 – Wait Once, Do Not Cancel:**
Run **Build Now** and **let it run 5–10 mins** (do not Cancel). First time cluster pulls jnlp (~150MB) and Kaniko (~40MB) images. When pod is Ready, build proceeds. Subsequent builds on nodes with cached images will be faster.

**Step 3 – Pre-pull (Optional):**
To speed up subsequent builds, pre-pull images to nodes:

- **Method A – SSH access to node (worker):**
  SSH into node (e.g. `desktop-worker2`), run:
  `crictl pull jenkins/inbound-agent:3355.v388858a_47b_33-3-jdk21` and
  `crictl pull gcr.io/kaniko-project/executor:v1.6.0-debug`
  (use `docker pull` if node uses Docker).

- **Method B – No SSH access:**
  Create a temporary Job to force pull. Save this file and run `kubectl apply -f jenkins-agent-prepull.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: jenkins-agent-prepull
  namespace: jenkins
spec:
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: jnlp
        image: jenkins/inbound-agent:3355.v388858a_47b_33-3-jdk21
        command: ["sleep", "60"]
      - name: kaniko
        image: gcr.io/kaniko-project/executor:v1.6.0-debug
        command: ["sleep", "60"]
```

This Job creates a pod using these images → kubelet pulls them. After a few minutes pod Completes; delete Job: `kubectl delete job jenkins-agent-prepull -n jenkins`. Subsequent Jenkins builds on **that same node** will be faster.

**Check Pod:**
`kubectl get pods -n jenkins` and `kubectl describe pod -n jenkins <pod-name>`. Events showing **Pulled**, **Started** means pod ran; if Jenkins still offline, it timed out — increase to 1200 then rebuild.

---

### 5. Pod Running but Agent "Offline" / Build Not Starting

If Dashboard shows pod **Running** but Jenkins says **Still waiting to schedule task**, **agent offline**:

**Cause:** **jnlp** container (Jenkins agent) cannot connect back to Jenkins. Usually because **Jenkins URL** is `https://jenkins.localhost` — inside cluster `jenkins.localhost` may resolve to 127.0.0.1, failing connection.

**Fix:**
**Manage Jenkins** → **Clouds** → click **kubernetes** → find **Jenkins URL** → change to **Internal Service URL**:

- `http://jenkins.jenkins.svc.cluster.local:8080`

(Service is usually named `jenkins` in `jenkins` namespace, port 8080.)
**Save** → **Build Now**. New pod uses internal URL, agent connects, build proceeds.

---

### 6. Push Harbor Error: Token "harbor.localhost" / Connection Refused

If Kaniko fails with: `Get "https://harbor.localhost/service/token?...": dial tcp [::1]:443: connection refused`:

**Cause:** Harbor returns token URL as `https://harbor.localhost`. Inside pod, `harbor.localhost` resolves to 127.0.0.1.

**Fix:** Pipeline adds **hostAliases** to resolve `harbor.localhost` to Ingress. Configure **INGRESS_CLUSTER_IP** in Jenkins:

1. Get Ingress ClusterIP:
   ```bash
   kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}'
   ```
   (Adjust namespace/name if different.)

2. In Jenkins: **Manage Jenkins** → **System** → **Global properties** → Check **Environment variables** → **Add**:
   - **Name:** `INGRESS_CLUSTER_IP`
   - **Value:** Paste ClusterIP (e.g., `10.96.123.45`).

3. **Save** → **Build Now**.

Agent pod uses hostAliases to resolve `harbor.localhost` to Ingress → requests token from Ingress:443 → Ingress forwards to Harbor Core → push succeeds.
