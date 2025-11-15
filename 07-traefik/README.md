# Traefik Ingress Controller 설치 및 DNS 라우팅

## 공식 Helm Chart
- URL: https://github.com/traefik/traefik-helm-chart
- Helm Repo: https://traefik.github.io/charts

## 설치 명령어
```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik \
  --namespace traefik \
  --values 01-traefik-values.yaml
```

## 도메인 라우팅
- **traefik.mireu.xyz** → Traefik Dashboard
- **jupyter.mireu.xyz** → JupyterHub
- **grafana.mireu.xyz** → Grafana
- **spark.mireu.xyz** → Apache Spark
- **hdfs.mireu.xyz** → Hadoop HDFS
- **yarn.mireu.xyz** → YARN ResourceManager
- **pg.mireu.xyz** → pgAdmin (PostgreSQL)
- **keycloak.mireu.xyz** → Keycloak IAM

## SSL/TLS
기존 인증서를 Kubernetes Secret으로 배포하여 사용
