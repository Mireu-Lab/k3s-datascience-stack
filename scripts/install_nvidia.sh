#!/usr/bin/env bash
set -euo pipefail

driver_installed=false
if command -v nvidia-smi >/dev/null 2>&1; then
  if nvidia-smi >/dev/null 2>&1; then
    driver_installed=true
  fi
fi

toolkit_installed=false
if command -v nvidia-container-runtime >/dev/null 2>&1; then
  toolkit_installed=true
fi

if [[ $(id -u) -ne 0 ]]; then
  echo "루트로 실행하세요. 예: sudo $0"
  exit 1
fi

echo "NVIDIA 설치 검사 및 필요시 설치 진행"
apt-get update
apt-get install -y ca-certificates gnupg lsb-release

if [ "$driver_installed" = true ]; then
  printf "NVIDIA 드라이버가 이미 설치되어 있습니다:\n"
  nvidia-smi || true
else
  echo "NVIDIA 드라이버가 설치되어 있지 않으므로 자동 설치를 시도합니다."
  apt-get install -y ubuntu-drivers-common
  # autoinstall은 실패해도 계속 진행
  ubuntu-drivers autoinstall || true
fi

# NVIDIA container toolkit 설치 여부 확인 후 필요하면 설치
if [ "$toolkit_installed" = true ]; then
  echo "nvidia-container-runtime(또는 toolkit)이 이미 설치되어 있습니다. 설치 건너뜁니다."
else
  echo "nvidia-container-toolkit 설치를 진행합니다."
  distribution="$(. /etc/os-release; echo $ID$VERSION_ID)"
  curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
  curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
  apt-get update
  apt-get install -y nvidia-container-toolkit
  # container runtime 재시작: docker 또는 containerd가 존재하면 재시작 시도
  if systemctl list-units --type=service --all | grep -q '^docker.service'; then
    systemctl restart docker || true
  fi
  if systemctl list-units --type=service --all | grep -q '^containerd.service'; then
    systemctl restart containerd || true
  fi
fi

echo "설치/검사 완료. 필요시 시스템 재부팅 후 'nvidia-smi'와 컨테이너 내 GPU 접근을 확인하세요."
