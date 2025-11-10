#!/bin/bash

# 서비스 배포 스크립트

echo "서비스 배포 시작..."

# PostgreSQL 배포
echo "PostgreSQL 배포 중..."
kubectl apply -f ./k8s/services/postgresql/postgresql-deployment.yaml

# Hadoop 배포
echo "Hadoop 배포 중..."
kubectl apply -f ./k8s/services/hadoop/hadoop-deployment.yaml

# Spark 배포
echo "Spark 배포 중..."
kubectl apply -f ./k8s/services/spark/spark-operator.yaml

# JupyterHub 배포
echo "JupyterHub 배포 중..."
kubectl apply -f ./k8s/services/jupyterhub/jupyterhub-config.yaml
kubectl apply -f ./k8s/services/jupyterhub/jupyterhub-deployment.yaml

# 배포 상태 확인
echo "서비스 배포 상태 확인 중..."
kubectl get pods -n datascience

echo "서비스 배포 완료"