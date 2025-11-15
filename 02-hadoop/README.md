# Apache Hadoop HDFS 설치 및 구성

## 공식 Operator
- URL: https://github.com/stackabletech/hdfs-operator
- Documentation: https://docs.stackable.tech/hdfs/stable/

## 설치 명령어
```bash
# Stackable Operator 설치
helm repo add stackable-stable https://repo.stackable.tech/repository/helm-stable/
helm repo update

# HDFS Operator 설치
helm install hdfs-operator stackable-stable/hdfs-operator \
  --namespace hadoop \
  --create-namespace \
  --wait

# HDFS Cluster 배포
kubectl apply -f 02-hdfs-cluster.yaml -n hadoop
```

## 데이터 티어링 전략
1. **Hot Data (NVME SSD)**: 최대 2일 - 실시간 분석 데이터
2. **Cold Data (SATA HDD)**: 최소 2일 - 장기 보관 데이터
3. **Archive Data (GCS)**: 최소 1주일 - tar.xz 압축 후 아카이브

## WebUI 접근
- HDFS NameNode UI: https://hdfs.mireu.xyz
- YARN ResourceManager UI: https://yarn.mireu.xyz
