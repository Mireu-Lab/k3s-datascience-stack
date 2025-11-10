#!/bin/bash

# K3s 설치 스크립트

echo "K3s 설치 시작..."

# K3s 설치
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# kubeconfig 설정
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

# 설치 확인
echo "K3s 설치 확인 중..."
kubectl get nodes

echo "K3s 설치 완료"