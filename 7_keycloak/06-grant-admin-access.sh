#!/bin/bash
set -e

echo "=========================================="
echo "Granting Admin Access to Google User"
echo "=========================================="

NAMESPACE="keycloak"
KEYCLOAK_URL="http://keycloak-http.${NAMESPACE}.svc.cluster.local:8080/auth"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"
GOOGLE_EMAIL="limmireu1214@gmail.com"

# Wait for Keycloak to be ready
echo ""
echo "Waiting for Keycloak to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=keycloak -n ${NAMESPACE} --timeout=300s

# Get admin token
echo ""
echo "Getting admin token..."
TOKEN=$(kubectl run keycloak-admin-grant --rm -i --restart=Never --image=curlimages/curl:latest -- \
  curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
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

# First, login with Google to create the user account
echo ""
echo "================================================================"
echo "IMPORTANT: Please login with Google account first!"
echo "================================================================"
echo ""
echo "1. Open browser: https://keycloak.mireu.xyz/auth/admin/master/console/"
echo "2. Click 'Google' button"
echo "3. Login with: ${GOOGLE_EMAIL}"
echo "4. After login completes, press Enter to continue..."
echo ""
read -p "Press Enter after you have logged in with Google..."

# Wait a bit for user creation
echo ""
echo "Waiting for user creation to sync..."
sleep 5

# Get user ID by email
echo ""
echo "Finding user by email: ${GOOGLE_EMAIL}"
USER_ID=$(kubectl run keycloak-admin-grant --rm -i --restart=Never --image=curlimages/curl:latest -- \
  curl -s -X GET "${KEYCLOAK_URL}/admin/realms/master/users?email=${GOOGLE_EMAIL}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$USER_ID" ]; then
  echo "User not found. Please make sure you have logged in with Google first."
  echo "Email: ${GOOGLE_EMAIL}"
  exit 1
fi

echo "User found: ${USER_ID}"

# Get admin role ID
echo ""
echo "Getting admin role..."
ADMIN_ROLE=$(kubectl run keycloak-admin-grant --rm -i --restart=Never --image=curlimages/curl:latest -- \
  curl -s -X GET "${KEYCLOAK_URL}/admin/realms/master/roles/admin" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json")

# Assign admin role to user
echo ""
echo "Assigning admin role to user..."
kubectl run keycloak-admin-grant --rm -i --restart=Never --image=curlimages/curl:latest -- \
  curl -s -X POST "${KEYCLOAK_URL}/admin/realms/master/users/${USER_ID}/role-mappings/realm" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "[${ADMIN_ROLE}]"

echo ""
echo "=========================================="
echo "Admin access granted successfully!"
echo "=========================================="
echo ""
echo "User: ${GOOGLE_EMAIL}"
echo "Role: admin (Master Realm)"
echo ""
echo "You can now login to Keycloak Admin Console with Google:"
echo "https://keycloak.mireu.xyz/auth/admin/master/console/"
echo ""
echo "Click 'Google' button and use ${GOOGLE_EMAIL}"
echo ""
