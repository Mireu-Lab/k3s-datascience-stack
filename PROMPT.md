# 목표

나는 주어진 시스템으로 데이터 분석 용 서버를 구현하고자 한다
나는 JupyterHub로 로그인 시스템을 단일화 하고, 나머지 부가적인 기능들 Apache Spark, PostgreSQL, Apache Hadoop, Google JAX를 사용할수있는 FrameWork가 필요하다.
나는 데이터 분석 및 ML/DL/RL 실험용으로 시스템을 구축하고자 하는것이다.
내가 제시하는 방식을 구현할수있는 파일를 작성하여 출력하시오.


# 참고

- 사용할수있는 도메인은 *.mireu.xyz입니다. (DNS서비스는 CloudFlare를 활용합니다.)
- 단, 모든 설치가 처음부터 진행하는게 아니라서 제거하고 재설치 하는 형태로 제시하여야합니다.
- 모든 프로그램들의 설정을 제시하여 출력하여야 합니다.
- 디스크 또한 처음부터 셋팅 할수있도록 하여야합니다. (예시로 파티션 제거후 재 생성)
- 이미 설치 되어있는 패키지는 제외하고 진행하여야합니다.
- github로 Container Image와 Code를 배포할수있도록 각 파일로 분류하여야합니다.

# 시스템 구성

- HW : HP Z440
- CPU : INTEL E5-2666 v3
- RAM : DDR4 2666 8GB * 4 / DDR4 2666 16GB * 4 = 96GB
- ROM#1 : SATA SSD 480GB [OS 설치]
- ROM#2 : NVME PCI SSD 2TB (WD Black AN1500) [mount: /mnt/nvme]
- ROM#3 : HDD 3.5inch 2TB [mount: /mnt/hdd]
- GPU : NVIDIA GTX1080TI 11GB
- OS : Ubuntu 24.04.02
- NET : 1Gbps RJ45

으로 **단일 구성**이 되어있다.

# K3S (containerd) 설계 아키택쳐

1. 데이터를 관리 및 전처리 할수있는 Apache Spark
2. 정형 데이터인경우 PostgreSQL에 저장
3. 비 정형 데이터인경우 Apache Hadoop를 가지고 데이터 저장 (예: 이미지, MP3, MP4)
4. 모든 데이터를 Cold Data목적으로 HDD에 1주일 지나면 자동으로 압축하여 GCP Storage에 Upload
5. NVIDIA 드라이버가 설치 되어있는 JAX
6. Google Cloud IAM으로 관리하는 RBAC
7. 이 모든 형태를 관리하고 각 프로젝트 마다 새로운 네임스페이스를 생성하여 또는 계정을 분활 하여 프로젝트와 분리 관리를 할수있는 jupyter hub

## 데이터 관리

1. Hot Data인경우 NVME SSD (SIZE 2TB)에 저장하여야합니다.
2. Cold Data인경우 NVME SSD에서 HDD로 데이터를 백업 하여야 합니다.

## 네트워크 관리

1. 추후에 네트워크 IP가 변경이 될수도 있습니다.
2. 네트워크 IP는 단일적으로 구성되어있습니다.