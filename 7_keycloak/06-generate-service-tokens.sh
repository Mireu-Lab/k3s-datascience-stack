#!/bin/bash
set -e

echo "=========================================="
echo "Generating Service Account Tokens"
echo "=========================================="

NAMESPACE="keycloak"
REALM="researchope"
KEYCLOAK_URL="https://keycloak.mireu.xyz"

# Function to get service account token
get_service_token() {
  local CLIENT_ID=$1
  local CLIENT_SECRET=$2
  
  echo ""
  echo "Getting token for ${CLIENT_ID}..."
  
  TOKEN_RESPONSE=$(curl -s -X POST \
    "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials" \
    -d "client_id=${CLIENT_ID}" \
    -d "client_secret=${CLIENT_SECRET}")
  
  ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
  
  if [ -z "$ACCESS_TOKEN" ]; then
    echo "Failed to get token for ${CLIENT_ID}"
    echo "Response: $TOKEN_RESPONSE"
    return 1
  fi
  
  echo "Token obtained successfully for ${CLIENT_ID}"
  echo "Access Token: ${ACCESS_TOKEN:0:50}..."
  
  # Store token in a ConfigMap for easy access by services
  kubectl create configmap ${CLIENT_ID}-token \
    --from-literal=access-token="${ACCESS_TOKEN}" \
    -n ${NAMESPACE} \
    --dry-run=client -o yaml | kubectl apply -f -
  
  echo "Token stored in configmap/${CLIENT_ID}-token"
}

echo ""
echo "Retrieving client secrets from Kubernetes secrets..."

# Get client secrets
SPARK_SECRET=$(kubectl get secret spark-oauth-secret -n ${NAMESPACE} -o jsonpath='{.data.client-secret}' 2>/dev/null | base64 -d || echo "")
HDFS_SECRET=$(kubectl get secret hdfs-oauth-secret -n ${NAMESPACE} -o jsonpath='{.data.client-secret}' 2>/dev/null | base64 -d || echo "")
POSTGRES_SECRET=$(kubectl get secret postgres-oauth-secret -n ${NAMESPACE} -o jsonpath='{.data.client-secret}' 2>/dev/null | base64 -d || echo "")

if [ -z "$SPARK_SECRET" ] || [ -z "$HDFS_SECRET" ] || [ -z "$POSTGRES_SECRET" ]; then
  echo ""
  echo "Error: Client secrets not found. Please run 05-configure-realm.sh first."
  exit 1
fi

# Generate tokens for service accounts
get_service_token "spark" "$SPARK_SECRET"
get_service_token "hdfs" "$HDFS_SECRET"
get_service_token "postgres" "$POSTGRES_SECRET"

echo ""
echo "=========================================="
echo "Service Account Tokens Generated!"
echo "=========================================="
echo ""
echo "Tokens are stored in ConfigMaps:"
echo "  kubectl get configmap -n ${NAMESPACE} | grep token"
echo ""
echo "To use tokens in applications:"
echo "  - Spark: kubectl get configmap spark-token -n ${NAMESPACE} -o jsonpath='{.data.access-token}'"
echo "  - HDFS: kubectl get configmap hdfs-token -n ${NAMESPACE} -o jsonpath='{.data.access-token}'"
echo "  - PostgreSQL: kubectl get configmap postgres-token -n ${NAMESPACE} -o jsonpath='{.data.access-token}'"
echo ""
echo "Note: These tokens expire based on realm settings (default: 3600 seconds)"
echo "      Implement token refresh in your applications for production use."
echo ""
