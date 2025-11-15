# PostgreSQL 및 pgAdmin 설치 및 구성

## 공식 Helm Chart
- URL: https://github.com/bitnami/charts/tree/main/bitnami/postgresql
- Helm Repo: `oci://registry-1.docker.io/bitnamicharts/postgresql`

## 설치 명령어
```bash
helm install postgresql oci://registry-1.docker.io/bitnamicharts/postgresql \
  --namespace postgresql \
  --values 01-postgresql-values.yaml

kubectl apply -f 02-pgadmin.yaml
```

## 주요 기능
1. 프로젝트별 데이터베이스 자동 생성
2. Keycloak을 통한 데이터베이스 접근 권한 관리
3. pgAdmin WebUI를 통한 데이터베이스 관리

## WebUI 접근
- pgAdmin: https://pg.mireu.xyz
