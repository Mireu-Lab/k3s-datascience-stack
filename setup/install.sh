#!/bin/bash

# 메인 설치 스크립트

echo "데이터 사이언스 스택 설치 시작..."

# 스크립트 실행 권한 부여
chmod +x ./*.sh

# 단계별 설치 진행
./00-prepare-system.sh
./01-install-k3s.sh
./02-install-nvidia-drivers.sh
./03-deploy-storage.sh
./04-deploy-services.sh
./05-deploy-ingress.sh

echo "데이터 사이언스 스택 설치 완료"
echo "서비스 상태를 확인하려면 다음 명령어를 실행하세요:"
echo "kubectl get pods -n datascience"
echo ""
echo "접속 정보:"
echo "- JupyterHub: https://jupyter.mireu.xyz"
echo "- Spark UI: https://spark.mireu.xyz"
echo "- Hadoop UI: https://hadoop.mireu.xyz"
echo "- PostgreSQL: postgresql.mireu.xyz:5432"