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

echo "Token obtained: ${TOKEN:0:20}..."

echo ""
echo "Getting JupyterHub client UUID..."
CLIENT_UUID=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
  "http://localhost:8080/auth/admin/realms/researchope/clients?clientId=jupyterhub" \
  -H "Authorization: Bearer ${TOKEN}" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$CLIENT_UUID" ]; then
  echo "Failed to get client UUID. Client might not exist."
  exit 1
fi

echo "Client UUID: $CLIENT_UUID"

echo ""
echo "Getting JupyterHub client secret..."
CLIENT_SECRET=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
  "http://localhost:8080/auth/admin/realms/researchope/clients/${CLIENT_UUID}/client-secret" \
  -H "Authorization: Bearer ${TOKEN}" | grep -o '"value":"[^"]*' | cut -d'"' -f4)

if [ -z "$CLIENT_SECRET" ]; then
  echo "Failed to get client secret"
  exit 1
fi

echo "Client Secret: $CLIENT_SECRET"

echo ""
echo "Creating Kubernetes secret..."
kubectl create secret generic jupyterhub-oauth-secret \
  --from-literal=client-id=jupyterhub \
  --from-literal=client-secret=${CLIENT_SECRET} \
  -n ${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "Secret created successfully!"
echo "You can now update JupyterHub configuration with this secret."
