# GitHub Actions Runner Controller (ARC)

Deploys self-hosted GitHub Actions runners on the cluster using GitHub's official **Autoscaling Runner Scale Sets** mode. Lets you run unlimited GitHub Actions workflows on your own hardware (no GitHub-hosted minute quota).

## Architecture

```
       ┌────────────────────────┐
       │   GitHub Actions       │
       │   Service (api.gh.com) │
       └──────────┬─────────────┘
                  │ long-poll HTTPS (outbound only)
                  ▼
   ┌──────────────────────────────────┐
   │  arc-systems namespace           │
   │  ┌────────────────────────────┐  │
   │  │ arc (controller manager)   │  │── reconciles
   │  └────────────┬───────────────┘  │   AutoscalingRunnerSet CR
   │               │                  │
   └───────────────┼──────────────────┘
                   ▼
   ┌──────────────────────────────────────────┐
   │  arc-runners namespace                   │
   │  ┌────────────────────────────────────┐  │
   │  │ arc-runner-set-listener pod        │  │── polls GitHub for jobs
   │  └─────────────┬──────────────────────┘  │
   │                │ scales 0..N             │
   │                ▼                         │
   │  ┌──────────┐  ┌──────────┐  ...         │
   │  │ runner-0 │  │ runner-1 │  ephemeral   │
   │  │ + dind   │  │ + dind   │  pods        │
   │  └──────────┘  └──────────┘              │
   └──────────────────────────────────────────┘
```

- **Controller** (`apps/infra/arc-controller`, `arc-systems` ns, sync-wave `2`) — installs the CRDs and manages `AutoscalingRunnerSet` resources cluster-wide. Watches only the `arc-runners` namespace (locked down via `flags.watchSingleNamespace`).
- **Runner Scale Set** (`apps/infra/arc-runner-set`, `arc-runners` ns, sync-wave `3`) — defines a scale set named `arc-runner-set` registered against your GitHub repo. Spawns ephemeral runner pods on demand and tears them down when idle (scale-to-zero).
- **No inbound traffic** — runners only make outbound HTTPS to `api.github.com` and the Actions service. No Gateway/HTTPRoute needed.

## Setup Steps

### 1. Create GitHub auth credentials

Pick **one** of the two methods.

#### Option A — Personal Access Token (simpler, fine for one repo)

1. Go to GitHub → Settings → Developer settings → **Personal access tokens (classic)** → Generate new token (classic)
2. Scope:
   - For **repo-level** runners: tick `repo` (full control)
   - For **org-level** runners: tick `admin:org`
3. Copy the token (`ghp_…`)

#### Option B — GitHub App (recommended for production / multiple repos)

1. GitHub → Settings → Developer settings → **GitHub Apps** → New GitHub App
2. Permissions:
   - For **repo-level**: `Administration: Read & write`, `Metadata: Read`
   - For **org-level**: same plus `Self-hosted runners: Read & write` (org)
3. Generate a private key (`.pem` file) and note the **App ID**
4. Install the App on the target repo or org and note the **Installation ID** (visible in the install URL: `…/installations/<id>`)

### 2. Add the auth secret to the private secrets repo

In `k8s_manifest_secrets` (the private repo synced by `bootstrap/secrets.yaml`), add `arc-github-config.yaml`. See `guide/2. secret_storage/README.md` for the exact format.

The secret **must** be:
- Named `arc-github-config`
- In namespace `arc-runners`
- Either keyed with `github_token` (PAT) **or** with `github_app_id` + `github_app_installation_id` + `github_app_private_key` (App)

Commit and push to the private repo — ArgoCD's `secrets` Application will sync it within ~20s.

### 3. (Optional) Point the scale set at a different repo / org

By default `apps/infra/arc-runner-set/chart/values.yaml` registers against `https://github.com/Hoangvu75/k8s_manifest`. To change:

```yaml
# apps/infra/arc-runner-set/chart/values.yaml
githubConfigUrl: "https://github.com/<owner>/<repo>"          # repo-level
# OR
githubConfigUrl: "https://github.com/<org>"                   # org-level
# OR
githubConfigUrl: "https://github.com/enterprises/<enterprise>" # enterprise-level
```

Commit, push — ArgoCD picks it up automatically.

### 4. Verify the runner is registered

Once both apps are Synced/Healthy in ArgoCD:

```bash
kubectl -n arc-systems get pods
# arc-gha-rs-controller-xxxx                    1/1     Running

kubectl -n arc-runners get pods
# arc-runner-set-xxx-listener                   1/1     Running

kubectl -n arc-runners get autoscalingrunnerset
# NAME             MINIMUM   MAXIMUM   CURRENT   STATE   ...
# arc-runner-set   0         5
```

Then on GitHub: **Repo → Settings → Actions → Runners** — you should see a runner scale set named `arc-runner-set` with status "Idle".

### 5. Use it in a workflow

In any `.github/workflows/*.yml` in the target repo:

```yaml
jobs:
  build:
    runs-on: arc-runner-set     # name = releaseName of the helm chart
    steps:
      - uses: actions/checkout@v5
      - run: echo "Running on a self-hosted runner in our cluster!"
```

Trigger a workflow run — within a few seconds the controller will spawn a runner pod in `arc-runners`. After the job finishes, the pod is deleted (ephemeral runners).

## Configuration Cheatsheet

All knobs live in `apps/infra/arc-runner-set/chart/values.yaml`:

| Key | Default | Purpose |
|-----|---------|---------|
| `githubConfigUrl` | `https://github.com/Hoangvu75/k8s_manifest` | Target repo / org / enterprise |
| `githubConfigSecret` | `arc-github-config` | K8s secret holding PAT or App creds |
| `minRunners` | `0` | Idle floor — `0` = scale-to-zero |
| `maxRunners` | `5` | Hard cap on concurrent runners. Bump as high as your cluster can handle. |
| `runnerScaleSetName` | `arc-runner-set` | Name used in `runs-on:` in workflows |
| `containerMode.type` | `dind` | `dind` for Docker-in-Docker, or `kubernetes` for k8s-mode (needs PV per pod) |
| `template.spec.containers[0].resources` | 250m/512Mi → 2000m/4Gi | Runner pod resource requests/limits |

For "unlimited" parallelism, set `maxRunners` to a high value (e.g. `100`) — the actual ceiling is your cluster's CPU / memory.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Listener pod CrashLoopBackOff | Wrong / missing `arc-github-config` secret | Re-check secret keys (`github_token` **or** App trio); verify it's in `arc-runners` ns |
| `403 Resource not accessible by integration` | PAT scope too narrow | Re-issue PAT with `repo` (or `admin:org`) |
| `404 Not Found` on registration | `githubConfigUrl` typo | Must be a real, accessible GitHub URL with no trailing slash |
| Runner never picks up jobs | `runs-on:` mismatch | Use the exact `runnerScaleSetName` value (default `arc-runner-set`) |
| Docker commands fail in workflow | `containerMode.type` not `dind` | Either set `dind` in values, or switch the workflow to non-Docker steps |
| Controller doesn't see CR | `flags.watchSingleNamespace` set wrong | Must be `arc-runners` (matches scale set ns) |

## References

- [ARC docs](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/quickstart-for-actions-runner-controller)
- [Helm chart source](https://github.com/actions/actions-runner-controller/tree/master/charts)
- [Troubleshooting guide](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/troubleshooting-actions-runner-controller-errors)
