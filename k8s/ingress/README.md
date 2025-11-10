# 인그레스 구성

이 디렉토리는 데이터 사이언스 스택의 외부 접근을 위한 인그레스 설정을 포함합니다.

## 구성 요소
- `ingress.yaml`: 기본 인그레스 설정
- `cert-manager.yaml`: SSL 인증서 관리자 설정

## 도메인 구성
- JupyterHub: jupyter.mireu.xyz
- Spark UI: spark.mireu.xyz
- Hadoop UI: hadoop.mireu.xyz
- PostgreSQL: postgresql.mireu.xyz

## SSL 설정
- CloudFlare를 통한 DNS 관리
- Let's Encrypt 인증서 자동 발급