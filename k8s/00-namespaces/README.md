# 네임스페이스 설정

이 디렉토리는 Kubernetes 네임스페이스 설정을 포함합니다.

## 네임스페이스 구조

### datascience
데이터 분석 및 ML/DL/RL 작업을 위한 네임스페이스입니다.

**포함된 서비스**:
- JupyterHub (통합 로그인 및 개발 환경)
- Apache Spark (데이터 처리)

### storage
데이터 저장 및 관리를 위한 네임스페이스입니다.

**포함된 서비스**:
- PostgreSQL (정형 데이터)
- Apache Hadoop HDFS (비정형 데이터)
- Data Backup CronJobs

### monitoring
시스템 모니터링을 위한 네임스페이스입니다 (추후 확장).

**포함될 서비스**:
- Prometheus
- Grafana
- AlertManager

## 배포

```bash
kubectl apply -f namespace.yaml
```

## 확인

```bash
kubectl get namespaces
```

## 네임스페이스 간 통신

네트워크 정책을 통해 다음과 같이 통신이 제어됩니다:
- `datascience` ↔ `storage`: 허용
- `monitoring` → 모든 네임스페이스: 허용 (메트릭 수집)
- 외부 → `datascience`: Ingress를 통해서만 허용
