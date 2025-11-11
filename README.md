# K3s Data Science Stack

단일 서버 환경에서 데이터 분석 및 ML/DL/RL 실험을 위한 완전한 Kubernetes 기반 플랫폼입니다.

## 🎯 주요 기능

- **JupyterHub**: Google OAuth 인증 기반 통합 로그인 시스템
- **Apache Spark**: 분산 데이터 처리 및 분석
- **PostgreSQL**: 정형 데이터 저장
- **Apache Hadoop HDFS**: 비정형 데이터 저장 (이미지, 비디오, 오디오)
- **JAX GPU**: NVIDIA GPU 가속 ML/DL/RL 프레임워크
- **자동 백업**: Hot → Cold → Archive 데이터 계층화
- **HTTPS Ingress**: Let's Encrypt 자동 SSL 인증서

## 🖥️ 시스템 요구사항

### 하드웨어
- **CPU**: Intel Xeon E5-2666 v3
- **RAM**: 96GB (DDR4 2666MHz)
- **Storage**:
  - OS: 480GB SATA SSD
  - Hot Data: 2TB NVMe SSD (`/mnt/nvme`)
  - Cold Data: 2TB HDD (`/mnt/hdd`)
- **GPU**: NVIDIA GTX 1080Ti 11GB
- **Network**: 1Gbps Ethernet

### 소프트웨어
- Ubuntu 24.04.02 LTS
- K3s (containerd runtime)
- NVIDIA Driver 535+
- Helm 3.x
- kubectl

## 📁 프로젝트 구조

```
k3s-datascience-stack/
├── k8s/
│   ├── 00-namespaces/        # Kubernetes 네임스페이스
│   ├── 01-storage/            # 스토리지 클래스 및 PV/PVC
│   ├── 02-postgresql/         # PostgreSQL 데이터베이스
│   ├── 03-hadoop/             # Hadoop HDFS
│   ├── 04-spark/              # Apache Spark
│   ├── 05-jupyterhub/         # JupyterHub + Google OAuth
│   ├── 06-data-backup/        # 자동 백업 CronJobs
│   └── 07-ingress/            # Ingress 및 SSL 설정
├── docker/
│   └── jupyter-jax-gpu/       # JAX GPU Docker 이미지
├── scripts/
│   ├── setup.sh               # 초기 설정 스크립트
│   ├── deploy.sh              # 배포 스크립트
│   ├── uninstall.sh           # 제거 스크립트
│   └── install_nvidia.sh      # NVIDIA 드라이버 설치
└── README.md
```

## 🚀 빠른 시작

### 1. 사전 준비

#### K3s 설치

```bash
curl -sfL https://get.k3s.io | sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

#### Helm 설치

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### NVIDIA 드라이버 설치

```bash
cd scripts
sudo ./install_nvidia.sh
```

### 2. 디스크 설정

```bash
# NVME SSD 마운트
sudo mkfs.ext4 /dev/nvme0n1  # 주의: 데이터가 삭제됩니다!
sudo mkdir -p /mnt/nvme
sudo mount /dev/nvme0n1 /mnt/nvme
echo '/dev/nvme0n1 /mnt/nvme ext4 defaults 0 2' | sudo tee -a /etc/fstab

# HDD 마운트
sudo mkfs.ext4 /dev/sdb1  # 주의: 데이터가 삭제됩니다!
sudo mkdir -p /mnt/hdd
sudo mount /dev/sdb1 /mnt/hdd
echo '/dev/sdb1 /mnt/hdd ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

### 3. 초기 설정

```bash
./scripts/setup.sh
```

이 스크립트는 다음을 수행합니다:
- 필요한 디렉토리 생성
- Helm 저장소 추가
- Kubernetes 네임스페이스 생성
- 스토리지 클래스 설정
- cert-manager 설치
- NVIDIA Device Plugin 설치

### 4. 설정 파일 수정

각 서비스의 `values.yaml` 파일을 실제 환경에 맞게 수정하세요:

#### PostgreSQL (`k8s/02-postgresql/values.yaml`)
```yaml
global:
  postgresql:
    auth:
      postgresPassword: "YOUR_SECURE_PASSWORD"
      password: "YOUR_SECURE_PASSWORD"
```

#### JupyterHub (`k8s/05-jupyterhub/values.yaml`)
```yaml
proxy:
  secretToken: "GENERATE_WITH_openssl_rand_hex_32"

extraConfig:
  00-oauth: |
    c.GoogleOAuthenticator.client_id = 'YOUR_GOOGLE_CLIENT_ID'
    c.GoogleOAuthenticator.client_secret = 'YOUR_GOOGLE_CLIENT_SECRET'
```

#### Secrets (`k8s/05-jupyterhub/secrets.yaml`)
```yaml
stringData:
  client-id: "YOUR_GOOGLE_CLIENT_ID"
  client-secret: "YOUR_GOOGLE_CLIENT_SECRET"
  credentials.json: |
    {
      "type": "service_account",
      ...
    }
```

#### Ingress (`k8s/07-ingress/ingress.yaml`)
```yaml
email: your-email@mireu.xyz  # Let's Encrypt 알림용
```

### 5. Docker 이미지 빌드 및 푸시

```bash
cd docker/jupyter-jax-gpu

# 빌드
docker build -t ghcr.io/mireu-lab/jupyter-jax-gpu:latest .

# GitHub Container Registry 로그인
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# 푸시
docker push ghcr.io/mireu-lab/jupyter-jax-gpu:latest
```

`k8s/05-jupyterhub/values.yaml`에서 이미지 경로 업데이트:
```yaml
kubespawner_override:
  'image': 'ghcr.io/mireu-lab/jupyter-jax-gpu:latest'
```

### 6. 서비스 배포

```bash
./scripts/deploy.sh
```

이 스크립트는 순차적으로 다음을 배포합니다:
1. PostgreSQL
2. Hadoop HDFS
3. Apache Spark
4. JupyterHub
5. Data Backup CronJobs
6. Ingress

### 7. DNS 설정 (CloudFlare)

CloudFlare 대시보드에서 다음 A 레코드를 추가하세요:

| Type | Name | Content | Proxy Status | TTL |
|------|------|---------|--------------|-----|
| A | jupyter | YOUR_SERVER_IP | DNS only | Auto |
| A | spark | YOUR_SERVER_IP | DNS only | Auto |
| A | spark-history | YOUR_SERVER_IP | DNS only | Auto |
| A | hadoop | YOUR_SERVER_IP | DNS only | Auto |

**중요**: Proxy Status를 "DNS only"로 설정 (Let's Encrypt HTTP-01 challenge를 위해)

### 8. 인증서 발급 확인

```bash
# Certificate 상태 확인
kubectl get certificate -A

# cert-manager 로그 확인
kubectl logs -n cert-manager -l app=cert-manager -f
```

## 🌐 접속 정보

### 서비스 URL

| 서비스 | URL | 인증 |
|--------|-----|------|
| JupyterHub | https://jupyter.mireu.xyz | Google OAuth |
| Spark Master | https://spark.mireu.xyz | Basic Auth |
| Spark History | https://spark-history.mireu.xyz | Basic Auth |
| Hadoop NameNode | https://hadoop.mireu.xyz | Basic Auth |

### 기본 자격 증명

**⚠️ 보안상 반드시 변경하세요!**

- Spark/Hadoop Basic Auth: `admin` / `admin`

## 📊 데이터 계층 관리

### 자동 백업 정책

| 계층 | 저장소 | 기간 | 압축 | 스케줄 |
|------|--------|------|------|--------|
| **Hot** | NVME SSD (2TB) | 최대 2일 | 없음 | - |
| **Cold** | HDD (2TB) | 2일~1주일 | gzip | 매일 02:00 |
| **Archive** | GCP Storage | 1주일 이상 | gzip | 매주 일요일 03:00 |

### 수동 백업 실행

```bash
# Hot to Cold 백업
kubectl create job -n storage \
  --from=cronjob/hot-to-cold-backup \
  hot-to-cold-manual-$(date +%s)

# Cold to Archive 백업
kubectl create job -n storage \
  --from=cronjob/cold-to-archive-backup \
  cold-to-archive-manual-$(date +%s)
```

## 📝 사용 예제

### JupyterHub에서 Spark 사용

```python
from pyspark.sql import SparkSession
import os

spark = SparkSession.builder \
    .appName("DataAnalysis") \
    .master(os.environ['SPARK_MASTER']) \
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
    password='your-password'
)
```

### JAX GPU 사용

```python
import jax
import jax.numpy as jnp

# GPU 확인
print(f"Available devices: {jax.devices()}")

# GPU 연산
x = jnp.ones((1000, 1000))
y = jnp.dot(x, x)
print(f"Result device: {y.device()}")
```

## 🔧 관리 및 모니터링

### Pod 상태 확인

```bash
# 모든 네임스페이스의 Pod
kubectl get pods -A

# 특정 네임스페이스
kubectl get pods -n datascience
kubectl get pods -n storage
```

### 로그 확인

```bash
# JupyterHub Hub
kubectl logs -n datascience -l component=hub -f

# Spark Master
kubectl logs -n datascience -l app.kubernetes.io/component=master -f

# PostgreSQL
kubectl logs -n storage -l app.kubernetes.io/name=postgresql -f

# Hadoop NameNode
kubectl logs -n storage hadoop-namenode-0 -f
```

### 리소스 사용량

```bash
# 노드 리소스
kubectl top nodes

# Pod 리소스
kubectl top pods -A
```

### 스토리지 사용량

```bash
# PVC 상태
kubectl get pvc -A

# 실제 디스크 사용량
df -h /mnt/nvme
df -h /mnt/hdd
```

## 🔒 보안

### 비밀번호 변경

#### Basic Auth 비밀번호

```bash
# 새 비밀번호 생성
htpasswd -nb admin NEW_PASSWORD | base64

# Secret 업데이트
kubectl edit secret spark-basic-auth -n datascience
kubectl edit secret hadoop-basic-auth -n storage
```

#### PostgreSQL 비밀번호

```bash
kubectl create secret generic postgresql-secrets \
  -n storage \
  --from-literal=postgres-password='NEW_PASSWORD' \
  --from-literal=password='NEW_PASSWORD' \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Secrets 관리

**중요**: `secrets.yaml` 파일을 Git에 커밋하지 마세요!

```bash
echo "k8s/05-jupyterhub/secrets.yaml" >> .gitignore
```

## 🐛 문제 해결

### GPU 인식 안 됨

```bash
# 호스트에서 GPU 확인
nvidia-smi

# NVIDIA Device Plugin 확인
kubectl get pods -n kube-system -l name=nvidia-device-plugin-ds

# GPU 노드 레이블 확인
kubectl get nodes --show-labels | grep nvidia
```

### 인증서 발급 실패

```bash
# Challenge 확인
kubectl get challenges -A

# cert-manager 로그
kubectl logs -n cert-manager -l app=cert-manager --tail=100

# CloudFlare Proxy 비활성화 확인
# DNS only 모드로 설정되어 있어야 함
```

### Spark 작업 실패

```bash
# Spark Master 로그
kubectl logs -n datascience spark-master-0

# Worker 로그
kubectl logs -n datascience spark-worker-0

# HDFS 연결 확인
kubectl exec -n datascience spark-master-0 -- \
  hdfs dfs -ls hdfs://hadoop-namenode.storage.svc.cluster.local:9000/
```

### PostgreSQL 연결 실패

```bash
# PostgreSQL Pod 상태
kubectl get pods -n storage -l app.kubernetes.io/name=postgresql

# PostgreSQL 로그
kubectl logs -n storage postgresql-0

# 연결 테스트
kubectl exec -it -n storage postgresql-0 -- psql -U datauser -d analytics
```

## 🔄 업데이트 및 유지보수

### 서비스 업그레이드

```bash
# Helm 차트 업데이트
helm repo update

# 특정 서비스 업그레이드
helm upgrade jupyterhub jupyterhub/jupyterhub \
  -f k8s/05-jupyterhub/values.yaml \
  -n datascience \
  --version NEW_VERSION
```

### 백업

```bash
# 모든 Kubernetes 리소스 백업
kubectl get all -A -o yaml > k8s-backup.yaml

# Helm releases 백업
helm list -A -o yaml > helm-releases.yaml

# PVC 데이터 백업 (rsync 사용)
sudo rsync -av /mnt/nvme/hot-data/ /backup/nvme/
sudo rsync -av /mnt/hdd/cold-data/ /backup/hdd/
```

## 📚 추가 문서

각 컴포넌트의 상세 문서는 해당 디렉토리의 README.md를 참조하세요:

- [Storage 설정](k8s/01-storage/README.md)
- [PostgreSQL](k8s/02-postgresql/README.md)
- [Apache Hadoop](k8s/03-hadoop/README.md)
- [Apache Spark](k8s/04-spark/README.md)
- [JupyterHub](k8s/05-jupyterhub/README.md)
- [Data Backup](k8s/06-data-backup/README.md)
- [Ingress](k8s/07-ingress/README.md)
- [JAX GPU Docker Image](docker/jupyter-jax-gpu/README.md)

## 🗑️ 제거

전체 스택을 제거하려면:

```bash
./scripts/uninstall.sh
```

데이터도 삭제하려면:

```bash
sudo rm -rf /mnt/nvme/hot-data/*
sudo rm -rf /mnt/hdd/cold-data/*
```

## 🤝 기여

이 프로젝트는 Mireu Lab에서 관리합니다.

## 📄 라이선스

MIT License

## 📧 지원

문의사항이 있으시면 admin@mireu.xyz로 연락주세요.

---

**Mireu Lab** - Data Science Infrastructure
