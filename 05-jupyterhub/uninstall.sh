#!/bin/bash
# JupyterHub 제거 스크립트

echo "JupyterHub 제거 중..."

# Jupyter Config 제거
kubectl delete -f 02-jupyter-config.yaml --ignore-not-found

# JupyterHub Helm Release 제거
helm uninstall jupyterhub --namespace jupyterhub || true

# Namespace 제거
kubectl delete namespace jupyterhub --ignore-not-found

echo "JupyterHub 제거 완료!"
echo ""
echo "참고: 사용자 데이터는 PersistentVolume에 남아있을 수 있습니다."
echo "완전히 삭제하려면 PV를 수동으로 삭제하세요."
