#!/bin/bash
set -e

echo "=========================================="
echo "Updating JupyterHub OAuth Configuration"
echo "=========================================="

NAMESPACE="keycloak"
JUPYTERHUB_NAMESPACE="jupyterhub"

# Get JupyterHub client secret from Keycloak
echo ""
echo "Retrieving JupyterHub client secret from Keycloak..."
CLIENT_SECRET=$(kubectl get secret jupyterhub-oauth-secret -n ${NAMESPACE} -o jsonpath='{.data.client-secret}' 2>/dev/null | base64 -d || echo "")

if [ -z "$CLIENT_SECRET" ]; then
  echo "Error: JupyterHub client secret not found in keycloak namespace."
  echo "Please run 05-configure-realm.sh first to create OAuth clients and secrets."
  exit 1
fi

echo "Client secret retrieved: ${CLIENT_SECRET:0:10}..."

# Update values.yaml with client secret
echo ""
echo "Updating 4_jupyterhub/values.yaml with Keycloak OAuth configuration..."

# Create a temporary file with the updated values
sed -i "s/client_secret: \"REPLACE_WITH_JUPYTERHUB_CLIENT_SECRET\"/client_secret: \"${CLIENT_SECRET}\"/" \
  /home/limmi/k3s-datascience-stack/4_jupyterhub/values.yaml

echo "values.yaml updated successfully."

# Check if JupyterHub is already installed
if helm list -n ${JUPYTERHUB_NAMESPACE} | grep -q jupyterhub; then
  echo ""
  echo "JupyterHub is already installed. Upgrading with new configuration..."
  
  helm upgrade jupyterhub jupyterhub/jupyterhub \
    --namespace ${JUPYTERHUB_NAMESPACE} \
    -f /home/limmi/k3s-datascience-stack/4_jupyterhub/values.yaml \
    --wait
  
  echo ""
  echo "JupyterHub upgraded successfully!"
else
  echo ""
  echo "JupyterHub is not yet installed."
  echo "Install it with: bash 4_jupyterhub/00-install-jupyterhub.sh"
fi

echo ""
echo "=========================================="
echo "JupyterHub OAuth Configuration Complete!"
echo "=========================================="
echo ""
echo "Configuration Details:"
echo "  Keycloak URL: https://keycloak.mireu.xyz"
echo "  Realm: researchope"
echo "  Client ID: jupyterhub"
echo "  OAuth Callback: https://jupyter.mireu.xyz/hub/oauth_callback"
echo ""
echo "Users must login with Google OAuth via Keycloak."
echo "Only users in 'master-admin' group can access JupyterHub."
echo ""
echo "To grant admin access to a user:"
echo "  bash 7_keycloak/06-grant-admin-access.sh <email>"
echo ""
