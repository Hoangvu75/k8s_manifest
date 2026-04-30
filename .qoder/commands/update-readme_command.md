---
description: Review the project then update the .md files 
---
Thoroughly review the entire project structure, contents, and GitOps workflow before making any changes.

Steps to follow:
1. Read `/README.md` to understand the full project overview, repo structure, app catalog, and traffic flow
2. Explore `apps/`, `bootstrap/`, `cluster-resources/`, `components/`, and `guide/` directories to identify any new or changed resources
3. Read `.qoder/repowiki/` for existing architecture documentation and design decisions
4. Compare the current project state against what is documented in all `.md` files

Then update the following documentation to reflect the current project state:
- **`/README.md`** — Update the app catalog table, repo structure tree, sync-wave ordering, and traffic flow diagram as needed
- **`/guide/`** — Update setup steps, secrets management docs, or any operational procedures that have changed

Ensure all hostnames, namespace names, sync-wave numbers, and Helm chart references are accurate and consistent across all documentation.
