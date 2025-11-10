#!/bin/bash

# 시스템 준비 스크립트

echo "시스템 준비 시작..."

# 기존 설치 제거
echo "기존 설치 제거 중..."
sudo systemctl stop k3s || true
sudo /usr/local/bin/k3s-uninstall.sh || true
sudo rm -rf /var/lib/rancher/k3s || true

# 디스크 파티션 재설정
echo "디스크 파티션 설정 중..."
sudo umount /mnt/nvme || true
sudo umount /mnt/hdd || true

# NVME 디스크 설정
echo "NVME 디스크 파티션 생성 중..."
sudo parted /dev/nvme0n1 mklabel gpt
sudo parted /dev/nvme0n1 mkpart primary ext4 0% 100%
sudo mkfs.ext4 /dev/nvme0n1p1

# HDD 디스크 설정
echo "HDD 디스크 파티션 생성 중..."
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary ext4 0% 100%
sudo mkfs.ext4 /dev/sdb1

# 마운트 포인트 생성
echo "마운트 포인트 생성 중..."
sudo mkdir -p /mnt/nvme
sudo mkdir -p /mnt/hdd

# fstab 설정
echo "fstab 설정 중..."
echo "/dev/nvme0n1p1  /mnt/nvme  ext4  defaults  0  0" | sudo tee -a /etc/fstab
echo "/dev/sdb1       /mnt/hdd   ext4  defaults  0  0" | sudo tee -a /etc/fstab

# 마운트
echo "디스크 마운트 중..."
sudo mount -a

echo "시스템 준비 완료"