#!/bin/bash
# Apache Spark 제거 스크립트

echo "Apache Spark 제거 중..."

# Spark Config 제거
kubectl delete -f 02-spark-config.yaml --ignore-not-found

# Spark Helm Release 제거
helm uninstall spark --namespace spark || true

# Namespace 제거
kubectl delete namespace spark --ignore-not-found

echo "Apache Spark 제거 완료!"
