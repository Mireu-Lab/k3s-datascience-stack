# PostgreSQL 데이터베이스

이 디렉토리는 정형 데이터 저장을 위한 PostgreSQL 데이터베이스 설정을 포함합니다.

## 구성 요소

- **PostgreSQL 14+**: Bitnami Helm Chart 사용
- **스토리지**: NVME Hot Storage (200Gi)
- **백업**: 매일 02:00 자동 백업 (HDD Cold Storage)

## 설치 방법

### 1. Helm Repository 추가

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. 기존 설치 제거 (재설치 시)

```bash
helm uninstall postgresql -n storage --wait
kubectl delete pvc -n storage -l app.kubernetes.io/name=postgresql
```

### 3. PostgreSQL 설치

```bash
helm install postgresql bitnami/postgresql \
  -f values.yaml \
  -n storage \
  --create-namespace
```

### 4. 설치 확인

```bash
# Pod 상태 확인
kubectl get pods -n storage -l app.kubernetes.io/name=postgresql

# 서비스 확인
kubectl get svc -n storage -l app.kubernetes.io/name=postgresql

# 로그 확인
kubectl logs -n storage -l app.kubernetes.io/name=postgresql
```

## 접속 정보

### 클러스터 내부 접속

```bash
# PostgreSQL 접속
kubectl exec -it -n storage postgresql-0 -- psql -U datauser -d analytics
```

### 연결 문자열

```
Host: postgresql.storage.svc.cluster.local
Port: 5432
Database: analytics
Username: datauser
Password: (values.yaml에 설정된 비밀번호)
```

### Python에서 연결 예시

```python
import psycopg2

conn = psycopg2.connect(
    host="postgresql.storage.svc.cluster.local",
    port=5432,
    database="analytics",
    user="datauser",
    password="changeme-user-password"
)
```

## 스키마 구조

- **raw_data**: 원시 데이터 저장
- **processed_data**: 전처리된 데이터 저장
- **ml_models**: 모델 메타데이터 및 결과 저장

## 백업 및 복구

### 수동 백업

```bash
kubectl exec -n storage postgresql-0 -- pg_dump -U postgres analytics > backup.sql
```

### 복구

```bash
kubectl exec -i -n storage postgresql-0 -- psql -U postgres analytics < backup.sql
```

## 모니터링

Prometheus ServiceMonitor가 활성화되어 있어 PostgreSQL 메트릭을 자동으로 수집합니다.

```bash
# 메트릭 확인
kubectl get servicemonitor -n storage
```

## 보안 고려사항

**중요**: `values.yaml`의 비밀번호를 반드시 변경하세요!

```bash
# Secret 생성하여 비밀번호 관리
kubectl create secret generic postgresql-secrets \
  -n storage \
  --from-literal=postgres-password='YOUR_SECURE_PASSWORD' \
  --from-literal=password='YOUR_USER_PASSWORD'
```

## 성능 튜닝

현재 설정:
- Memory: 4Gi (request) / 8Gi (limit)
- CPU: 2 cores (request) / 4 cores (limit)

시스템 사용량에 따라 `values.yaml`에서 리소스를 조정하세요.
