# Grafana 모니터링 설치 및 구성

## 공식 Helm Chart
- URL: https://github.com/bitnami/charts/tree/main/bitnami/grafana
- Helm Repo: `oci://registry-1.docker.io/bitnamicharts/grafana`

## 설치 명령어
```bash
helm install grafana oci://registry-1.docker.io/bitnamicharts/grafana \
  --namespace grafana \
  --values 01-grafana-values.yaml
```

## 주요 기능
1. 프로젝트별 모니터링 대시보드
2. 전체 서버 리소스 모니터링
3. 각 프로그램별 메트릭 수집 및 시각화
4. Prometheus 연동

## WebUI 접근
- Grafana: https://grafana.mireu.xyz
