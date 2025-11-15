#!/bin/bash
# PostgreSQL 및 pgAdmin 제거 스크립트

echo "PostgreSQL 및 pgAdmin 제거 중..."

# pgAdmin 제거
kubectl delete -f 02-pgadmin.yaml --ignore-not-found

# PostgreSQL Helm Release 제거
helm uninstall postgresql --namespace postgresql || true

# Namespace 제거
kubectl delete namespace postgresql --ignore-not-found

echo "PostgreSQL 및 pgAdmin 제거 완료!"
echo ""
echo "참고: 데이터베이스 데이터는 PersistentVolume에 남아있을 수 있습니다."
echo "완전히 삭제하려면 PV를 수동으로 삭제하세요."
