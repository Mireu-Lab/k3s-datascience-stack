# Keycloak IAM 설정 가이드

## 1. Google OAuth 설정

### Google Cloud Console 설정
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 생성 또는 선택
3. **API 및 서비스** > **OAuth 동의 화면** 설정
   - 사용자 유형: 외부
   - 앱 이름: ResearchOps Platform
   - 승인된 도메인: mireu.xyz
   - 범위: email, profile, openid

4. **사용자 인증 정보** > **OAuth 2.0 클라이언트 ID 만들기**
   - 애플리케이션 유형: 웹 애플리케이션
   - 이름: ResearchOps Keycloak
   - 승인된 리디렉션 URI:
     - `https://keycloak.mireu.xyz/realms/researchops/broker/google/endpoint`
     - `https://jupyter.mireu.xyz/hub/oauth_callback`
     - `https://grafana.mireu.xyz/login/generic_oauth`

5. 클라이언트 ID와 클라이언트 보안 비밀 저장

### Keycloak Secret 업데이트
```bash
kubectl edit secret keycloak-clients-secrets -n keycloak
```

다음 값을 업데이트:
- `google-client-id`: Google OAuth 클라이언트 ID
- `google-client-secret`: Google OAuth 클라이언트 보안 비밀

## 2. Keycloak Realm 구성

### ResearchOps Realm
- **Realm 이름**: `researchops`
- **Display Name**: ResearchOps Platform
- **SSL Required**: External requests
- **Login with Email**: Enabled

### Identity Provider (Google OAuth)
- **Alias**: google
- **Display Name**: Google
- **Sync Mode**: IMPORT
- **Trust Email**: Enabled
- **Store Token**: Enabled

## 3. 클라이언트 설정

### JupyterHub Client
- **Client ID**: `jupyterhub`
- **Client Protocol**: openid-connect
- **Access Type**: confidential
- **Standard Flow**: Enabled
- **Direct Access Grants**: Enabled
- **Service Accounts**: Enabled
- **Valid Redirect URIs**: 
  - `https://jupyter.mireu.xyz/*`
  - `https://jupyter.mireu.xyz/hub/oauth_callback`
- **Web Origins**: `https://jupyter.mireu.xyz`

### Grafana Client
- **Client ID**: `grafana`
- **Client Protocol**: openid-connect
- **Access Type**: confidential
- **Valid Redirect URIs**: 
  - `https://grafana.mireu.xyz/*`
  - `https://grafana.mireu.xyz/login/generic_oauth`

### Service Clients (Spark, HDFS, PostgreSQL)
각 서비스별 클라이언트:
- **Client ID**: `spark`, `hdfs`, `postgresql`
- **Client Protocol**: openid-connect
- **Access Type**: confidential
- **Service Accounts Enabled**: Yes
- **Authorization**: Enabled
- **Access Token Lifespan**: 7200초 (2시간)

## 4. 롤(Role) 및 그룹(Group) 구조

### Realm Roles
1. **master_account**: Jupyter, Grafana 마스터 계정
   - 모든 프로젝트 접근 가능
   - 모든 리소스 관리 권한

2. **project_admin**: 프로젝트 관리자
   - 프로젝트 내 사용자 관리
   - 리소스 할당 및 관리

3. **data_analyst**: 데이터 분석가
   - Spark 읽기/쓰기
   - HDFS 읽기
   - PostgreSQL 읽기/쓰기

4. **data_scientist**: 데이터 과학자
   - 모든 데이터 서비스 접근
   - 모델 훈련 및 배포

### Groups
- **/master_accounts**: 마스터 계정 그룹
- **/project_admins**: 프로젝트 관리자 그룹
- **/data_analysts**: 데이터 분석가 그룹
- **/data_scientists**: 데이터 과학자 그룹

## 5. Client Scopes

### project_access
프로젝트 기반 접근 제어
- **Mapper**: project-mapper
- **User Attribute**: project
- **Token Claim**: project

### resource_access
리소스별 접근 토큰
- **Audience Mappers**:
  - spark-access
  - hdfs-access
  - postgresql-access

## 6. 토큰 생성 및 관리

### 프로젝트별 토큰 생성
```bash
python3 token-generator.py \
  --project "my-project" \
  --user-email "user@example.com" \
  --spark-secret "spark-secret-change-me" \
  --hdfs-secret "hdfs-secret-change-me" \
  --pg-secret "postgresql-secret-change-me" \
  --output "my-project-tokens.json"
```

### 토큰 구조
```json
{
  "project": "my-project",
  "user": "user@example.com",
  "created_at": "2025-11-15T12:00:00",
  "expires_in": 7200,
  "services": {
    "spark": {
      "access_token": "eyJhbGc...",
      "token_type": "Bearer",
      "expires_in": 7200
    },
    "hdfs": {
      "access_token": "eyJhbGc...",
      "token_type": "Bearer",
      "expires_in": 7200
    },
    "postgresql": {
      "access_token": "eyJhbGc...",
      "token_type": "Bearer",
      "expires_in": 7200
    }
  }
}
```

### 토큰 사용 예시

#### Spark 접근
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("MyProject") \
    .config("spark.hadoop.fs.hdfs.impl.disable.cache", "true") \
    .config("spark.authenticate", "true") \
    .config("spark.authenticate.secret", SPARK_TOKEN) \
    .getOrCreate()
```

#### HDFS 접근
```bash
# WebHDFS REST API
curl -i -X GET "https://hdfs.mireu.xyz/webhdfs/v1/user/project?op=LISTSTATUS" \
  -H "Authorization: Bearer ${HDFS_TOKEN}"
```

#### PostgreSQL 접근
```python
import psycopg2

conn = psycopg2.connect(
    host="postgresql.postgresql.svc.cluster.local",
    port=5432,
    database="project_db",
    user="oauth2",
    password=POSTGRESQL_TOKEN
)
```

## 7. JWT 토큰 검증

### 공개 키 엔드포인트
```
https://keycloak.mireu.xyz/realms/researchops/protocol/openid-connect/certs
```

### Python 토큰 검증 예시
```python
import jwt
import requests

# 공개 키 가져오기
jwks_url = "https://keycloak.mireu.xyz/realms/researchops/protocol/openid-connect/certs"
jwks = requests.get(jwks_url).json()

# 토큰 검증
token = "eyJhbGc..."
decoded = jwt.decode(
    token,
    jwks,
    algorithms=["RS256"],
    audience="spark",
    issuer="https://keycloak.mireu.xyz/realms/researchops"
)
```

## 8. 사용자 프로비저닝

### Google OAuth 로그인 시 자동 생성
1. 사용자가 Google OAuth로 로그인
2. Keycloak이 자동으로 사용자 계정 생성
3. 기본 그룹(data_analysts)에 자동 할당
4. 프로젝트 관리자가 추가 권한 부여

### 마스터 계정 생성
Keycloak Admin Console에서:
1. Users > Add User
2. Email: admin@mireu.xyz
3. Groups: master_accounts 추가
4. Role Mappings: master_account 할당

## 9. 보안 설정

### Brute Force Protection
- **Max Failure**: 5회
- **Wait Increment**: 60초
- **Quick Login Check**: 1000ms
- **Permanent Lockout**: Disabled

### Token Lifespans
- **Access Token**: 3600초 (1시간)
- **SSO Session Idle**: 7200초 (2시간)
- **SSO Session Max**: 36000초 (10시간)
- **Offline Session Idle**: 2592000초 (30일)

### SSL/TLS
- **SSL Required**: External requests
- **HTTPS Everywhere**: Enabled
- **Frontend URL**: https://keycloak.mireu.xyz

## 10. 모니터링 및 로깅

### 로그 확인
```bash
kubectl logs -n keycloak -l app.kubernetes.io/name=keycloak -f
```

### 이벤트 모니터링
Keycloak Admin Console:
- Events > Login Events
- Events > Admin Events
- Sessions > Active Sessions

### 메트릭
```bash
curl -s http://keycloak.keycloak.svc.cluster.local:8080/metrics
```

## 11. 백업 및 복구

### Realm Export
```bash
kubectl exec -n keycloak deployment/keycloak -- \
  /opt/bitnami/keycloak/bin/kc.sh export \
  --realm researchops \
  --file /tmp/researchops-realm-backup.json

kubectl cp keycloak/keycloak-xxxxx:/tmp/researchops-realm-backup.json ./backup.json
```

### Realm Import
```bash
kubectl cp ./backup.json keycloak/keycloak-xxxxx:/tmp/backup.json

kubectl exec -n keycloak deployment/keycloak -- \
  /opt/bitnami/keycloak/bin/kc.sh import \
  --file /tmp/backup.json
```

## 참고 자료
- Keycloak Documentation: https://www.keycloak.org/documentation
- OpenID Connect: https://openid.net/connect/
- JWT: https://jwt.io/
- Google OAuth: https://developers.google.com/identity/protocols/oauth2
