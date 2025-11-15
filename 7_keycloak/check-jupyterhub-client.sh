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

echo "Getting JupyterHub client UUID..."
CLIENT_UUID=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
  "http://localhost:8080/auth/admin/realms/researchope/clients?clientId=jupyterhub" \
  -H "Authorization: Bearer ${TOKEN}" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

echo "Client UUID: $CLIENT_UUID"
echo ""
echo "Getting JupyterHub client configuration..."

kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
  "http://localhost:8080/auth/admin/realms/researchope/clients/${CLIENT_UUID}" \
  -H "Authorization: Bearer ${TOKEN}" > /tmp/jupyterhub-client.json

echo "Redirect URIs:"
cat /tmp/jupyterhub-client.json | python3 -c "import sys, json; data=json.load(sys.stdin); print(json.dumps(data.get('redirectUris', []), indent=2))"

echo ""
echo "Web Origins:"
cat /tmp/jupyterhub-client.json | python3 -c "import sys, json; data=json.load(sys.stdin); print(json.dumps(data.get('webOrigins', []), indent=2))"

echo ""
echo "Access Type:"
cat /tmp/jupyterhub-client.json | python3 -c "import sys, json; data=json.load(sys.stdin); print('publicClient:', data.get('publicClient', False))"

echo ""
echo "Service Account Enabled:"
cat /tmp/jupyterhub-client.json | python3 -c "import sys, json; data=json.load(sys.stdin); print('serviceAccountsEnabled:', data.get('serviceAccountsEnabled', False))"
