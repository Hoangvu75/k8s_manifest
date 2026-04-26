---
name: dockerfile-optim
description: Optimize Dockerfiles with multi-stage builds, layer caching, security hardening, and best practices for production containers
compatibility: opencode
metadata:
  audience: devops
  stack: docker, containers, ci-cd
---

## What I Do
- Review and optimize Dockerfiles for build speed and image size
- Apply multi-stage build patterns to separate build and runtime dependencies
- Harden images with non-root users, minimal base images, and security scanning
- Recommend proper `.dockerignore` patterns
- Advise on caching strategies for faster CI/CD pipelines

## When to Use Me
Use this skill when you need to:
- Create a new Dockerfile from scratch
- Optimize an existing Dockerfile for production
- Reduce image size or build time
- Harden a container for security compliance
- Set up multi-architecture builds

## Multi-Stage Build Template
```dockerfile
# Stage 1: Build
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/binary

# Stage 2: Runtime
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app/binary /app/binary
USER nonroot:nonroot
ENTRYPOINT ["/app/binary"]
```

## Layer Caching Optimization
- Order COPY/ADD by change frequency (least changed first)
- Copy package manifests separately from source code
- Group RUN commands to reduce layers when they don't benefit from caching
- Example order: `FROM` → `RUN` (system deps) → `COPY` (package files) → `RUN` (install deps) → `COPY` (source) → `RUN` (build)

## Security Checklist
- [ ] Use specific base image tags (never `:latest`)
- [ ] Run as non-root user (`USER 1000`)
- [ ] Use distroless or Alpine-based images for runtime
- [ ] Remove build tools and cache in same layer
- [ ] Set `WORKDIR` explicitly
- [ ] Use `HEALTHCHECK` for long-running services
- [ ] Scan images with Trivy or similar before pushing
- [ ] Never hardcode secrets — use build args with caution or external secret injection

## Node.js Example
```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY . .

FROM node:22-alpine
RUN addgroup -S app && adduser -S app -G app
USER app
WORKDIR /app
COPY --from=builder --chown=app:app /app /app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "index.js"]
```

## .dockerignore Basics
```
node_modules
.git
.gitignore
*.md
.env*
Dockerfile
docker-compose*.yml
.nyc_output
coverage
dist
**
**/node_modules
```
