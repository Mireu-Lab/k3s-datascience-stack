#!/bin/bash
set -e

# KUBECONFIG 설정
export KUBECONFIG=/home/limmi/k3s-datascience-stack/k3s.yaml

echo "=== Stackable HDFS Operator 설치 (공식 Helm 차트) ==="
echo "참조: https://github.com/stackabletech/hdfs-operator"

# Stackable Helm Repository 추가
echo "Helm Repository 추가..."
helm repo add stackable-stable https://repo.stackable.tech/repository/helm-stable/
helm repo update

# Namespace 생성
echo "Namespace 생성..."
kubectl create namespace stackable-operators --dry-run=client -o yaml | kubectl apply -f -

# Commons Operator 설치 (필수 의존성)
echo "Commons Operator 설치..."
helm upgrade --install commons-operator stackable-stable/commons-operator \
  --version 24.11.0 \
  --namespace stackable-operators \
  --wait

# Secret Operator 설치 (필수 의존성)
echo "Secret Operator 설치..."
helm upgrade --install secret-operator stackable-stable/secret-operator \
  --version 24.11.0 \
  --namespace stackable-operators \
  --wait

# Listener Operator 설치 (필수 의존성)
echo "Listener Operator 설치..."
helm upgrade --install listener-operator stackable-stable/listener-operator \
  --version 24.11.0 \
  --namespace stackable-operators \
  --wait

# ZooKeeper Operator 설치 (HDFS 의존성)
echo "ZooKeeper Operator 설치..."
helm upgrade --install zookeeper-operator stackable-stable/zookeeper-operator \
  --version 24.11.0 \
  --namespace stackable-operators \
  --wait

# HDFS Operator 설치 (공식)
echo "HDFS Operator 설치..."
helm upgrade --install hdfs-operator stackable-stable/hdfs-operator \
  --version 24.11.0 \
  --namespace stackable-operators \
  --wait

echo ""
echo "=== 설치 완료 ==="
kubectl get pods -n stackable-operators
