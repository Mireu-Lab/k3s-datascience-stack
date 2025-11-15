#!/bin/bash
set -e

echo "=========================================="
echo "Updating Grafana OAuth Configuration"
echo "=========================================="

NAMESPACE="keycloak"
GRAFANA_NAMESPACE="grafana"

# Get Grafana client secret from Keycloak
echo ""
echo "Retrieving Grafana client secret from Keycloak..."
CLIENT_SECRET=$(kubectl get secret grafana-oauth-secret -n ${NAMESPACE} -o jsonpath='{.data.client-secret}' 2>/dev/null | base64 -d || echo "")

if [ -z "$CLIENT_SECRET" ]; then
  echo "Error: Grafana client secret not found in keycloak namespace."
  echo "Please run 05-configure-realm.sh first to create OAuth clients and secrets."
  exit 1
fi

echo "Client secret retrieved: ${CLIENT_SECRET:0:10}..."

# Update Grafana instance YAML with client secret
echo ""
echo "Updating 5_grafana/01-grafana-instance.yaml with Keycloak OAuth configuration..."

# Create a temporary file with the updated values
sed -i "s/client_secret: \"REPLACE_WITH_GRAFANA_CLIENT_SECRET\"/client_secret: \"${CLIENT_SECRET}\"/" \
  /home/limmi/k3s-datascience-stack/5_grafana/01-grafana-instance.yaml

echo "01-grafana-instance.yaml updated successfully."

# Check if Grafana is already installed
if kubectl get grafana -n ${GRAFANA_NAMESPACE} grafana 2>/dev/null; then
  echo ""
  echo "Grafana is already installed. Applying updated configuration..."
  
  kubectl apply -f /home/limmi/k3s-datascience-stack/5_grafana/01-grafana-instance.yaml
  
  # Restart Grafana pod to apply new configuration
  echo ""
  echo "Restarting Grafana pod to apply OAuth configuration..."
  kubectl rollout restart deployment grafana-deployment -n ${GRAFANA_NAMESPACE} 2>/dev/null || \
    kubectl delete pod -l app=grafana -n ${GRAFANA_NAMESPACE}
  
  echo ""
  echo "Grafana OAuth configuration updated successfully!"
else
  echo ""
  echo "Grafana is not yet installed."
  echo "Install it with: bash 5_grafana/deploy-all.sh"
fi

echo ""
echo "=========================================="
echo "Grafana OAuth Configuration Complete!"
echo "=========================================="
echo ""
echo "Configuration Details:"
echo "  Keycloak URL: https://keycloak.mireu.xyz"
echo "  Realm: researchope"
echo "  Client ID: grafana"
echo "  Grafana URL: https://grafana.mireu.xyz"
echo ""
echo "Users can login with:"
echo "  1. Google OAuth via Keycloak (Sign in with Keycloak button)"
echo "  2. Local admin account (Username: admin, Password: admin123)"
echo ""
echo "Users in 'master-admin' group will have Admin role in Grafana."
echo "Other users will have Viewer role."
echo ""
