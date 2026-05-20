# ============================================================
# ai-agent-claude — Real Anthropic Claude Code CLI
# Build:   docker build -t ghcr.io/hoangvu75/ai-agent-claude:latest .
# Push:    docker push ghcr.io/hoangvu75/ai-agent-claude:latest
# ============================================================
FROM ubuntu:22.04

# Install system packages + Node.js 20
RUN apt update && apt upgrade -y && \
    apt install -y curl git build-essential && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt install -y nodejs && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt || echo "v1.32.0") && \
    curl -sLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl

# Install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod +x get_helm.sh && \
    ./get_helm.sh && \
    rm -f get_helm.sh

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Setup bash aliases and profile
RUN echo "alias k='kubectl'" > /root/.bashrc && \
    echo "alias kg='kubectl get'" >> /root/.bashrc && \
    echo "alias kd='kubectl describe'" >> /root/.bashrc && \
    echo "alias kl='kubectl logs'" >> /root/.bashrc && \
    echo "alias kgp='kubectl get pods'" >> /root/.bashrc && \
    echo "alias kgn='kubectl get nodes'" >> /root/.bashrc && \
    echo "alias kgs='kubectl get svc'" >> /root/.bashrc && \
    echo "alias kga='kubectl get all --all-namespaces'" >> /root/.bashrc && \
    echo "alias ai='claude'" >> /root/.bashrc && \
    echo "source /root/.bashrc" >> /root/.profile && \
    mkdir -p /root/.kube

CMD ["sleep", "infinity"]
