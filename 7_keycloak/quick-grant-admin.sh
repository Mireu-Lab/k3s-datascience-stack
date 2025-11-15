#!/bin/bash
# Quick admin grant - no user interaction needed

NAMESPACE="keycloak"
EMAIL="limmireu1214@gmail.com"

echo "Granting admin access to: ${EMAIL}"

# Get admin token
TOKEN=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s -X POST \
  "http://localhost:8080/auth/realms/master/protocol/openid-connect/token" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "Failed to get token"
  exit 1
fi

# Get user ID
USER_ID=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
  "http://localhost:8080/auth/admin/realms/master/users?email=${EMAIL}" \
  -H "Authorization: Bearer ${TOKEN}" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$USER_ID" ]; then
  echo "User not found: ${EMAIL}"
  echo "Please login with Google first at: https://keycloak.mireu.xyz/auth/admin/master/console/"
  exit 1
fi

echo "Found user ID: ${USER_ID}"

# Get admin role
ADMIN_ROLE=$(kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s \
  "http://localhost:8080/auth/admin/realms/master/roles/admin" \
  -H "Authorization: Bearer ${TOKEN}")

# Assign admin role
kubectl exec -n ${NAMESPACE} keycloak-0 -- curl -s -X POST \
  "http://localhost:8080/auth/admin/realms/master/users/${USER_ID}/role-mappings/realm" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "[${ADMIN_ROLE}]"

echo ""
echo "✓ Admin access granted to: ${EMAIL}"
echo "You can now login at: https://keycloak.mireu.xyz/auth/admin/master/console/"
