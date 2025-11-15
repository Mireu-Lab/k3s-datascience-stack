#!/bin/bash
# 네임스페이스 및 스토리지 제거 스크립트

echo "네임스페이스 및 스토리지 제거 중..."

# 스토리지 클래스 및 PV 제거
kubectl delete -f 01-storage-pv.yaml --ignore-not-found

# 네임스페이스 제거
kubectl delete -f 00-namespaces.yaml --ignore-not-found

echo "네임스페이스 및 스토리지 제거 완료!"
