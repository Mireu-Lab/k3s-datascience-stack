# ResearchOpe 설계 아키택쳐

주어진 내용으로만 보고 구현하시오
단, 설명서 필요 없지만 제안하는 URL를 직접 Find하여 작성하여야합니다.

**모든 설치는 Helm를 통해서 설치 하여야합니다.**
**또한, 공식 이미지, 공식 Helm를 가지고 설치를 진행하여야합니다.**

1. 비 정형 데이터인경우 Apache Hadoop를 가지고 데이터 저장 (예: 이미지, MP3, MP4) (제안 HELM: https://github.com/stackabletech/hdfs-operator)
    - 데이터 관리
        1. Hot Data인경우 NVME SSD (SIZE 2TB)에 저장하여야합니다. (기간은 최대 2일)
        2. Cold Data인경우 NVME SSD에서 SATA HDD로 데이터를 백업 하여야 합니다. (기간은 최소 2일)
        3. Archive Data인경우 HDD에서 GCP Storage로 데이터를 백업 하여야합니다. (기간은 최소 1주일)
        4. 변동된 사항이 없는지 FILE SUM를 통해서 확인하고 없으면 해당 프로세스를 진행하지 않아야합니다.
        5. Archive Data는 tar.xz로 압축하여 GCP Storage에 Upload 하여야합니다.
    - NVME SSD를 이미 Mount하였습니다.
    - SATA HDD를 이미 Mount하였습니다.
    - GCS를 이미 Mount하였습니다.
    - 각 프로젝트마다 새로운 폴더를 생성하고 폴더에 적용되는 권한을 Keycloak에서 관리 할수있도록 합니다.
2. 데이터를 관리 및 전처리 할수있는 Apache Spark (제안 HELM: https://github.com/apache/spark-kubernetes-operator)
3. 정형 데이터인경우 PostgreSQL에 저장 (제안 HELM: https://github.com/cloudnative-pg/cloudnative-pg)
    - 각 프로젝트마다 새로운 데이터베이스를 생성하고 데이터베이스에 적용되는 권한을 Keycloak에서 관리 할수있도록 합니다.
4. 이 모든 형태를 관리하고 각 프로젝트 마다 새로운 네임스페이스를 생성하여 또는 계정을 분활 하여 프로젝트와 분리 관리를 할수있는 Jupyter Hub (제안 HELM: https://github.com/jupyterhub/zero-to-jupyterhub-k8s)
    - Container 패키지 리스트
        1. NVIDIA 드라이버 + JAX 설치 되어있는 Container (사용자가 Git Repo URL를 제공하면 주어진 Repo Name으로 배포 하여야함.)
        2. Hadoop을 Mount하여야함.
        3. Spark는 어떠한 상황에서도 Hadoop와 PostgreSQL간의 연결이 되어야 합니다.
    - Jupyter Hub 기능 리스트
        1. Google OAuth로 관리하는 Jupyter Hub
        2. Git Repo URL를 보고 Login Email + Repo Name를 기반으로 WorkSpace 생성하여야합니다.
5. 이들을 관리 모니터링 할수있는 Grafana (제안 HELM: https://github.com/grafana/grafana-operator)
    - 각 프로젝트마다 모니터링 할수있는 대시보드
    - 서버 전체를 모니터링 할수있는 대시보드
    - 각 프로그램마다 모니터링 할수있는 대시보드
    - 각 프로젝트마다 모니터링 할수있는 대시보드
6. 구축된 시스템을 접속하기 위한 DNS Traefik 
    - JupyterHub는 jupyter.mireu.xyz로 접속 하여야합니다.
    - Grafana는 grafana.mireu.xyz로 접속 하여야합니다.
    - Apache Spark는 spark.mireu.xyz로 접속 하여야합니다.
    - Apache Hadoop는 hdfs.mireu.xyz로 접속 하여야합니다.
    - PostgreSQL는 pg.mireu.xyz로 접속 하여야합니다.
7. 구축된 시스템들을 접속 관리하기 위한 Keycloak (제안 HELM: https://artifacthub.io/packages/helm/keycloak-operator/keycloak-operator)
    - 각 프로젝트를 JupyterHub로 생성하고 프로젝트에 적용되는 IAM 구현
    1. 모든 Login를 Google OAuth으로 활용
    2. 각각 프로젝트에서 사용가능한 spark, hdfs, pg를 접속하기 위한 Token생성
    3. jupyter, grafana는 연구 환경을 구축하기 위한 목적으로 Master Account이므로 Google OAuth를 활용
    4. *.mireu.xyz에서 사용가능한 JWT를 배포

    
# 시스템 구성

- HW : HP Z440
- CPU : INTEL E5-2666 v3
- RAM : DDR4 2666 8GB * 4 / DDR4 2666 16GB * 4 = 96GB
- ROM#1 : SATA SSD 480GB [OS 설치]
- ROM#2 : NVME PCI SSD 2TB (WD Black AN1500) [mount: /mnt/nvme]
- ROM#3 : SATA HDD 3.5inch 2TB [mount: /mnt/hdd]
- ROM#4 : GCS NETWORK STORAGE 1PB [mount: /mnt/gcs]
- GPU : NVIDIA GTX1080TI 11GB
- OS : Ubuntu 24.04.02
- NET : 1Gbps RJ45

으로 **단일 구성**이 되어있다.