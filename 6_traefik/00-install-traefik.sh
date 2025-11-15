#!/bin/bash
set -e

# Traefik Installation Script with Cloudflare SSL
# Official Helm Chart: https://github.com/traefik/traefik-helm-chart
# Documentation: https://doc.traefik.io/traefik/

echo "=========================================="
echo "Installing Traefik with Cloudflare SSL via Helm"
echo "=========================================="

# Add Traefik Helm repository
echo "Adding Traefik Helm repository..."
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Create namespace for Traefik
echo "Creating traefik-system namespace..."
kubectl create namespace traefik-system --dry-run=client -o yaml | kubectl apply -f -

# Check if Cloudflare Origin Certificate exists
if ! kubectl get secret cloudflare-origin-cert -n traefik-system &> /dev/null; then
    echo ""
    echo "=========================================="
    echo "WARNING: Cloudflare Origin Certificate not found!"
    echo "=========================================="
    echo ""
    echo "Please run the following script first to create the certificate:"
    echo "  bash 6_traefik/00-create-cloudflare-cert.sh"
    echo ""
    echo "Or create it manually:"
    echo "  kubectl create secret tls cloudflare-origin-cert \\"
    echo "    --cert=origin-cert.pem \\"
    echo "    --key=origin-key.pem \\"
    echo "    --namespace=traefik-system"
    echo ""
    read -p "Do you want to continue without SSL? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo "Exiting. Please create the certificate first."
        exit 1
    fi
fi

# Install Traefik with custom values for Cloudflare
echo "Installing Traefik with Cloudflare SSL support..."
helm upgrade --install traefik traefik/traefik \
  --namespace traefik-system \
  --version 32.1.1 \
  --set ingressRoute.dashboard.enabled=true \
  --set ingressRoute.dashboard.matchRule="Host(\`traefik.mireu.xyz\`)" \
  --set ingressRoute.dashboard.entryPoints[0]=web \
  --set ingressRoute.dashboard.entryPoints[1]=websecure \
  --set ports.web.port=80 \
  --set ports.websecure.port=443 \
  --set ports.websecure.tls.enabled=true \
  --set service.type=LoadBalancer \
  --set deployment.replicas=1 \
  --set resources.requests.cpu="100m" \
  --set resources.requests.memory="128Mi" \
  --set resources.limits.cpu="1000m" \
  --set resources.limits.memory="1Gi" \
  --wait

echo "=========================================="
echo "Traefik installation completed!"
echo "=========================================="

# Wait for Traefik to be ready
echo "Waiting for Traefik to be ready..."
kubectl wait --namespace traefik-system \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=traefik \
  --timeout=300s

echo "Traefik is ready!"
echo ""
echo "Dashboard URL: http://traefik.mireu.xyz"
echo ""
echo "To get LoadBalancer IP:"
echo "kubectl get svc -n traefik-system traefik"
