# ArgoCD 설치 및 GitOps 자동 배포

## 공식 Helm Chart
- URL: https://github.com/bitnami/charts/tree/main/bitnami/argo-cd
- Helm Repo: `oci://registry-1.docker.io/bitnamicharts/argo-cd`

## 설치 명령어
```bash
helm install argocd oci://registry-1.docker.io/bitnamicharts/argo-cd \
  --namespace argocd \
  --values 01-argocd-values.yaml
```

## 주요 기능
1. GitOps 기반 자동 배포
2. 모든 Helm Chart 및 Kubernetes 리소스 자동 동기화
3. k3s 클러스터 자동 업데이트
4. 변경 사항 자동 감지 및 배포

## WebUI 접근
- ArgoCD: https://argocd.mireu.xyz
