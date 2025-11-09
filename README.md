# k3s-datascience-stack

이 저장소는 단일 노드(HP Z440)에서 K3s 기반의 데이터 과학 스택을 구성하기 위한 예시 스크립트 및 Kubernetes 매니페스트를 포함합니다.

주요 구성 요소:
- JupyterHub (Helm chart를 이용한 배포 예시)
- Apache Spark (간단한 standalone 예시)
- PostgreSQL (StatefulSet)
- Hadoop (간단한 single-node 예시)
- NVIDIA device plugin (GPU 사용을 위한 DaemonSet 예시)
- Cold-data 백업 스크립트 및 Kubernetes CronJob
- 디스크 초기화/마운트 스크립트
- k3s 설치/제거 스크립트

중요 가정 및 주의사항:
- 스크립트는 파티션/포맷 등을 수행하므로 반드시 백업 후 사용하세요.
- 실제 운영 환경에서는 Helm 차트 설정, HTTPS/Ingress, 인증(OAuth/LDAP), RBAC 정책을 보다 엄격히 구성해야 합니다.
- JAX/GPU 사용은 올바른 호스트 드라이버, CUDA 라이브러리 및 컨테이너 내 CUDA 런타임 버전이 일치해야 합니다.

파일 목록(주요):
- scripts/setup_disk.sh : NVMe/HDD 파티션, 포맷 및 /etc/fstab 등록
- scripts/install_k3s.sh : k3s 설치
- scripts/uninstall_k3s.sh : k3s 제거
- scripts/install_nvidia.sh : NVIDIA 드라이버 + nvidia-container-toolkit 설치 시도
- docker/jupyteruser.Dockerfile : Jupyter singleuser 이미지 예시
- k8s/jupyterhub/values.yaml : JupyterHub Helm values 예시
- k8s/postgres/postgres-statefulset.yaml : PostgreSQL StatefulSet
- k8s/spark/spark-deploy.yaml : Spark master/worker 예시
- k8s/hdfs/hadoop-deployment.yaml : 간단한 HDFS 예시
- k8s/nvidia-device-plugin/nvidia-device-plugin.yaml : NVIDIA device plugin DaemonSet
- k8s/backup/backup.sh : 백업 스크립트
- k8s/backup/backup-cronjob.yaml : CronJob 매니페스트

빠른 시작 (권장: 테스트 노드에서 단계별로 진행):

1) 디스크 초기화 (검토 후 실행)

   sudo bash scripts/setup_disk.sh

2) NVIDIA 드라이버 설치(필요한 경우)

   sudo bash scripts/install_nvidia.sh

3) k3s 설치

   sudo bash scripts/install_k3s.sh

4) Kubernetes 리소스 배포

   # kubeconfig가 /etc/rancher/k3s/k3s.yaml 에 생성됩니다.
   export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
   kubectl apply -f k8s/nvidia-device-plugin/nvidia-device-plugin.yaml
   kubectl apply -f k8s/postgres/postgres-statefulset.yaml
   kubectl apply -f k8s/spark/spark-deploy.yaml
   kubectl apply -f k8s/hdfs/hadoop-deployment.yaml
   kubectl apply -f k8s/backup/backup-cronjob.yaml

5) JupyterHub 배포 (Helm 필요)

   # Helm을 사용하여 jupyterhub 설치
   # helm install jhub jupyterhub/jupyterhub --namespace jupyterhub -f k8s/jupyterhub/values.yaml

검증 및 후속 작업:
- 각 컴포넌트 로그 확인: kubectl -n <namespace> logs ...
- GPU 사용 확인: kubectl run --rm -it --restart=Never --image=nvidia/cuda:12.1.1-base-ubuntu24.04 gpu-test -- nvidia-smi
- GCP 업로드를 위한 서비스 계정 및 Secret 생성은 k8s/backup 문서를 참고 후 수동으로 적용하세요.
