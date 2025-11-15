#!/bin/bash
set -e

echo "=========================================="
echo "Creating OAuth2-Proxy Client in Keycloak"
echo "=========================================="

NAMESPACE="keycloak"
KEYCLOAK_URL="http://keycloak-http.${NAMESPACE}.svc.cluster.local:8080/auth"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

# Get admin token
echo "Getting admin token..."
TOKEN=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s -X POST \
  "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "Failed to get admin token"
  exit 1
fi

echo "Creating oauth2-proxy client..."

# Create oauth2-proxy client
CLIENT_RESPONSE=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s -X POST \
  "${KEYCLOAK_URL}/admin/realms/researchope/clients" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "oauth2-proxy",
    "name": "OAuth2 Proxy",
    "description": "OAuth2 Proxy for unified authentication across all services",
    "enabled": true,
    "publicClient": false,
    "protocol": "openid-connect",
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": false,
    "serviceAccountsEnabled": false,
    "redirectUris": [
      "https://auth.mireu.xyz/oauth2/callback",
      "https://spark.mireu.xyz/*",
      "https://hdfs.mireu.xyz/*",
      "https://pg.mireu.xyz/*",
      "https://jupyter.mireu.xyz/*",
      "https://grafana.mireu.xyz/*"
    ],
    "webOrigins": [
      "https://auth.mireu.xyz",
      "https://spark.mireu.xyz",
      "https://hdfs.mireu.xyz",
      "https://pg.mireu.xyz",
      "https://jupyter.mireu.xyz",
      "https://grafana.mireu.xyz"
    ],
    "attributes": {
      "access.token.lifespan": "3600",
      "user.info.response.signature.alg": "RS256"
    }
  }')

# Get client secret
echo ""
echo "Retrieving client secret..."
sleep 2

CLIENT_SECRET=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
  "${KEYCLOAK_URL}/admin/realms/researchope/clients?clientId=oauth2-proxy" \
  -H "Authorization: Bearer ${TOKEN}" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$CLIENT_SECRET" ]; then
  echo "Failed to get client ID"
  exit 1
fi

SECRET=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
  "${KEYCLOAK_URL}/admin/realms/researchope/clients/${CLIENT_SECRET}/client-secret" \
  -H "Authorization: Bearer ${TOKEN}" | grep -o '"value":"[^"]*' | cut -d'"' -f4)

echo ""
echo "=========================================="
echo "OAuth2-Proxy Client Created Successfully!"
echo "=========================================="
echo ""
echo "Client ID: oauth2-proxy"
echo "Client Secret: ${SECRET}"
echo ""
echo "Update the oauth2-proxy-values.yaml with this secret:"
echo "  clientSecret: \"${SECRET}\""
echo ""
echo "Then run:"
echo "  bash 7_keycloak/07-install-oauth2-proxy.sh"
echo ""
