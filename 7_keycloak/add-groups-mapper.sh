#!/bin/bash
set -e

NAMESPACE="keycloak"

echo "Getting admin token..."
TOKEN=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s -X POST \
  "http://localhost:8080/auth/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "Failed to get admin token"
  exit 1
fi

echo "Getting JupyterHub client UUID..."
CLIENT_UUID=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
  "http://localhost:8080/auth/admin/realms/researchope/clients?clientId=jupyterhub" \
  -H "Authorization: Bearer ${TOKEN}" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

echo "Client UUID: $CLIENT_UUID"

echo ""
echo "Adding groups mapper to JupyterHub client..."

kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s -X POST \
  "http://localhost:8080/auth/admin/realms/researchope/clients/${CLIENT_UUID}/protocol-mappers/models" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "groups",
    "protocol": "openid-connect",
    "protocolMapper": "oidc-group-membership-mapper",
    "consentRequired": false,
    "config": {
      "full.path": "false",
      "id.token.claim": "true",
      "access.token.claim": "true",
      "userinfo.token.claim": "true",
      "claim.name": "groups"
    }
  }'

echo ""
echo "Groups mapper added successfully!"
