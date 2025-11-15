#!/bin/bash
set -e

# Cloudflare Origin CA Certificate Setup Script
# This script helps you create a Kubernetes secret with Cloudflare Origin CA certificates

echo "=========================================="
echo "Cloudflare Origin CA Certificate Setup"
echo "=========================================="
echo ""
echo "Before running this script, you need to:"
echo "1. Go to Cloudflare Dashboard → SSL/TLS → Origin Server"
echo "2. Click 'Create Certificate'"
echo "3. Choose settings:"
echo "   - Private key type: RSA (2048)"
echo "   - Hostnames: *.mireu.xyz, mireu.xyz"
echo "   - Certificate validity: 15 years (recommended)"
echo "4. Click 'Create'"
echo "5. Save both the Origin Certificate and Private Key"
echo ""
echo "=========================================="
echo ""

# Prompt for certificate path
read -p "Enter path to Origin Certificate file (PEM format): " CERT_FILE
read -p "Enter path to Private Key file: " KEY_FILE

# Validate files exist
if [ ! -f "$CERT_FILE" ]; then
    echo "Error: Certificate file not found: $CERT_FILE"
    exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Private key file not found: $KEY_FILE"
    exit 1
fi

echo ""
echo "Creating Kubernetes secret in traefik-system namespace..."

# Create namespace if it doesn't exist
kubectl create namespace traefik-system --dry-run=client -o yaml | kubectl apply -f -

# Create TLS secret
kubectl create secret tls cloudflare-origin-cert \
  --cert="$CERT_FILE" \
  --key="$KEY_FILE" \
  --namespace=traefik-system \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "=========================================="
echo "✓ Cloudflare Origin Certificate installed!"
echo "=========================================="
echo ""
echo "Secret name: cloudflare-origin-cert"
echo "Namespace: traefik-system"
echo ""
echo "You can now proceed with deploying Traefik."
echo ""

# Verify secret
echo "Verifying secret..."
kubectl get secret cloudflare-origin-cert -n traefik-system

echo ""
echo "Next steps:"
echo "1. Ensure Cloudflare DNS is configured (Proxy enabled - orange cloud)"
echo "2. Set Cloudflare SSL/TLS mode to 'Full (strict)'"
echo "3. Run: bash 6_traefik/deploy-all.sh"
