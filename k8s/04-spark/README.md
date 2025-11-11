# Apache Spark

이 디렉토리는 데이터 처리 및 분석을 위한 Apache Spark 클러스터 설정을 포함합니다.

## 구성 요소

- **Spark Master**: 클러스터 관리 (4Gi-8Gi RAM)
- **Spark Worker**: 실제 작업 수행 (16Gi-32Gi RAM, 8 cores)
- **Spark History Server**: 작업 이력 관리
- **HDFS & PostgreSQL 연동**: 데이터 소스 통합

## 설치 방법

### 1. Helm Repository 추가

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. 기존 설치 제거 (재설치 시)

```bash
helm uninstall spark -n datascience --wait
kubectl delete pvc -n datascience -l app.kubernetes.io/name=spark
```

### 3. HDFS 로그 디렉토리 생성

```bash
# Spark 이벤트 로그 디렉토리 생성
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -mkdir -p /spark-logs
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -mkdir -p /spark-warehouse
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -chmod 777 /spark-logs
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -chmod 777 /spark-warehouse
```

### 4. Spark 설치

```bash
helm install spark bitnami/spark \
  -f values.yaml \
  -n datascience \
  --create-namespace
```

### 5. 설치 확인

```bash
# Pod 상태 확인
kubectl get pods -n datascience -l app.kubernetes.io/name=spark

# 서비스 확인
kubectl get svc -n datascience -l app.kubernetes.io/name=spark

# Master 로그
kubectl logs -n datascience -l app.kubernetes.io/component=master
```

## Spark 사용법

### Spark Shell 접속

```bash
# Scala Shell
kubectl exec -it -n datascience spark-master-0 -- spark-shell

# PySpark Shell
kubectl exec -it -n datascience spark-master-0 -- pyspark

# SparkSQL
kubectl exec -it -n datascience spark-master-0 -- spark-sql
```

### Python 스크립트 제출

```bash
kubectl exec -n datascience spark-master-0 -- \
  spark-submit \
  --master spark://spark-master-svc:7077 \
  --deploy-mode client \
  /path/to/script.py
```

### JupyterHub에서 Spark 사용

Jupyter 노트북에서:

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("DataAnalysis") \
    .master("spark://spark-master-svc.datascience.svc.cluster.local:7077") \
    .config("spark.executor.memory", "8g") \
    .config("spark.driver.memory", "4g") \
    .getOrCreate()

# HDFS에서 데이터 읽기
df = spark.read.parquet("hdfs://hadoop-namenode.storage.svc.cluster.local:9000/user/data/dataset.parquet")

# PostgreSQL에서 데이터 읽기
df_pg = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://postgresql.storage.svc.cluster.local:5432/analytics") \
    .option("dbtable", "processed_data.table_name") \
    .option("user", "datauser") \
    .option("password", "changeme-user-password") \
    .option("driver", "org.postgresql.Driver") \
    .load()

# 데이터 처리
result = df.groupBy("column").count()

# PostgreSQL에 결과 저장
result.write \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://postgresql.storage.svc.cluster.local:5432/analytics") \
    .option("dbtable", "processed_data.results") \
    .option("user", "datauser") \
    .option("password", "changeme-user-password") \
    .option("driver", "org.postgresql.Driver") \
    .mode("overwrite") \
    .save()

spark.stop()
```

### HDFS와 연동

```python
# HDFS 읽기
df = spark.read.text("hdfs://hadoop-namenode.storage.svc.cluster.local:9000/user/data/file.txt")

# HDFS 쓰기
df.write.parquet("hdfs://hadoop-namenode.storage.svc.cluster.local:9000/user/data/output.parquet")

# 이미지 파일 읽기 (바이너리)
images_df = spark.read.format("binaryFile") \
    .load("hdfs://hadoop-namenode.storage.svc.cluster.local:9000/user/data/images/")
```

## 웹 UI 접근

### Spark Master UI

```bash
kubectl port-forward -n datascience svc/spark-master-svc 8080:8080
```

브라우저: `http://localhost:8080`

### Spark History Server UI

```bash
kubectl port-forward -n datascience svc/spark-history-server-svc 18080:18080
```

브라우저: `http://localhost:18080`

### Worker UI

```bash
kubectl port-forward -n datascience svc/spark-worker-svc 8081:8081
```

브라우저: `http://localhost:8081`

## 데이터 처리 예제

### CSV 파일 처리

```python
# CSV 읽기
df = spark.read.csv("hdfs://hadoop-namenode.storage.svc.cluster.local:9000/user/data/dataset.csv", 
                    header=True, inferSchema=True)

# 데이터 변환
df_transformed = df.filter(df["value"] > 100) \
                   .groupBy("category") \
                   .agg({"value": "sum", "count": "count"})

# PostgreSQL에 저장
df_transformed.write \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://postgresql.storage.svc.cluster.local:5432/analytics") \
    .option("dbtable", "processed_data.summary") \
    .option("user", "datauser") \
    .option("password", "changeme-user-password") \
    .mode("append") \
    .save()
```

### Streaming 처리

```python
from pyspark.sql import functions as F

# Structured Streaming
df = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "kafka:9092") \
    .option("subscribe", "data-topic") \
    .load()

# 처리 및 저장
query = df.selectExpr("CAST(value AS STRING)") \
    .writeStream \
    .format("parquet") \
    .option("path", "hdfs://hadoop-namenode.storage.svc.cluster.local:9000/streaming-data") \
    .option("checkpointLocation", "/tmp/checkpoint") \
    .start()

query.awaitTermination()
```

## 성능 튜닝

### 리소스 설정

현재 Worker 설정:
- Memory: 16Gi (request) / 32Gi (limit)
- CPU: 4 cores (request) / 8 cores (limit)
- Executor Memory: 28G

### Dynamic Allocation

동적 실행자 할당이 활성화되어 있어 워크로드에 따라 자동으로 확장/축소됩니다.

```yaml
spark.dynamicAllocation.enabled: "true"
spark.dynamicAllocation.minExecutors: "1"
spark.dynamicAllocation.maxExecutors: "4"
```

### Adaptive Query Execution (AQE)

Spark 3.x의 AQE가 활성화되어 있어 쿼리 실행 계획을 자동으로 최적화합니다.

## 모니터링

### Prometheus 메트릭

ServiceMonitor가 설정되어 있어 자동으로 메트릭 수집:
- 실행 중인 작업 수
- Executor 상태
- 메모리 사용량
- 처리된 데이터 양

### 로그 확인

```bash
# Master 로그
kubectl logs -n datascience spark-master-0

# Worker 로그
kubectl logs -n datascience spark-worker-0

# History Server 로그
kubectl logs -n datascience -l app.kubernetes.io/component=history-server
```

## 문제 해결

### Out of Memory 오류

Worker 메모리 증가:
```yaml
worker:
  resources:
    limits:
      memory: "48Gi"
  extraEnvVars:
    - name: SPARK_WORKER_MEMORY
      value: "44G"
```

### 연결 문제

HDFS/PostgreSQL 연결 테스트:
```bash
# HDFS 연결 테스트
kubectl exec -n datascience spark-master-0 -- hdfs dfs -ls hdfs://hadoop-namenode.storage.svc.cluster.local:9000/

# PostgreSQL 연결 테스트
kubectl exec -n datascience spark-master-0 -- \
  spark-shell --driver-class-path /opt/bitnami/spark/jars-extra/postgresql-*.jar
```

## 보안

네트워크 정책이 활성화되어 있어 datascience와 storage 네임스페이스에서만 접근 가능합니다.

추가 보안 설정:
```yaml
spark.authenticate: "true"
spark.authenticate.secret: "your-secret-key"
```
