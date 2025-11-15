#!/bin/bash
# ResearchOps 플랫폼 전체 배포 스크립트
# HP Z440 단일 노드 구성

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# KUBECONFIG 설정
export KUBECONFIG=/home/limmi/k3s-datascience-stack/k3s.yaml

echo -e "${BLUE}=========================================="
echo "ResearchOps Platform 배포 시작"
echo "=========================================="
echo -e "아키텍처: 단일 노드 (HP Z440)"
echo "CPU: Intel E5-2666 v3"
echo "RAM: 96GB DDR4"
echo "GPU: NVIDIA GTX 1080 Ti"
echo "Storage: NVME 2TB + HDD 2TB + GCS 1PB"
echo -e "==========================================${NC}"
echo ""

# 배포 순서
echo -e "${YELLOW}배포 순서:${NC}"
echo "1. HDFS (Stackable Operator) - 비정형 데이터 저장"
echo "2. PostgreSQL (CloudNativePG) - 정형 데이터 저장"
echo "3. Apache Spark - 데이터 처리 및 전처리"
echo "4. JupyterHub - 연구 환경 및 프로젝트 관리"
echo "5. Grafana - 모니터링 및 시각화"
echo "6. Traefik - Ingress 및 DNS 라우팅"
echo "7. Keycloak - IAM 및 Google OAuth"
echo ""

read -p "계속 진행하시겠습니까? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "배포가 취소되었습니다."
    exit 0
fi

# 1. HDFS 배포
echo -e "\n${GREEN}[1/7] HDFS 클러스터 배포 중...${NC}"
cd /home/limmi/k3s-datascience-stack/1_hdfs
bash deploy-all.sh || { echo -e "${RED}HDFS 배포 실패${NC}"; exit 1; }

# 2. PostgreSQL 배포
echo -e "\n${GREEN}[2/7] PostgreSQL 클러스터 배포 중...${NC}"
cd /home/limmi/k3s-datascience-stack/3_postgres
bash deploy-all.sh || { echo -e "${RED}PostgreSQL 배포 실패${NC}"; exit 1; }

# 3. Apache Spark 배포
echo -e "\n${GREEN}[3/7] Apache Spark 배포 중...${NC}"
cd /home/limmi/k3s-datascience-stack/2_spark
bash deploy-all.sh || { echo -e "${RED}Spark 배포 실패${NC}"; exit 1; }

# 4. JupyterHub 배포
echo -e "\n${GREEN}[4/7] JupyterHub 배포 중...${NC}"
cd /home/limmi/k3s-datascience-stack/4_jupyterhub
bash deploy-all.sh || { echo -e "${RED}JupyterHub 배포 실패${NC}"; exit 1; }

# 5. Grafana 배포
echo -e "\n${GREEN}[5/7] Grafana 배포 중...${NC}"
cd /home/limmi/k3s-datascience-stack/5_grafana
bash deploy-all.sh || { echo -e "${RED}Grafana 배포 실패${NC}"; exit 1; }

# 6. Traefik 배포
echo -e "\n${GREEN}[6/7] Traefik 배포 중...${NC}"
cd /home/limmi/k3s-datascience-stack/6_traefik
bash deploy-all.sh || { echo -e "${RED}Traefik 배포 실패${NC}"; exit 1; }

# 7. Keycloak 배포
echo -e "\n${GREEN}[7/7] Keycloak 배포 중...${NC}"
cd /home/limmi/k3s-datascience-stack/7_keycloak
bash deploy-all.sh || { echo -e "${RED}Keycloak 배포 실패${NC}"; exit 1; }

echo -e "\n${BLUE}=========================================="
echo "배포 완료!"
echo "==========================================${NC}"
echo ""
echo -e "${GREEN}접속 URL:${NC}"
echo "  - JupyterHub:  https://jupyter.mireu.xyz"
echo "  - Grafana:     https://grafana.mireu.xyz"
echo "  - Spark UI:    https://spark.mireu.xyz"
echo "  - HDFS UI:     https://hdfs.mireu.xyz"
echo "  - PostgreSQL:  https://pg.mireu.xyz"
echo "  - Keycloak:    https://keycloak.mireu.xyz"
echo ""
echo -e "${YELLOW}인증 정보:${NC}"
echo "  Keycloak Admin:"
echo "    - Username: admin"
echo "    - Password: admin"
echo ""
echo "  Google OAuth를 통한 로그인:"
echo "    - JupyterHub: Master Admin 권한"
echo "    - Grafana: Master Admin 권한"
echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo "1. Keycloak에서 Google OAuth Identity Provider 설정"
echo "2. 각 서비스의 Client Secret 업데이트"
echo "3. 프로젝트별 사용자 및 그룹 생성"
echo "4. JWT 토큰 생성 및 API 접근 테스트"
echo ""
echo -e "${GREEN}배포 상태 확인:${NC}"
echo "  kubectl get pods -A"
echo "  kubectl get ingress -A"
echo ""
