#!/bin/bash
set -e

echo "=========================================="
echo "Configuring Keycloak Realm via API"
echo "=========================================="

NAMESPACE="keycloak"
KEYCLOAK_URL="http://keycloak-service.${NAMESPACE}.svc.cluster.local:8080"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

# Wait for Keycloak to be ready
echo ""
echo "Waiting for Keycloak to be ready..."
kubectl wait --for=condition=ready pod -l app=keycloak -n ${NAMESPACE} --timeout=600s

# Wait for Keycloak service to be available
echo ""
echo "Waiting for Keycloak service..."
sleep 30

# Get admin token using kubectl exec to avoid networking issues
echo ""
echo "Getting admin token..."
TOKEN=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s -X POST \
  "http://localhost:8080/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "Failed to get admin token. Please check Keycloak status."
  exit 1
fi

echo "Admin token obtained successfully."

# Note: Realm is already created via KeycloakRealmImport CRD
# This script configures Google OAuth which requires secret values

# Get Google OAuth credentials from secret
echo ""
echo "Getting Google OAuth credentials..."
GOOGLE_CLIENT_ID=$(kubectl get secret -n ${NAMESPACE} google-client-secret -o jsonpath='{.data.clientId}' | base64 -d)
GOOGLE_CLIENT_SECRET=$(kubectl get secret -n ${NAMESPACE} google-client-secret -o jsonpath='{.data.clientSecret}' | base64 -d)

# Configure Google Identity Provider for researchope realm
echo ""
echo "Configuring Google Identity Provider for researchope realm..."
kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s -X POST \
  "http://localhost:8080/admin/realms/researchope/identity-provider/instances" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"alias\": \"google\",
    \"providerId\": \"google\",
    \"enabled\": true,
    \"trustEmail\": true,
    \"storeToken\": false,
    \"addReadTokenRoleOnCreate\": false,
    \"authenticateByDefault\": false,
    \"linkOnly\": false,
    \"firstBrokerLoginFlowAlias\": \"first broker login\",
    \"config\": {
      \"clientId\": \"${GOOGLE_CLIENT_ID}\",
      \"clientSecret\": \"${GOOGLE_CLIENT_SECRET}\",
      \"defaultScope\": \"openid profile email\",
      \"syncMode\": \"IMPORT\",
      \"useJwksUrl\": \"true\",
      \"hostedDomain\": \"\"
    }
  }"

echo "Google Identity Provider configured successfully."

# Note: Roles and Clients are already created via KeycloakRealmImport CRDs
# This section retrieves and displays client secrets for configuration

echo ""
echo "=========================================="
echo "Retrieving Client Secrets"
echo "=========================================="

# Function to get client secret
get_client_secret() {
  local CLIENT_ID=$1
  echo ""
  echo "Getting ${CLIENT_ID} client secret..."
  
  # Get internal client UUID
  CLIENT_UUID=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
    "http://localhost:8080/admin/realms/researchope/clients?clientId=${CLIENT_ID}" \
    -H "Authorization: Bearer ${TOKEN}" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  
  if [ -z "$CLIENT_UUID" ]; then
    echo "Warning: Client ${CLIENT_ID} not found"
    return
  fi
  
  # Get client secret
  SECRET=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
    "http://localhost:8080/admin/realms/researchope/clients/${CLIENT_UUID}/client-secret" \
    -H "Authorization: Bearer ${TOKEN}" | grep -o '"value":"[^"]*' | cut -d'"' -f4)
  
  echo "${CLIENT_ID} secret: ${SECRET}"
  
  # Store in kubernetes secret for easy access
  kubectl create secret generic ${CLIENT_ID}-oauth-secret \
    --from-literal=client-id=${CLIENT_ID} \
    --from-literal=client-secret=${SECRET} \
    -n ${NAMESPACE} \
    --dry-run=client -o yaml | kubectl apply -f -
}

# Get secrets for all OAuth clients
get_client_secret "jupyterhub"
get_client_secret "grafana"
get_client_secret "spark"
get_client_secret "hdfs"
get_client_secret "postgres"

echo ""
echo "=========================================="
echo "Keycloak configuration completed!"
echo "=========================================="
echo ""
echo "Access Keycloak:"
echo "  URL: https://keycloak.mireu.xyz"
echo "  Admin Console: https://keycloak.mireu.xyz/admin"
echo "  Username: ${ADMIN_USER}"
echo "  Password: ${ADMIN_PASSWORD}"
echo ""
echo "Realm: researchope"
echo "  - Identity Provider: Google OAuth"
echo "  - Clients: jupyterhub, grafana, spark, hdfs, postgres"
echo "  - Roles: master-admin, data-engineer, researcher"
echo ""
echo "Client secrets have been stored in Kubernetes secrets:"
echo "  kubectl get secret -n ${NAMESPACE} | grep oauth-secret"
echo ""
echo "Google OAuth Redirect URI:"
echo "  https://keycloak.mireu.xyz/realms/researchope/broker/google/endpoint"
echo ""
