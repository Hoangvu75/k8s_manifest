---
trigger: always_on
---

# Project Summarization Rule

When working on this project, you MUST maintain and update project documentation to reflect important changes and keep the user informed.

## Source of Truth

Key project documentation files to read and maintain:

| Source | Location | What It Contains |
|--------|----------|------------------|
| **README.md** | `/README.md` | Overall project overview, repo structure, GitOps rules, workflow, traffic flow, app catalog |
| **Guide** | `/guide/` | Step-by-step setup instructions (ArgoCD install, secrets management) |
| **Project Wiki** | `.qoder/repowiki/` | Detailed architecture, design decisions, app configuration docs |
| **Rules** | `.qoder/rules/` | AI agent behavioral rules for this project |

## When to Update Documentation

You MUST update `.md` files when ANY of the following occurs:

1. **New app created** — Document in README.md (app catalog table) and add an app-specific `.md` if it introduces a new pattern
2. **New component created** (e.g., new Kustomize component in `components/`) — Document its purpose, how it works, and how it's consumed
3. **Architecture changed** (e.g., sync-wave ordering, traffic flow, bootstrap chain) — Update the diagrams and descriptions in README.md and relevant wiki docs
4. **New project or ApplicationSet added** — Document in the Project Management section
5. **New infrastructure dependency** (e.g., new Helm registry, new external integration) — Document in Advanced Topics or External System Integrations
6. **Secret handling changed** — Update the guide documentation
7. **Any structural change** that affects how the repo works or how a developer would use it

## How to Document

### For README.md Changes

- **App catalog** — Add/update the Common Apps table with name, type, and purpose
- **Repo structure** — Update the directory tree if new top-level or significant subdirectories are added
- **Workflow** — Update the bootstrap chain and sync order tables if new steps or waves are introduced
- **Traffic flow** — Update the network flow diagram and hostname table if new ingress routes are added

### For Guide Changes

- New setup steps → add to the appropriate `guide/` subdirectory
- New secrets or credentials → update `guide/k8s_manifest_secrets/README.md`

### For New Documentation Files

Create a new `.md` file when:
- A new application introduces a unique deployment pattern
- A new integration requires special configuration
- A new component has non-obvious behavior or dependencies

Place the file in the appropriate location under `.qoder/repowiki/` matching the existing structure.

## Reading Before Writing

Before making any significant change to the project:
1. Read `/README.md` to understand the full context
2. Read relevant files under `/guide/` for setup and operational procedures
3. Read the `.qoder/repowiki/` content related to the area you're changing
4. Check `.qoder/rules/` for active behavioral rules

## Verification

After any documentation update:
- Ensure all links and references are valid
- Keep diagrams (Mermaid or ASCII) consistent with actual project state
- Verify sync-wave numbers, namespace names, and hostnames are accurate
