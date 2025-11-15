#!/bin/bash
# Apache Hadoop HDFS 설치 스크립트

# ConfigMap 및 Cluster 배포
kubectl apply -f 02-hdfs-cluster.yaml

# 설치 확인
kubectl get pods -n hadoop
kubectl get svc -n hadoop
kubectl get ingress -n hadoop

echo "Hadoop HDFS 설치 완료!"
echo "HDFS NameNode UI: https://hdfs.mireu.xyz"
echo "YARN ResourceManager UI: https://yarn.mireu.xyz"
