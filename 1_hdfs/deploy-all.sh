#!/bin/bash
# ResearchOps 전체 배포 스크립트

set -e

# KUBECONFIG 설정
export KUBECONFIG=/home/limmi/k3s-datascience-stack/k3s.yaml

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "ResearchOps 아키텍처 배포 시작"
echo "========================================="

# 1. Stackable Operators 설치
echo ""
echo "[1/4] Stackable Operators 설치..."
bash "$SCRIPT_DIR/00-install-operators.sh"

# 2. ZooKeeper 클러스터 배포
echo ""
echo "[2/4] ZooKeeper 클러스터 배포..."
kubectl apply -f "$SCRIPT_DIR/01-zookeeper-cluster.yaml"
kubectl apply -f "$SCRIPT_DIR/01-zookeeper-znode.yaml"

echo "ZooKeeper 준비 대기 중..."
kubectl rollout status --watch --timeout=5m statefulset/hdfs-zk-server-default

# 3. HDFS 클러스터 배포
echo ""
echo "[3/4] HDFS 클러스터 배포..."
kubectl apply -f "$SCRIPT_DIR/02-hdfs-cluster.yaml"

echo "HDFS 준비 대기 중..."
sleep 30
kubectl rollout status --watch --timeout=10m statefulset/hdfs-cluster-namenode-default
kubectl rollout status --watch --timeout=10m statefulset/hdfs-cluster-datanode-default
kubectl rollout status --watch --timeout=10m statefulset/hdfs-cluster-journalnode-default

# 4. 데이터 라이프사이클 관리 CronJob 배포
echo ""
echo "[4/4] 데이터 라이프사이클 CronJob 배포..."
kubectl apply -f "$SCRIPT_DIR/03-data-lifecycle-cronjob.yaml"

echo ""
echo "========================================="
echo "배포 완료!"
echo "========================================="
echo ""
echo "배포된 리소스 확인:"
echo ""
kubectl get pods -n stackable-operators
echo ""
kubectl get pods
echo ""
kubectl get cronjobs
echo ""
echo "========================================="
echo "ResearchOps 시스템 구성 완료"
echo "========================================="
echo ""
echo "데이터 저장 계층:"
echo "  - Hot Data (NVME):    /mnt/nvme (최대 2일)"
echo "  - Cold Data (HDD):    /mnt/hdd  (2일 후)"
echo "  - Archive Data (GCS): /mnt/gcs  (1주일 후)"
echo ""
echo "자동 마이그레이션: 매일 새벽 2시"
echo "========================================="
