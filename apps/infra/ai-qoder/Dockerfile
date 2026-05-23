# ============================================================
# ai-agent-qoder — Qoder CLI running inside the cluster
# Build:   docker build -t ghcr.io/hoangvu75/ai-agent-qoder:latest .
# Push:    docker push ghcr.io/hoangvu75/ai-agent-qoder:latest
# ============================================================
FROM node:20-alpine

# Install system tools
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    openssl \
    python3

# Install kubectl
RUN KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt || echo "v1.32.0") && \
    curl -sLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl

# Install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod +x get_helm.sh && \
    (./get_helm.sh || VERIFY_CHECKSUM=false ./get_helm.sh) && \
    rm -f get_helm.sh

# Install Qoder CLI
RUN npm install -g @qoder-ai/qodercli

# Setup bash aliases and profile
RUN echo "alias k='kubectl'" > /root/.bashrc && \
    echo "alias kg='kubectl get'" >> /root/.bashrc && \
    echo "alias kd='kubectl describe'" >> /root/.bashrc && \
    echo "alias kl='kubectl logs'" >> /root/.bashrc && \
    echo "alias kgp='kubectl get pods'" >> /root/.bashrc && \
    echo "alias kgn='kubectl get nodes'" >> /root/.bashrc && \
    echo "alias kgs='kubectl get svc'" >> /root/.bashrc && \
    echo "alias kga='kubectl get all --all-namespaces'" >> /root/.bashrc && \
    echo "alias ai='qodercli'" >> /root/.bashrc && \
    echo "alias pyrun='python3'" >> /root/.bashrc && \
    echo "source /root/.bashrc" >> /root/.profile && \
    mkdir -p /root/.kube

# Bake in cluster knowledge — auto-loaded by Qoder CLI from ~/.qoder/AGENTS.md
COPY AGENTS.md /root/.qoder/AGENTS.md

CMD ["sleep", "infinity"]
