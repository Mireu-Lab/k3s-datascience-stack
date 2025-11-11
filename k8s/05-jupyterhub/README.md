# JupyterHub with Google OAuth & JAX GPU

이 디렉토리는 Google OAuth 인증과 JAX GPU 지원을 포함한 JupyterHub 설정을 포함합니다.

## 주요 기능

- **Google OAuth 인증**: 단일 로그인 시스템
- **프로젝트별 네임스페이스**: 사용자/프로젝트 격리
- **3가지 프로필**:
  - Minimal (CPU Only): 가벼운 분석
  - Data Science (CPU): Spark/PostgreSQL/HDFS 포함
  - GPU + JAX: ML/DL/RL 실험용 (NVIDIA GTX 1080Ti)
- **데이터 저장소 통합**: NVME Hot, HDD Cold 자동 마운트
- **리소스 관리**: 사용자별 리소스 할당

## 사전 준비

### 1. Google OAuth 설정

Google Cloud Console에서:
1. 프로젝트 생성 또는 선택
2. "APIs & Services" > "Credentials" 이동
3. "Create Credentials" > "OAuth 2.0 Client ID" 선택
4. Application type: "Web application"
5. Authorized redirect URIs에 추가:
   ```
   https://jupyter.mireu.xyz/hub/oauth_callback
   ```
6. Client ID와 Client Secret 저장

### 2. GPU 노드 레이블 설정

```bash
# GPU가 있는 노드에 레이블 추가
kubectl label nodes <node-name> nvidia.com/gpu=true
```

### 3. JAX GPU Docker 이미지 빌드

`docker/jupyter-jax-gpu/` 디렉토리에서:

```bash
cd docker/jupyter-jax-gpu
docker build -t your-registry/jupyter-jax-gpu:latest .
docker push your-registry/jupyter-jax-gpu:latest
```

## 설치 방법

### 1. Helm Repository 추가

```bash
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update
```

### 2. Secret Token 생성

```bash
# 랜덤 토큰 생성
openssl rand -hex 32
```

생성된 값을 `values.yaml`의 `proxy.secretToken`에 설정

### 3. Secrets 설정

`secrets.yaml` 파일을 편집하여 실제 값으로 변경:
- Google OAuth Client ID
- Google OAuth Client Secret
- GCP Service Account Credentials

```bash
# Secrets 적용
kubectl apply -f secrets.yaml
```

### 4. Values 파일 수정

`values.yaml`에서 다음 항목 변경:
- `proxy.secretToken`: 생성한 토큰
- Google OAuth 설정
- 이미지 레지스트리 경로
- 노드 호스트명
- 관리자 이메일

### 5. 기존 설치 제거 (재설치 시)

```bash
helm uninstall jupyterhub -n datascience --wait
kubectl delete pvc -n datascience -l app=jupyterhub
```

### 6. JupyterHub 설치

```bash
helm install jupyterhub jupyterhub/jupyterhub \
  -f values.yaml \
  -n datascience \
  --create-namespace \
  --version 3.2.1
```

### 7. 설치 확인

```bash
# Pod 상태 확인
kubectl get pods -n datascience

# Hub 로그
kubectl logs -n datascience -l component=hub

# Proxy 로그
kubectl logs -n datascience -l component=proxy

# Ingress 확인
kubectl get ingress -n datascience
```

## 접속 방법

브라우저에서 `https://jupyter.mireu.xyz` 접속

1. "Sign in with Google" 클릭
2. Google 계정으로 로그인
3. 권한 승인
4. 서버 프로필 선택:
   - **Minimal**: 기본 Jupyter 환경
   - **Data Science**: Spark, PostgreSQL, HDFS 포함
   - **GPU + JAX**: GPU 가속 ML/DL/RL

## 사용 예제

### Spark 연동

```python
from pyspark.sql import SparkSession
import os

spark = SparkSession.builder \
    .appName("JupyterAnalysis") \
    .master(os.environ['SPARK_MASTER']) \
    .config("spark.executor.memory", "8g") \
    .getOrCreate()

# HDFS에서 데이터 읽기
df = spark.read.parquet(f"{os.environ['HDFS_NAMENODE']}/user/data/dataset.parquet")
df.show()
```

### PostgreSQL 연동

```python
import psycopg2
import os

conn = psycopg2.connect(
    host=os.environ['POSTGRES_HOST'],
    port=os.environ['POSTGRES_PORT'],
    database=os.environ['POSTGRES_DB'],
    user='datauser',
    password='changeme-user-password'
)

cursor = conn.cursor()
cursor.execute("SELECT * FROM processed_data.results LIMIT 10")
results = cursor.fetchall()
```

### HDFS 파일 접근

```python
from hdfs import InsecureClient
import os

# HDFS 클라이언트
hdfs_host = os.environ['HDFS_NAMENODE'].replace('hdfs://', 'http://').replace(':9000', ':9870')
client = InsecureClient(hdfs_host, user='jovyan')

# 파일 목록
files = client.list('/user/data/')
print(files)

# 파일 읽기
with client.read('/user/data/file.txt') as reader:
    content = reader.read()
```

### JAX GPU 사용 (GPU 프로필)

```python
import jax
import jax.numpy as jnp

# GPU 확인
print(f"Available devices: {jax.devices()}")
print(f"Default backend: {jax.default_backend()}")

# GPU 연산
x = jnp.ones((1000, 1000))
y = jnp.ones((1000, 1000))
z = jnp.dot(x, y)

print(f"Result shape: {z.shape}")
print(f"Device: {z.device()}")
```

### 데이터 저장소 접근

```python
import os

# Hot Data (NVME)
hot_data_path = '/mnt/hot-data'
print(os.listdir(hot_data_path))

# Cold Data (HDD)
cold_data_path = '/mnt/cold-data'
print(os.listdir(cold_data_path))

# 사용자 작업 공간
work_path = '/home/jovyan/work'
print(os.listdir(work_path))
```

## 사용자 관리

### 관리자 추가

`values.yaml`에서:
```python
c.Authenticator.admin_users = {'admin@mireu.xyz', 'newadmin@mireu.xyz'}
```

### 사용자 추가

```python
c.Authenticator.allowed_users = {'user1@mireu.xyz', 'user2@mireu.xyz'}
```

또는 특정 도메인 전체 허용:
```python
c.GoogleOAuthenticator.hosted_domain = ['mireu.xyz']
```

### 프로젝트별 네임스페이스

사용자가 로그인하면 자동으로 `jupyter-{username}` 네임스페이스가 생성됩니다.

```bash
# 사용자 네임스페이스 확인
kubectl get namespaces | grep jupyter-

# 특정 사용자의 Pod 확인
kubectl get pods -n jupyter-username
```

## 리소스 관리

### 프로필별 리소스

- **Minimal**: 1-2 CPU, 2-4GB RAM
- **Data Science**: 2-4 CPU, 8-16GB RAM
- **GPU + JAX**: 4-8 CPU, 16-32GB RAM, 1 GPU

### Idle Timeout

사용하지 않는 서버는 1시간 후 자동 종료:
```yaml
cull:
  timeout: 3600  # 초 단위
```

## 웹 UI 접근

### JupyterHub Admin Panel

1. JupyterHub에 관리자로 로그인
2. 상단 "Control Panel" 클릭
3. "Admin" 탭 선택

여기서 다음 작업 가능:
- 모든 사용자 목록 확인
- 사용자 서버 시작/중지
- 사용자 추가/제거

## 백업 및 복구

### 사용자 데이터 백업

```bash
# 특정 사용자의 PVC 백업
kubectl get pvc -n jupyter-username
kubectl exec -n jupyter-username <pod-name> -- tar czf /tmp/backup.tar.gz /home/jovyan/work
kubectl cp jupyter-username/<pod-name>:/tmp/backup.tar.gz ./backup.tar.gz
```

### Hub 데이터베이스 백업

```bash
kubectl exec -n datascience hub-<pod-id> -- sqlite3 /srv/jupyterhub/jupyterhub.sqlite .dump > hub-backup.sql
```

## 모니터링

### 활성 사용자 확인

```bash
kubectl get pods -n datascience -l component=singleuser-server
```

### 리소스 사용량

```bash
kubectl top pods -n datascience
```

### 로그 확인

```bash
# Hub 로그
kubectl logs -n datascience -l component=hub -f

# 특정 사용자 서버 로그
kubectl logs -n jupyter-username jupyter-username--<random-id>
```

## 문제 해결

### 로그인 실패

1. Google OAuth 설정 확인
2. Callback URL 확인: `https://jupyter.mireu.xyz/hub/oauth_callback`
3. Hub 로그 확인:
   ```bash
   kubectl logs -n datascience -l component=hub
   ```

### 서버 시작 실패

```bash
# 이벤트 확인
kubectl get events -n jupyter-username --sort-by='.lastTimestamp'

# Pod 상태 확인
kubectl describe pod -n jupyter-username <pod-name>
```

### GPU 인식 안됨

```bash
# NVIDIA Device Plugin 확인
kubectl get pods -n kube-system -l name=nvidia-device-plugin-ds

# GPU 노드 레이블 확인
kubectl get nodes --show-labels | grep nvidia
```

## 보안 고려사항

### Secrets 관리

**중요**: `secrets.yaml`을 절대 Git에 커밋하지 마세요!

```bash
# .gitignore에 추가
echo "k8s/05-jupyterhub/secrets.yaml" >> .gitignore
```

### Network Policy

네트워크 정책이 활성화되어 있어:
- storage 네임스페이스 접근 가능
- datascience 네임스페이스 접근 가능
- 외부 인터넷 접근 제한적 허용

### HTTPS/TLS

Ingress에 Let's Encrypt 인증서 자동 발급 설정:
```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
```

cert-manager가 설치되어 있어야 합니다.

## 성능 튜닝

### Hub 리소스 증가

```yaml
hub:
  resources:
    limits:
      memory: "8Gi"
      cpu: "4000m"
```

### 동시 사용자 수 증가

```yaml
scheduling:
  userScheduler:
    enabled: true
    replicas: 2
```

## 업그레이드

```bash
# 최신 차트 버전 확인
helm search repo jupyterhub/jupyterhub

# 업그레이드
helm upgrade jupyterhub jupyterhub/jupyterhub \
  -f values.yaml \
  -n datascience \
  --version <new-version>
```
