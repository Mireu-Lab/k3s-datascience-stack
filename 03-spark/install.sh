#!/bin/bash
# Apache Spark 설치 스크립트

# Spark Config 적용
kubectl apply -f 02-spark-config.yaml

# Spark 설치
helm install spark oci://registry-1.docker.io/bitnamicharts/spark \
  --namespace spark \
  --create-namespace \
  --values 01-spark-values.yaml \
  --wait

# 설치 확인
kubectl get pods -n spark
kubectl get svc -n spark
kubectl get ingress -n spark

echo "Apache Spark 설치 완료!"
echo "Spark Master UI: https://spark.mireu.xyz"
