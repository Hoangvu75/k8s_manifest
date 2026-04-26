# Web Research Guidelines

## Using webfetch for Internet Searches
- Use the `webfetch` tool to look up documentation, API references, changelogs, and best practices
- When searching, construct search-engine-friendly URLs (e.g., `https://www.google.com/search?q=kubernetes+ingress+annotations`)
- Prefer fetching official documentation pages directly when you know the URL (e.g., `https://kubernetes.io/docs/`, `https://argo-cd.readthedocs.io/`)
- Use `format: "markdown"` for documentation pages to get clean, readable output
- Use `format: "text"` when you need raw page content

## When to Search
- Version-specific feature availability (e.g., "when was Gateway API v1.2 graduated")
- New API changes or deprecations in Kubernetes/Helm/Kustomize
- Troubleshooting known issues with specific versions of tools
- Library/chart changelog lookups
- Best practice queries when existing project patterns are unclear

## Search URL Patterns
```
# Google search
https://www.google.com/search?q=<query>

# Docs-specific searches
https://kubernetes.io/docs/search/?q=<query>
https://argo-cd.readthedocs.io/en/stable/search.html?q=<query>
https://helm.sh/docs/search/?q=<query>
https://docs.github.com/en/search?q=<query>
```
