# Keycloak IAM 설치 및 구성

## 공식 Helm Chart
- URL: https://github.com/bitnami/charts/tree/main/bitnami/keycloak
- Helm Repo: `oci://registry-1.docker.io/bitnamicharts/keycloak`

## 설치 명령어
```bash
bash install.sh
```

## 주요 기능

### 1. Google OAuth 통합 인증
- 모든 사용자는 Google 계정으로 로그인
- 자동 사용자 프로비저닝
- 이메일 기반 식별

### 2. 프로젝트별 IAM
- JupyterHub 프로젝트별 격리
- 프로젝트 단위 리소스 접근 제어
- 사용자 그룹 및 역할 관리

### 3. 서비스 접근 토큰
각 프로젝트에서 사용 가능한 JWT 토큰:
- **Spark**: 데이터 처리 작업용
- **HDFS**: 파일 시스템 접근용
- **PostgreSQL**: 데이터베이스 접근용

### 4. Master Account
Jupyter 및 Grafana 전용 마스터 계정:
- Google OAuth로 로그인
- 모든 프로젝트 접근 가능
- 시스템 전체 모니터링 및 관리

### 5. JWT 토큰 배포
- `*.mireu.xyz` 도메인에서 유효한 JWT
- RS256 알고리즘 서명
- 2시간 유효 기간 (서비스 토큰)
- 자동 갱신 지원

## 파일 구조

```
01-keycloak/
├── README.md                           # 개요
├── KEYCLOAK_SETUP.md                   # 상세 설정 가이드
├── 01-keycloak-values.yaml             # Helm values
├── 02-keycloak-realm.yaml              # ResearchOps Realm 설정
├── 03-keycloak-realm-import.yaml       # Realm Import Job
├── token-generator.py                  # 토큰 생성 스크립트
└── install.sh                          # 설치 스크립트
```

## Realm 구조

### ResearchOps Realm
- **Realm**: `researchops`
- **Identity Provider**: Google OAuth
- **Default Group**: `data_analysts`

### Roles
1. **master_account**: 마스터 계정 (Jupyter, Grafana)
2. **project_admin**: 프로젝트 관리자
3. **data_analyst**: 데이터 분석가
4. **data_scientist**: 데이터 과학자

### Clients
1. **jupyterhub**: JupyterHub OAuth 클라이언트
2. **grafana**: Grafana OAuth 클라이언트
3. **spark**: Spark 서비스 계정
4. **hdfs**: HDFS 서비스 계정
5. **postgresql**: PostgreSQL 서비스 계정

### Client Scopes
1. **project_access**: 프로젝트 기반 접근 제어
2. **resource_access**: 리소스별 토큰 (Spark, HDFS, PG)

## 토큰 생성 방법

### 기본 사용법
```bash
python3 token-generator.py \
  --project "my-research-project" \
  --user-email "researcher@example.com" \
  --spark-secret "spark-secret-change-me" \
  --hdfs-secret "hdfs-secret-change-me" \
  --pg-secret "postgresql-secret-change-me" \
  --output "project-tokens.json"
```

### 생성된 토큰 사용
```python
import json

# 토큰 로드
with open('project-tokens.json') as f:
    tokens = json.load(f)

# Spark 토큰
spark_token = tokens['services']['spark']['access_token']

# HDFS 토큰
hdfs_token = tokens['services']['hdfs']['access_token']

# PostgreSQL 토큰
pg_token = tokens['services']['postgresql']['access_token']
```

## 설정 단계

### 1. Google OAuth 설정
[KEYCLOAK_SETUP.md](./KEYCLOAK_SETUP.md) 참고

1. Google Cloud Console에서 OAuth 클라이언트 생성
2. 리디렉션 URI 설정:
   - `https://keycloak.mireu.xyz/realms/researchops/broker/google/endpoint`
   - `https://jupyter.mireu.xyz/hub/oauth_callback`
   - `https://grafana.mireu.xyz/login/generic_oauth`

### 2. Client Secrets 업데이트
```bash
kubectl edit secret keycloak-clients-secrets -n keycloak
```

업데이트할 항목:
- `google-client-id`
- `google-client-secret`
- `jupyterhub-client-secret`
- `grafana-client-secret`

### 3. Realm Import 확인
```bash
kubectl logs -n keycloak job/keycloak-realm-import
```

### 4. 사용자 추가
Keycloak Admin Console:
- Users > Add User
- Email 설정
- Groups 할당
- Role Mappings 설정

## 보안 설정

### SSL/TLS
- HTTPS 강제 (외부 요청)
- TLS 1.2 이상
- 인증서: `mireu-xyz-tls` Secret

### Token Security
- RS256 알고리즘
- Access Token: 1시간
- Refresh Token: 30일
- SSO Session: 10시간

### Brute Force Protection
- 최대 실패 횟수: 5회
- 대기 시간: 60초
- 영구 잠금: 비활성화

## 모니터링

### 로그 확인
```bash
kubectl logs -n keycloak -l app.kubernetes.io/name=keycloak -f
```

### 메트릭
```bash
curl -s http://keycloak.keycloak.svc.cluster.local:8080/metrics
```

### 이벤트
Keycloak Admin Console > Events

## 백업

### Realm Export
```bash
kubectl exec -n keycloak deployment/keycloak -- \
  /opt/bitnami/keycloak/bin/kc.sh export \
  --realm researchops \
  --file /tmp/backup.json
```

## 문제 해결

### Realm Import 실패
```bash
# Job 재실행
kubectl delete job keycloak-realm-import -n keycloak
kubectl apply -f 03-keycloak-realm-import.yaml
```

### Google OAuth 연결 실패
1. Google Cloud Console에서 리디렉션 URI 확인
2. Client ID/Secret 재확인
3. Keycloak에서 Identity Provider 재설정

### 토큰 생성 실패
1. Client Secret 확인
2. 네트워크 연결 확인
3. Keycloak 로그 확인

## 참고 문서
- [상세 설정 가이드](./KEYCLOAK_SETUP.md)
- [Keycloak 공식 문서](https://www.keycloak.org/documentation)
- [OpenID Connect](https://openid.net/connect/)
