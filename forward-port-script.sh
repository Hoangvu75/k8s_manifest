#!/bin/bash

echo "🚀 Starting port-forwarding for ArgoCD and Jenkins..."
echo ""

# Forward ArgoCD
echo "📡 Forwarding ArgoCD to http://localhost:8080"
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Port Rancher  
echo "📡 Forwarding Rancher to https://localhost:8081"

# Forward Jenkins  
echo "📡 Forwarding Jenkins to http://localhost:8082"
kubectl port-forward -n devops-tools svc/jenkins 8082:8080

# Forward Harbor
echo "📡 Forwarding Harbor to http://localhost:8083"
kubectl -n devops-tools port-forward svc/harbor 8083:80

