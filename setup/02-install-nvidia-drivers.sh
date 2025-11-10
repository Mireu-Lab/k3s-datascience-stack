#!/bin/bash

# NVIDIA 드라이버 및 컨테이너 툴킷 설치 스크립트

echo "NVIDIA 드라이버 설치 시작..."

# 기존 NVIDIA 드라이버 제거
sudo apt-get purge -y nvidia*

# NVIDIA 드라이버 설치
sudo apt-get update
sudo apt-get install -y nvidia-driver-535

# NVIDIA Container Toolkit 설치
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# containerd 설정
sudo nvidia-ctk runtime configure --runtime=containerd
sudo systemctl restart containerd

echo "NVIDIA 드라이버 설치 완료"