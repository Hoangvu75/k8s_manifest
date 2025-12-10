#!/bin/bash

# Script to forward ports for ArgoCD and Jenkins

echo "🚀 Starting port-forwarding for ArgoCD and Jenkins..."
echo ""

# Forward ArgoCD
echo "📡 Forwarding ArgoCD to http://localhost:8080"
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
ARGOCD_PID=$!

# Forward Jenkins  
echo "📡 Forwarding Jenkins to http://localhost:9090"
kubectl port-forward -n devops-tools svc/jenkins 9090:8080 > /dev/null 2>&1 &
JENKINS_PID=$!

echo ""
echo "✅ Port-forwarding started!"
echo ""
echo "📋 Access URLs:"
echo "  ArgoCD:  http://localhost:8080"
echo "  Jenkins: http://localhost:9090"
echo ""
echo "🔑 Get credentials:"
echo "  ArgoCD password:"
echo "    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
echo ""
echo "  Jenkins password:"
echo "    kubectl exec -n devops-tools deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
echo "⚠️  Press Ctrl+C to stop all port-forwarding"
echo ""

# Trap Ctrl+C to clean up
trap "echo ''; echo '🛑 Stopping port-forwarding...'; kill $ARGOCD_PID $JENKINS_PID $RANCHER_PID 2>/dev/null; echo '✅ Stopped'; exit" INT

# Keep script running
wait

