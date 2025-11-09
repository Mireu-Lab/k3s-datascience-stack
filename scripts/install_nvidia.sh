#!/usr/bin/env bash
set -euo pipefail

if command -v nvidia-smi >/dev/null 2>&1; then
  echo "NVIDIA 드라이버가 이미 설치되어 있습니다.\n$(nvidia-smi)"
  exit 0
fi

if [[ $(id -u) -ne 0 ]]; then
  echo "루트로 실행하세요. 예: sudo $0"
  exit 1
fi

echo "NVIDIA 드라이버와 nvidia-container-toolkit 설치 시도"
apt-get update
apt-get install -y ca-certificates gnupg lsb-release

# NVIDIA 드라이버 PPA 또는 리포지터리는 배포판 버전에 따라 다를 수 있습니다.
# Ubuntu 24.04에서는 표준 드라이버 패키지명을 사용해 설치 시도합니다.
apt-get install -y ubuntu-drivers-common
ubuntu-drivers autoinstall || true

# NVIDIA container toolkit
distribution="$(. /etc/os-release; echo $ID$VERSION_ID)"
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update
apt-get install -y nvidia-container-toolkit
systemctl restart docker || true

echo "설치 완료. 재부팅 후 nvidia-smi로 확인하세요."
