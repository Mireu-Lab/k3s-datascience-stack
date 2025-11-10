# 서비스 구성

이 디렉토리는 데이터 사이언스 스택의 핵심 서비스들을 정의합니다.

## 서비스 구성 요소
1. JupyterHub (`jupyterhub/`)
   - 사용자 인증 및 노트북 환경 관리
   - Google Cloud IAM 연동
   - RBAC 정책 적용

2. Apache Spark (`spark/`)
   - 데이터 처리 및 분석 엔진
   - NVIDIA GPU 지원 구성

3. PostgreSQL (`postgresql/`)
   - 정형 데이터 저장소
   - 고가용성 구성

4. Apache Hadoop (`hadoop/`)
   - 비정형 데이터 저장소
   - HDFS 구성

5. JAX 환경 (`jax/`)
   - NVIDIA 드라이버 통합
   - GPU 가속 지원

## 배포 순서
1. 스토리지 클래스 및 PV 생성
2. PostgreSQL 배포
3. Hadoop 배포
4. Spark 배포
5. JupyterHub 배포

## 주의사항
- 모든 서비스는 NVIDIA GPU 지원 필요
- 네트워크 구성은 동적 IP 환경 고려
- 데이터 백업 정책 적용 필요