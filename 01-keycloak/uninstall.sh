#!/bin/bash
# Keycloak IAM 제거 스크립트

echo "Keycloak IAM 제거 중..."

# Realm Import Job 제거
kubectl delete -f 03-keycloak-realm-import.yaml --ignore-not-found

# Realm Config 제거
kubectl delete -f 02-keycloak-realm.yaml --ignore-not-found

# Keycloak Helm Release 제거
helm uninstall keycloak --namespace keycloak || true

# Namespace 제거
kubectl delete namespace keycloak --ignore-not-found

echo "Keycloak IAM 제거 완료!"
echo ""
echo "참고: Keycloak 데이터베이스 데이터는 PersistentVolume에 남아있을 수 있습니다."
