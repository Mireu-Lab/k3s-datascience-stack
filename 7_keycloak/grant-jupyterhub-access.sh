#!/bin/bash
set -e

USER_EMAIL="${1:-limmireu1214@gmail.com}"
NAMESPACE="keycloak"

echo "=========================================="
echo "Adding User to master-admin Group"
echo "=========================================="
echo "User: $USER_EMAIL"
echo ""

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

echo "Getting user ID for ${USER_EMAIL}..."
USER_ID=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
  "http://localhost:8080/auth/admin/realms/researchope/users?email=${USER_EMAIL}" \
  -H "Authorization: Bearer ${TOKEN}" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$USER_ID" ]; then
  echo "User not found in researchope realm."
  echo "Please login via Google OAuth at least once to create the user account."
  exit 1
fi

echo "User ID: $USER_ID"

echo ""
echo "Getting master-admin group ID..."
GROUP_ID=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
  "http://localhost:8080/auth/admin/realms/researchope/groups?search=master-admin" \
  -H "Authorization: Bearer ${TOKEN}" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$GROUP_ID" ]; then
  echo "master-admin group not found. Creating it..."
  
  kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s -X POST \
    "http://localhost:8080/auth/admin/realms/researchope/groups" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"name": "master-admin"}'
  
  echo "Group created. Getting group ID..."
  GROUP_ID=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
    "http://localhost:8080/auth/admin/realms/researchope/groups?search=master-admin" \
    -H "Authorization: Bearer ${TOKEN}" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
fi

echo "Group ID: $GROUP_ID"

echo ""
echo "Adding user to master-admin group..."
kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s -X PUT \
  "http://localhost:8080/auth/admin/realms/researchope/users/${USER_ID}/groups/${GROUP_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"

echo ""
echo "=========================================="
echo "Success!"
echo "=========================================="
echo ""
echo "User ${USER_EMAIL} has been added to master-admin group."
echo "The user can now access JupyterHub."
echo ""
echo "Please logout and login again to apply the changes."
