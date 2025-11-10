# 스토리지 구성

이 디렉토리는 데이터 사이언스 스택의 스토리지 구성을 정의합니다.

## 스토리지 클래스
- `nvme-storage.yaml`: Hot Data를 위한 NVME SSD 스토리지 클래스
- `hdd-storage.yaml`: Cold Data를 위한 HDD 스토리지 클래스

## 영구 볼륨
- `nvme-pv.yaml`: NVME SSD 영구 볼륨 정의
- `hdd-pv.yaml`: HDD 영구 볼륨 정의

## 사용 안내
1. Hot Data는 NVME SSD에 저장됨 (/mnt/nvme)
2. Cold Data는 HDD에 저장됨 (/mnt/hdd)
3. 1주일 이상된 데이터는 자동으로 GCP Storage로 이전됨