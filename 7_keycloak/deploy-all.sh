#!/bin/bash
set -e

echo "=========================================="
echo "Deploying Keycloak IAM Stack"
echo "=========================================="
echo ""
echo "This script will deploy Keycloak with:"
echo "  - Keycloak Operator (Helm Chart)"
echo "  - Keycloak Instance with PostgreSQL backend"
echo "  - ResearchOpe Realm with Google OAuth"
echo "  - OAuth Clients for JupyterHub, Grafana"
echo "  - Service Account Clients for Spark, HDFS, PostgreSQL"
echo "  - JWT Middleware for *.mireu.xyz"
echo ""

# Set kubeconfig for k3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Step 1: Install Keycloak Operator via Helm
echo ""
echo "Step 1: Installing Keycloak Operator via Helm..."
bash 7_keycloak/00-install-operator.sh

# Step 2: Create Google OAuth Secret
echo ""
echo "Step 2: Creating Google OAuth Secret..."
kubectl apply -f 7_keycloak/02-keycloak-realm.yaml

# Step 3: Deploy Keycloak Instance
echo ""
echo "Step 3: Deploying Keycloak Instance..."
kubectl apply -f 7_keycloak/01-keycloak-instance.yaml

# Wait for Keycloak to be ready
echo ""
echo "Waiting for Keycloak instance to be ready (this may take 5-10 minutes)..."
kubectl wait --for=condition=ready pod -l app=keycloak -n keycloak --timeout=600s || {
    echo "Warning: Keycloak pod not ready yet. Checking status..."
    kubectl get pods -n keycloak
    kubectl describe pod -l app=keycloak -n keycloak | tail -50
}

# Step 4: Deploy Keycloak Realm and Clients
echo ""
echo "Step 4: Deploying Keycloak Realm and Clients via CRDs..."
kubectl apply -f 7_keycloak/03-keycloak-clients.yaml

# Step 5: Deploy IngressRoute and Middlewares
echo ""
echo "Step 5: Deploying Keycloak IngressRoute and JWT Middlewares..."
kubectl apply -f 7_keycloak/04-keycloak-ingressroute.yaml
kubectl apply -f 7_keycloak/09-jwt-middlewares.yaml

# Step 6: Wait for Keycloak to be fully operational
echo ""
echo "Waiting for Keycloak to be fully operational..."
sleep 60

# Step 7: Configure Google OAuth via API
echo ""
echo "Step 7: Configuring Google OAuth Identity Provider..."
bash 7_keycloak/05-configure-realm.sh || {
    echo "Warning: OAuth configuration failed. You may need to configure manually."
    echo "Continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
}

# Step 8: Generate Service Account Tokens
echo ""
echo "Step 8: Generating Service Account Tokens for Spark, HDFS, PostgreSQL..."
bash 7_keycloak/06-generate-service-tokens.sh || {
    echo "Warning: Token generation can be done later after services are deployed."
}

# Step 9: Update JupyterHub OAuth Configuration
echo ""
echo "Step 9: Updating JupyterHub OAuth Configuration..."
bash 7_keycloak/07-update-jupyterhub-oauth.sh || {
    echo "Warning: JupyterHub OAuth configuration can be updated later."
}

# Step 10: Update Grafana OAuth Configuration
echo ""
echo "Step 10: Updating Grafana OAuth Configuration..."
bash 7_keycloak/08-update-grafana-oauth.sh || {
    echo "Warning: Grafana OAuth configuration can be updated later."
}

echo ""
echo "=========================================="
echo "Keycloak IAM Stack Deployment Complete!"
echo "=========================================="
echo ""
echo "Keycloak Access:"
echo "  URL: https://keycloak.mireu.xyz"
echo "  Admin Console: https://keycloak.mireu.xyz/admin"
echo "  Username: admin"
echo "  Password: admin"
echo "  Realm: researchope"
echo ""
echo "⚠️  IMPORTANT: Change admin password after first login!"
echo ""
echo "Google OAuth Configuration:"
echo "  Identity Provider: Google"
echo "  Redirect URI: https://keycloak.mireu.xyz/realms/researchope/broker/google/endpoint"
echo "  Configure at: https://console.cloud.google.com/apis/credentials"
echo ""
echo "Configured OAuth Clients (Master Admin - Google OAuth):"
echo "  1. jupyterhub - https://jupyter.mireu.xyz"
echo "  2. grafana - https://grafana.mireu.xyz"
echo ""
echo "Configured Service Accounts (Token-based Access):"
echo "  3. spark - Token for Spark API access"
echo "  4. hdfs - Token for HDFS API access"
echo "  5. postgres - Token for PostgreSQL access"
echo ""
echo "JWT Middlewares deployed for *.mireu.xyz domain:"
echo "  - jwt-auth: JWT token validation"
echo "  - security-headers: Security headers"
echo "  - rate-limit: Rate limiting"
echo "  - cors-headers: CORS configuration"
echo ""
echo "Retrieve client secrets:"
echo "  kubectl get secret -n keycloak | grep oauth-secret"
echo "  kubectl get secret jupyterhub-oauth-secret -n keycloak -o jsonpath='{.data.client-secret}' | base64 -d"
echo ""
echo "Check deployment status:"
echo "  kubectl get all -n keycloak"
echo "  kubectl get keycloak -n keycloak"
echo "  kubectl get keycloakrealmimport -n keycloak"
echo ""
echo "Next steps:"
echo "  1. Access Keycloak and verify Google OAuth configuration"
echo "  2. Assign 'master-admin' role to users who need JupyterHub/Grafana access"
echo "  3. Use service account tokens for Spark, HDFS, PostgreSQL API access"
echo ""
echo "=========================================="
