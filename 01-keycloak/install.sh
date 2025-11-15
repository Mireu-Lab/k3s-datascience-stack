#!/bin/bash
# Keycloak 설치 스크립트

echo "Keycloak IAM 설치 시작..."

# 클라이언트 시크릿 생성
kubectl apply -f 03-keycloak-realm-import.yaml

# Keycloak 설치
helm install keycloak oci://registry-1.docker.io/bitnamicharts/keycloak \
  --namespace keycloak \
  --create-namespace \
  --values 01-keycloak-values.yaml \
  --wait

echo "Keycloak이 완전히 시작될 때까지 대기 중..."
sleep 60

# Realm 설정 ConfigMap 배포
kubectl apply -f 02-keycloak-realm.yaml

# Realm Import Job 실행
kubectl delete job keycloak-realm-import -n keycloak --ignore-not-found
kubectl apply -f 03-keycloak-realm-import.yaml

echo "Realm Import Job 실행 중..."
sleep 30

# Job 상태 확인
kubectl wait --for=condition=complete --timeout=300s job/keycloak-realm-import -n keycloak || true

# 설치 확인
kubectl get pods -n keycloak
kubectl get svc -n keycloak
kubectl get ingress -n keycloak
kubectl get job -n keycloak

echo ""
echo "================================================"
echo "Keycloak 설치 완료!"
echo "================================================"
echo ""
echo "접속 정보:"
echo "  URL: https://keycloak.mireu.xyz"
echo "  관리자 계정: admin / ChangeMe123!"
echo ""
echo "다음 단계:"
echo "1. Google OAuth 설정 (KEYCLOAK_SETUP.md 참고)"
echo "   - Google Cloud Console에서 OAuth 클라이언트 생성"
echo "   - Keycloak Clients Secret 업데이트"
echo ""
echo "2. Realm 확인"
echo "   - Realm: researchops"
echo "   - Identity Provider: Google 설정"
echo ""
echo "3. 클라이언트 Secret 업데이트"
echo "   kubectl edit secret keycloak-clients-secrets -n keycloak"
echo ""
echo "4. 토큰 생성 테스트"
echo "   python3 token-generator.py --help"
echo ""
