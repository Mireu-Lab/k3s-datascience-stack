# Scripts

이 디렉토리는 K3s Data Science Stack 설치 및 관리를 위한 스크립트를 포함합니다.

## 스크립트 목록

### setup.sh
초기 시스템 설정을 수행합니다.

**수행 작업**:
- 시스템 요구사항 확인
- 디스크 마운트 확인
- 디렉토리 생성 및 권한 설정
- Helm 저장소 추가
- 네임스페이스 및 스토리지 설정
- cert-manager 설치
- NVIDIA Device Plugin 설치

**사용법**:
```bash
./scripts/setup.sh
```

### deploy.sh
모든 서비스를 배포합니다.

**배포 순서**:
1. PostgreSQL
2. Hadoop HDFS
3. Apache Spark
4. JupyterHub
5. Data Backup CronJobs
6. Ingress

**사용법**:
```bash
./scripts/deploy.sh
```

각 서비스 배포 전에 확인 프롬프트가 표시됩니다.

### uninstall.sh
모든 서비스를 제거합니다.

**제거 항목**:
- Helm releases
- PersistentVolumeClaims
- CronJobs
- Ingress
- cert-manager (선택사항)
- Namespaces (선택사항)

**사용법**:
```bash
./scripts/uninstall.sh
```

⚠️ **주의**: 데이터가 삭제될 수 있으니 백업 후 실행하세요.

### install_nvidia.sh
NVIDIA GPU 드라이버를 설치합니다.

**설치 항목**:
- NVIDIA Driver 535
- NVIDIA Container Toolkit
- K3s containerd 설정

**사용법**:
```bash
sudo ./scripts/install_nvidia.sh
```

설치 후 시스템 재부팅이 필요할 수 있습니다.

## 사용 시나리오

### 새로운 설치

```bash
# 1. NVIDIA 드라이버 설치 (GPU 사용 시)
sudo ./scripts/install_nvidia.sh
sudo reboot

# 2. 디스크 설정 (README.md 참조)

# 3. 초기 설정
./scripts/setup.sh

# 4. 설정 파일 수정
# k8s/*/values.yaml 파일들을 실제 환경에 맞게 수정

# 5. Docker 이미지 빌드 및 푸시
cd docker/jupyter-jax-gpu
docker build -t your-registry/jupyter-jax-gpu:latest .
docker push your-registry/jupyter-jax-gpu:latest

# 6. 서비스 배포
./scripts/deploy.sh
```

### 재배포

```bash
# 제거
./scripts/uninstall.sh

# 재배포
./scripts/deploy.sh
```

### 특정 서비스만 배포

```bash
# PostgreSQL만 배포
helm upgrade --install postgresql bitnami/postgresql \
  -f k8s/02-postgresql/values.yaml \
  -n storage \
  --create-namespace

# JupyterHub만 배포
helm upgrade --install jupyterhub jupyterhub/jupyterhub \
  -f k8s/05-jupyterhub/values.yaml \
  -n datascience \
  --version 3.2.1
```

## 문제 해결

### 스크립트 실행 권한 오류

```bash
chmod +x scripts/*.sh
```

### kubectl/helm 명령어 오류

```bash
# KUBECONFIG 설정
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# 또는 홈 디렉토리에 복사
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

### 디스크 마운트 오류

```bash
# 마운트 확인
mount | grep mnt

# 수동 마운트
sudo mount /dev/nvme0n1 /mnt/nvme
sudo mount /dev/sdb1 /mnt/hdd

# fstab 확인
cat /etc/fstab
```

## 스크립트 커스터마이징

스크립트는 수정하여 사용할 수 있습니다. 예를 들어:

### 자동 배포 (프롬프트 없이)

`deploy.sh`를 수정하여 모든 프롬프트를 제거할 수 있습니다:

```bash
# read -p 부분을 모두 제거하거나
# REPLY=y로 설정
```

### 추가 서비스 배포

`deploy.sh`에 새로운 서비스 배포 단계를 추가할 수 있습니다:

```bash
# 7. Custom Service 배포
print_step "7/7 Deploying Custom Service..."
helm upgrade --install myservice myrepo/mychart \
  -f k8s/custom/values.yaml \
  -n custom \
  --create-namespace
```

## 로그 및 디버깅

스크립트 실행 시 문제가 발생하면:

```bash
# 상세 로그 활성화
set -x
./scripts/setup.sh

# 또는
bash -x ./scripts/setup.sh
```

## 환경 변수

스크립트에서 사용할 수 있는 환경 변수:

```bash
# KUBECONFIG 경로
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Helm 타임아웃
export HELM_TIMEOUT=15m

# 스크립트 실행
./scripts/deploy.sh
```
