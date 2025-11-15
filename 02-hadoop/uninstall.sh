#!/bin/bash
# Apache Hadoop HDFS 제거 스크립트

echo "Apache Hadoop HDFS 제거 중..."

# HDFS Cluster 제거
kubectl delete -f 02-hdfs-cluster.yaml --ignore-not-found

# Namespace 제거
kubectl delete namespace hadoop --ignore-not-found

echo "Apache Hadoop HDFS 제거 완료!"
echo ""
echo "참고: HDFS 데이터는 /mnt/nvme, /mnt/hdd, /mnt/gcs에 남아있습니다."
echo "데이터를 완전히 삭제하려면 다음 명령어를 실행하세요:"
echo "  sudo rm -rf /mnt/nvme/hadoop/*"
echo "  sudo rm -rf /mnt/hdd/hadoop/*"
echo "  sudo rm -rf /mnt/gcs/hadoop-archive/*"
