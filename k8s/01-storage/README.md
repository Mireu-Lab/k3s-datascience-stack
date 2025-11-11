# Storage 설정

이 디렉토리는 Kubernetes 스토리지 설정을 포함합니다.

## 구성 요소

### StorageClass
- **nvme-hot-storage**: NVME SSD 기반 Hot Data 스토리지 (2TB)
- **hdd-cold-storage**: HDD 기반 Cold Data 스토리지 (2TB)

### PersistentVolume (PV)
- **nvme-hot-pv**: NVME SSD 마운트 포인트 `/mnt/nvme/hot-data` (1800Gi)
- **hdd-cold-pv**: HDD 마운트 포인트 `/mnt/hdd/cold-data` (1800Gi)

### PersistentVolumeClaim (PVC)
- **nvme-hot-pvc**: Hot Data용 스토리지 클레임 (storage 네임스페이스)
- **hdd-cold-pvc**: Cold Data용 스토리지 클레임 (storage 네임스페이스)

## 사전 요구사항

스토리지 설정을 적용하기 전에 디스크 마운트를 설정해야 합니다:

```bash
# 디렉토리 생성
sudo mkdir -p /mnt/nvme/hot-data
sudo mkdir -p /mnt/hdd/cold-data

# 권한 설정
sudo chmod 777 /mnt/nvme/hot-data
sudo chmod 777 /mnt/hdd/cold-data
```

## 배포 방법

```bash
# 네임스페이스 먼저 생성
kubectl apply -f ../00-namespaces/namespace.yaml

# 스토리지 설정 적용
kubectl apply -f storage-class.yaml

# 확인
kubectl get storageclass
kubectl get pv
kubectl get pvc -n storage
```

## 데이터 계층 정책

- **Hot Data**: NVME SSD, 최대 2일간 보관
- **Cold Data**: HDD, 2일 후 NVME에서 이동, 1주일간 보관
- **Archive Data**: GCP Storage, 1주일 후 HDD에서 이동

데이터 이동은 CronJob을 통해 자동화됩니다 (06-data-backup 참조).
