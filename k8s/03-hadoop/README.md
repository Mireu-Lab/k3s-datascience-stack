# Apache Hadoop HDFS

이 디렉토리는 비정형 데이터 저장을 위한 Apache Hadoop HDFS 설정을 포함합니다.

## 구성 요소

- **NameNode**: HDFS 메타데이터 관리 (100Gi NVME)
- **DataNode**: 실제 데이터 저장 (800Gi NVME)
- **Replication Factor**: 1 (단일 노드 구성)

## 사용 목적

비정형 데이터 저장:
- 이미지 파일 (JPG, PNG, etc.)
- 오디오 파일 (MP3, WAV, etc.)
- 비디오 파일 (MP4, AVI, etc.)
- 기타 대용량 바이너리 파일

## 설치 방법

### 1. Helm Repository 추가

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. 기존 설치 제거 (재설치 시)

```bash
helm uninstall hadoop -n storage --wait
kubectl delete pvc -n storage -l app.kubernetes.io/name=hadoop
```

### 3. Hadoop HDFS 설치

```bash
helm install hadoop bitnami/hadoop \
  -f values.yaml \
  -n storage \
  --create-namespace
```

### 4. 설치 확인

```bash
# Pod 상태 확인
kubectl get pods -n storage -l app.kubernetes.io/name=hadoop

# 서비스 확인
kubectl get svc -n storage -l app.kubernetes.io/name=hadoop

# HDFS 상태 확인
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfsadmin -report
```

## HDFS 사용법

### 기본 명령어

```bash
# HDFS에 파일 업로드
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -put /local/file /hdfs/path

# HDFS에서 파일 다운로드
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -get /hdfs/path /local/file

# 파일 목록 조회
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -ls /

# 디렉토리 생성
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -mkdir -p /user/data/images

# 파일 삭제
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -rm /hdfs/path/file
```

### Python에서 사용

```python
from hdfs import InsecureClient

# HDFS 클라이언트 생성
client = InsecureClient('http://hadoop-namenode.storage.svc.cluster.local:9870', user='hadoop')

# 파일 업로드
client.upload('/user/data/image.jpg', '/local/path/image.jpg')

# 파일 다운로드
client.download('/user/data/image.jpg', '/local/path/image.jpg')

# 파일 목록
files = client.list('/user/data/')
```

### PySpark에서 HDFS 읽기

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("HDFS Reader") \
    .config("spark.hadoop.fs.defaultFS", "hdfs://hadoop-namenode:9000") \
    .getOrCreate()

# 텍스트 파일 읽기
df = spark.read.text("hdfs://hadoop-namenode:9000/user/data/file.txt")

# 이미지 읽기 (바이너리)
df = spark.read.format("binaryFile").load("hdfs://hadoop-namenode:9000/user/data/images/")
```

## 웹 UI 접근

### NameNode Web UI

```bash
# 포트 포워딩
kubectl port-forward -n storage svc/hadoop-namenode 9870:9870
```

브라우저에서 `http://localhost:9870` 접속

### DataNode Web UI

```bash
# 포트 포워딩
kubectl port-forward -n storage svc/hadoop-datanode 9864:9864
```

브라우저에서 `http://localhost:9864` 접속

## 디렉토리 구조 권장사항

```
/user
  /project1
    /raw
      /images
      /audio
      /video
    /processed
  /project2
    /raw
      /images
    /processed
  /shared
    /datasets
```

## 성능 최적화

### 블록 크기
현재 설정: 128MB (대용량 파일에 적합)

작은 파일이 많은 경우:
```yaml
dfs.blocksize: "67108864"  # 64MB
```

### 데이터 노드 스레드
현재 설정: 4096 (동시 전송 스레드)

## 백업 전략

HDFS 데이터는 데이터 백업 CronJob에 의해 자동으로:
- 2일 후: HDD로 이동 (Cold Storage)
- 1주일 후: GCP Storage로 아카이브

수동 백업:
```bash
# 스냅샷 생성
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfsadmin -allowSnapshot /user
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfs -createSnapshot /user snapshot-$(date +%Y%m%d)
```

## 모니터링

Prometheus ServiceMonitor를 통해 자동으로 메트릭 수집:
- HDFS 용량 사용률
- Block 수
- DataNode 상태
- I/O 성능

## 문제 해결

### Safe Mode 해제

```bash
kubectl exec -n storage hadoop-namenode-0 -- hdfs dfsadmin -safemode leave
```

### NameNode 포맷 (데이터 삭제 주의!)

```bash
kubectl exec -n storage hadoop-namenode-0 -- hdfs namenode -format
```

### 로그 확인

```bash
kubectl logs -n storage hadoop-namenode-0
kubectl logs -n storage hadoop-datanode-0
```
