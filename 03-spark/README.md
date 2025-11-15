# Apache Spark 설치 및 구성

## 공식 Helm Chart
- URL: https://github.com/bitnami/charts/tree/main/bitnami/spark
- Helm Repo: `oci://registry-1.docker.io/bitnamicharts/spark`

## 설치 명령어
```bash
helm install spark oci://registry-1.docker.io/bitnamicharts/spark \
  --namespace spark \
  --values 01-spark-values.yaml
```

## 주요 기능
1. Keycloak 권한 연동을 통한 프로젝트별 접근 제어
2. Hadoop HDFS 및 PostgreSQL 자동 연결
3. Spark WebUI를 통한 작업 모니터링

## WebUI 접근
- Spark Master UI: https://spark.mireu.xyz
