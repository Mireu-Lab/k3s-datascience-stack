#!/bin/bash
# PostgreSQL 및 pgAdmin 설치 스크립트

# PostgreSQL 설치
helm install postgresql oci://registry-1.docker.io/bitnamicharts/postgresql \
  --namespace postgresql \
  --create-namespace \
  --values 01-postgresql-values.yaml \
  --wait

# pgAdmin 배포
kubectl apply -f 02-pgadmin.yaml

# 설치 확인
kubectl get pods -n postgresql
kubectl get svc -n postgresql
kubectl get ingress -n postgresql

echo "PostgreSQL 및 pgAdmin 설치 완료!"
echo "pgAdmin URL: https://pg.mireu.xyz"
echo "pgAdmin 계정: admin@mireu.xyz / PgAdmin123!"
echo "PostgreSQL 접속 정보:"
echo "  Host: postgresql.postgresql.svc.cluster.local"
echo "  Port: 5432"
echo "  User: postgres"
echo "  Password: PostgresAdmin123!"
