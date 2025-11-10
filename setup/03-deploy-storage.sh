#!/bin/bash

# 스토리지 설정 스크립트

echo "스토리지 설정 시작..."

# 네임스페이스 생성
kubectl apply -f ./k8s/namespace/datascience.yaml

# 스토리지 클래스 및 PV 생성
kubectl apply -f ./k8s/storage/nvme-storage.yaml
kubectl apply -f ./k8s/storage/hdd-storage.yaml

# 설정 확인
echo "스토리지 설정 확인 중..."
kubectl get sc
kubectl get pv

echo "스토리지 설정 완료"