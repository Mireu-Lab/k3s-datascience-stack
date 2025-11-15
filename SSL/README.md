# SSL 인증서 디렉토리

이 디렉토리는 SSL/TLS 인증서를 저장하는 곳입니다.

## 자동 SSL 인증서 (Let's Encrypt)

Traefik이 자동으로 Let's Encrypt를 통해 SSL 인증서를 발급받습니다.
- 인증서는 Traefik Pod 내부의 PVC에 저장됩니다.
- 수동 인증서 관리가 필요하지 않습니다.

## 수동 SSL 인증서 (선택사항)

자체 SSL 인증서를 사용하려면:

1. 인증서 파일을 이 디렉토리에 배치:
   - `mireu.xyz.crt` (인증서)
   - `mireu.xyz.key` (개인키)
   - `ca-bundle.crt` (CA 체인, 선택사항)

2. Kubernetes Secret 생성:
```bash
kubectl create secret tls mireu-xyz-tls \
  --cert=SSL/mireu.xyz.crt \
  --key=SSL/mireu.xyz.key \
  -n traefik
```

3. IngressRoute에서 Secret 참조:
```yaml
spec:
  tls:
    secretName: mireu-xyz-tls
```

## 참고

- Let's Encrypt는 90일마다 자동 갱신됩니다
- 와일드카드 인증서는 DNS-01 challenge가 필요합니다
- HTTP-01 challenge는 포트 80이 외부에서 접근 가능해야 합니다
