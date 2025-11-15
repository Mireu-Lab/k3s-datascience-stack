#!/bin/bash
# SSL Troubleshooting Script

echo "=========================================="
echo "Cloudflare SSL Troubleshooting"
echo "=========================================="
echo ""

echo "1. Checking Cloudflare Origin Certificate in all namespaces..."
echo ""
for ns in traefik-system jupyterhub grafana spark hdfs postgres; do
    echo -n "  $ns: "
    if kubectl get secret cloudflare-origin-cert -n $ns &>/dev/null; then
        echo "✓ Secret exists"
    else
        echo "✗ Secret NOT found"
    fi
done

echo ""
echo "2. Checking IngressRoute TLS configuration..."
echo ""
kubectl get ingressroute -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,TLS:.spec.tls.secretName 2>/dev/null | grep -v '<none>'

echo ""
echo "3. Checking Traefik pod status..."
echo ""
kubectl get pods -n traefik-system -l app.kubernetes.io/name=traefik

echo ""
echo "4. Checking LoadBalancer IP..."
echo ""
LB_IP=$(kubectl get svc -n traefik-system traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "  LoadBalancer IP: $LB_IP"

echo ""
echo "5. Testing JupyterHub service..."
echo ""
if kubectl get svc proxy-public -n jupyterhub &>/dev/null; then
    echo "  ✓ JupyterHub proxy-public service exists"
else
    echo "  ✗ JupyterHub proxy-public service NOT found"
fi

echo ""
echo "=========================================="
echo "IMPORTANT: Cloudflare Configuration Checklist"
echo "=========================================="
echo ""
echo "Please verify in Cloudflare Dashboard:"
echo ""
echo "1. DNS Records (Cloudflare Dashboard → DNS → Records):"
echo "   - jupyter.mireu.xyz → $LB_IP [Proxied ☁️ ORANGE]"
echo "   - grafana.mireu.xyz → $LB_IP [Proxied ☁️ ORANGE]"
echo "   - spark.mireu.xyz   → $LB_IP [Proxied ☁️ ORANGE]"
echo "   - hdfs.mireu.xyz    → $LB_IP [Proxied ☁️ ORANGE]"
echo "   - pg.mireu.xyz      → $LB_IP [Proxied ☁️ ORANGE]"
echo ""
echo "2. SSL/TLS Mode (Cloudflare Dashboard → SSL/TLS → Overview):"
echo "   - Must be: Full (strict)"
echo "   - NOT: Off, Flexible, or Full"
echo ""
echo "3. Origin CA Certificate (Cloudflare Dashboard → SSL/TLS → Origin Server):"
echo "   - Verify certificate exists for *.mireu.xyz"
echo "   - Certificate should match the one in Kubernetes secrets"
echo ""
echo "4. Edge Certificates (Cloudflare Dashboard → SSL/TLS → Edge Certificates):"
echo "   - Universal SSL should be 'Active'"
echo "   - 'Always Use HTTPS' should be ON"
echo ""
echo "=========================================="
echo "Common Issues:"
echo "=========================================="
echo ""
echo "ERR_SSL_VERSION_OR_CIPHER_MISMATCH usually means:"
echo "1. SSL/TLS mode is NOT set to 'Full (strict)'"
echo "2. Origin Certificate is missing or incorrect"
echo "3. DNS Proxy is disabled (should be orange cloud)"
echo "4. Cloudflare Universal SSL is not active yet (wait 24h)"
echo ""
