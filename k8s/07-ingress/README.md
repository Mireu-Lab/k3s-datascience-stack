# Ingress 및 인증서 관리

이 디렉토리는 Traefik Ingress Controller와 cert-manager를 사용한 HTTPS 설정을 포함합니다.

## 구성 요소

### 도메인 구성

| 서비스 | 도메인 | 설명 | 인증 |
|--------|--------|------|------|
| JupyterHub | `jupyter.mireu.xyz` | 메인 분석 플랫폼 | Google OAuth |
| Spark Master | `spark.mireu.xyz` | Spark 클러스터 관리 | Basic Auth |
| Spark History | `spark-history.mireu.xyz` | Spark 작업 이력 | Basic Auth |
| Hadoop NameNode | `hadoop.mireu.xyz` | HDFS 관리 UI | Basic Auth |

### TLS/SSL 인증서

- **cert-manager**: Let's Encrypt를 통한 자동 인증서 발급
- **ClusterIssuer**: Production 및 Staging 환경
- **자동 갱신**: 만료 30일 전 자동 갱신

## 사전 준비

### 1. DNS 설정 (CloudFlare)

CloudFlare에서 다음 A 레코드 추가:

```
Type  Name            Content         Proxy status  TTL
A     jupyter         YOUR_SERVER_IP  DNS only      Auto
A     spark           YOUR_SERVER_IP  DNS only      Auto
A     spark-history   YOUR_SERVER_IP  DNS only      Auto
A     hadoop          YOUR_SERVER_IP  DNS only      Auto
A     *.mireu.xyz     YOUR_SERVER_IP  DNS only      Auto  (와일드카드, 선택사항)
```

**중요**: Proxy status를 "DNS only"로 설정 (Let's Encrypt HTTP-01 challenge를 위해)

### 2. 방화벽 설정

서버 방화벽에서 포트 개방:

```bash
# HTTP (Let's Encrypt challenge)
sudo ufw allow 80/tcp

# HTTPS
sudo ufw allow 443/tcp

# K3s API (필요시)
sudo ufw allow 6443/tcp
```

## 설치 방법

### 1. cert-manager 설치

```bash
# cert-manager 네임스페이스 생성
kubectl create namespace cert-manager

# CRD 설치
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml

# Helm으로 cert-manager 설치
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.13.3 \
  --set installCRDs=false

# 설치 확인
kubectl get pods -n cert-manager
```

### 2. ClusterIssuer 생성

`ingress.yaml`의 이메일 주소를 실제 이메일로 변경:

```yaml
email: admin@mireu.xyz  # 실제 이메일로 변경
```

```bash
# ClusterIssuer 생성
kubectl apply -f ingress.yaml
```

### 3. Basic Auth 비밀번호 변경

현재 기본 비밀번호는 `admin:admin`입니다. 반드시 변경하세요!

```bash
# htpasswd 설치 (없는 경우)
sudo apt-get install apache2-utils

# 새 비밀번호 생성 (예: 사용자 admin, 비밀번호 입력)
htpasswd -nb admin your-secure-password

# 출력 결과를 base64 인코딩
htpasswd -nb admin your-secure-password | base64

# 출력된 값을 ingress.yaml의 Secret에 복사
```

`ingress.yaml` 수정:
```yaml
data:
  users: <BASE64_ENCODED_VALUE>
```

### 4. Ingress 배포

```bash
# Ingress 리소스 배포
kubectl apply -f ingress.yaml

# Ingress 확인
kubectl get ingress -A
```

### 5. 인증서 발급 확인

```bash
# Certificate 상태 확인
kubectl get certificate -A

# cert-manager 로그 확인
kubectl logs -n cert-manager -l app=cert-manager -f

# 인증서 상세 정보
kubectl describe certificate jupyter-tls -n datascience
```

## 서비스 접속

### JupyterHub

```
https://jupyter.mireu.xyz
```

- Google OAuth 로그인
- 인증서 자동 적용

### Spark Master UI

```
https://spark.mireu.xyz
```

- Basic Auth 인증 필요
- 기본: `admin` / `admin` (변경 필수!)

### Spark History Server

```
https://spark-history.mireu.xyz
```

- Basic Auth 인증 필요
- Spark 작업 이력 조회

### Hadoop NameNode UI

```
https://hadoop.mireu.xyz
```

- Basic Auth 인증 필요
- HDFS 상태 및 파일 시스템 관리

## 문제 해결

### 인증서 발급 실패

#### 1. Challenge 상태 확인

```bash
# Challenge 리소스 확인
kubectl get challenges -A

# 상세 정보
kubectl describe challenge -n datascience <challenge-name>
```

#### 2. CloudFlare Proxy 비활성화 확인

CloudFlare에서 해당 도메인의 Proxy status가 "DNS only"인지 확인

#### 3. HTTP-01 Challenge 테스트

```bash
# Let's Encrypt가 접근할 수 있는지 확인
curl http://jupyter.mireu.xyz/.well-known/acme-challenge/test
```

#### 4. cert-manager 로그 확인

```bash
kubectl logs -n cert-manager -l app=cert-manager --tail=100
```

#### 5. Staging 환경으로 테스트

`ingress.yaml`에서 ClusterIssuer를 `letsencrypt-staging`으로 변경:

```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-staging
```

Staging 환경은 Rate Limit이 없어 테스트에 적합합니다.

### 인증서 수동 갱신

```bash
# 인증서 삭제 (자동 재발급됨)
kubectl delete certificate jupyter-tls -n datascience

# Secret 삭제
kubectl delete secret jupyter-tls -n datascience

# Ingress 재배포
kubectl apply -f ingress.yaml
```

### Ingress 작동 안 함

#### 1. Traefik 상태 확인

```bash
# K3s의 Traefik Pod 확인
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik

# Traefik 로그
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik
```

#### 2. Ingress 상태 확인

```bash
# Ingress 리소스
kubectl get ingress -n datascience

# 상세 정보
kubectl describe ingress jupyterhub-ingress -n datascience
```

#### 3. Service 연결 확인

```bash
# Service 존재 확인
kubectl get svc -n datascience proxy-public

# Service 엔드포인트 확인
kubectl get endpoints -n datascience proxy-public
```

### DNS 확인

```bash
# DNS 조회
nslookup jupyter.mireu.xyz

# Dig 사용
dig jupyter.mireu.xyz +short

# 실제 서버 IP와 일치하는지 확인
curl -I http://jupyter.mireu.xyz
```

## 보안 설정

### 1. Basic Auth 비밀번호 관리

```bash
# 강력한 비밀번호 생성
openssl rand -base64 32

# htpasswd로 해시 생성
htpasswd -nbB admin "$(openssl rand -base64 32)"
```

### 2. IP 화이트리스트 (선택사항)

특정 IP에서만 접근 허용:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: ip-whitelist
  namespace: datascience
spec:
  ipWhiteList:
    sourceRange:
      - "192.168.1.0/24"
      - "10.0.0.0/8"
```

Ingress에 적용:
```yaml
annotations:
  traefik.ingress.kubernetes.io/router.middlewares: datascience-ip-whitelist@kubernetescrd
```

### 3. Rate Limiting

DDoS 방지:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
  namespace: datascience
spec:
  rateLimit:
    average: 100
    burst: 50
```

### 4. CORS 설정

외부 도메인에서 API 접근 시:

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: cors-headers
  namespace: datascience
spec:
  headers:
    accessControlAllowMethods:
      - "GET"
      - "POST"
      - "PUT"
      - "DELETE"
    accessControlAllowOriginList:
      - "https://your-frontend.com"
    accessControlMaxAge: 100
    addVaryHeader: true
```

## CloudFlare 추가 설정

### 1. SSL/TLS 모드

CloudFlare Dashboard > SSL/TLS > Overview:
- **Encryption mode**: Full (strict) 또는 Full
- "DNS only"로 설정했다면 영향 없음

### 2. Firewall Rules

CloudFlare Dashboard > Security > WAF:
- 원하는 보안 규칙 설정
- Challenge/Block 설정

### 3. Page Rules

특정 URL에 대한 캐싱 정책:
- JupyterHub: 캐시 비활성화
- Static files: 캐시 활성화

## 모니터링

### 인증서 만료 확인

```bash
# 모든 인증서 상태
kubectl get certificate -A

# 특정 인증서 상세 정보
kubectl describe certificate jupyter-tls -n datascience | grep "Not After"
```

### Ingress 트래픽 모니터링

```bash
# Traefik 메트릭 확인
kubectl port-forward -n kube-system svc/traefik 9000:9000

# 브라우저에서 http://localhost:9000/metrics 접속
```

### 로그 수집

```bash
# 모든 Ingress 이벤트
kubectl get events -A --sort-by='.lastTimestamp' | grep Ingress

# Traefik 로그 (실시간)
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik -f
```

## 백업

### Ingress 설정 백업

```bash
# 모든 Ingress 리소스 백업
kubectl get ingress -A -o yaml > ingress-backup.yaml

# 모든 Certificate 백업
kubectl get certificate -A -o yaml > certificate-backup.yaml

# 모든 Secret (TLS) 백업
kubectl get secret -A -l cert-manager.io/certificate-name -o yaml > tls-secrets-backup.yaml
```

## 확장

### 새 서비스 추가

1. Ingress 리소스 생성:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: newservice-ingress
  namespace: your-namespace
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - newservice.mireu.xyz
    secretName: newservice-tls
  rules:
  - host: newservice.mireu.xyz
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: newservice
            port:
              number: 80
```

2. CloudFlare에 DNS 레코드 추가
3. 배포 및 확인

```bash
kubectl apply -f newservice-ingress.yaml
kubectl get certificate -n your-namespace
```

## Rate Limits

Let's Encrypt Rate Limits:
- **Production**: 50 certificates per registered domain per week
- **Staging**: Rate limits 없음 (테스트용)

테스트 시에는 반드시 Staging ClusterIssuer를 사용하세요!
