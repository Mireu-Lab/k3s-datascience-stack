# 데이터 자동 백업 시스템

이 디렉토리는 Hot -> Cold -> Archive 데이터 자동 백업 시스템 설정을 포함합니다.

## 데이터 계층 정책

| 계층 | 저장소 | 기간 | 압축 | 설명 |
|------|--------|------|------|------|
| **Hot Data** | NVME SSD | 최대 2일 | 없음 | 활발히 사용되는 데이터 |
| **Cold Data** | HDD | 2일 ~ 1주일 | gzip | 백업된 데이터 |
| **Archive Data** | GCP Storage | 1주일 이상 | gzip | 장기 보관 데이터 |

## 구성 요소

### 1. Hot to Cold Backup (hot-to-cold-backup)
- **스케줄**: 매일 새벽 2시
- **작업**: 2일 이상 지난 파일을 HDD로 이동 및 압축
- **검증**: MD5 체크섬으로 파일 무결성 확인
- **중복 제거**: 이미 백업된 파일은 체크섬 비교 후 스킵

### 2. Cold to Archive Backup (cold-to-archive-backup)
- **스케줄**: 매주 일요일 새벽 3시
- **작업**: 1주일 이상 지난 압축 파일을 GCP Storage로 업로드
- **검증**: GCS 체크섬으로 업로드 확인
- **중복 제거**: 이미 아카이브된 파일은 체크섬 비교 후 스킵

### 3. Cleanup Empty Directories (cleanup-empty-dirs)
- **스케줄**: 매일 새벽 4시
- **작업**: 빈 디렉토리 삭제

## 설치 방법

### 1. GCP Service Account 설정

GCP Console에서:
1. Service Account 생성
2. 권한 부여: "Storage Object Admin"
3. JSON 키 다운로드

### 2. GCP Storage Bucket 생성

```bash
# GCP CLI로 버킷 생성
gcloud storage buckets create gs://YOUR_BUCKET_NAME \
  --location=asia-northeast3 \
  --storage-class=ARCHIVE
```

### 3. Secret 생성

`../05-jupyterhub/secrets.yaml`에 GCP credentials 설정 또는:

```bash
kubectl create secret generic gcp-storage-credentials \
  -n storage \
  --from-file=credentials.json=/path/to/your/credentials.json
```

### 4. ConfigMap 수정

`cronjobs.yaml`의 `cold-to-archive.sh` 스크립트에서:
- `GCS_BUCKET`: 실제 버킷 이름으로 변경
- `CLOUDSDK_CORE_PROJECT`: GCP 프로젝트 ID로 변경

### 5. CronJob 배포

```bash
kubectl apply -f cronjobs.yaml
```

### 6. 배포 확인

```bash
# CronJob 목록
kubectl get cronjobs -n storage

# Job 실행 이력
kubectl get jobs -n storage

# 특정 Job 로그
kubectl logs -n storage job/hot-to-cold-backup-<timestamp>
```

## 수동 실행

### Hot to Cold 백업 수동 실행

```bash
kubectl create job -n storage \
  --from=cronjob/hot-to-cold-backup \
  hot-to-cold-manual-$(date +%s)

# 로그 확인
kubectl logs -n storage -l job-name=hot-to-cold-manual-<timestamp> -f
```

### Cold to Archive 백업 수동 실행

```bash
kubectl create job -n storage \
  --from=cronjob/cold-to-archive-backup \
  cold-to-archive-manual-$(date +%s)

# 로그 확인
kubectl logs -n storage -l job-name=cold-to-archive-manual-<timestamp> -f
```

## 백업 스크립트 설명

### hot-to-cold.sh

1. `/mnt/nvme/hot-data`에서 2일 이상 지난 파일 검색
2. 각 파일의 MD5 체크섬 계산
3. 대상 파일이 이미 존재하면 체크섬 비교
4. 변경된 파일만 gzip 압축하여 `/mnt/hdd/cold-data`로 복사
5. 백업 성공 확인 후 원본 파일 삭제

### cold-to-archive.sh

1. `/mnt/hdd/cold-data`에서 1주일 이상 지난 `.gz` 파일 검색
2. GCP Service Account로 인증
3. 각 파일의 MD5 체크섬 계산
4. GCS에 이미 존재하면 체크섬 비교
5. 변경된 파일만 GCS로 업로드
6. 업로드 성공 확인 후 원본 파일 삭제

### cleanup-empty-dirs.sh

1. Hot Data와 Cold Data 경로에서 빈 디렉토리 검색
2. 빈 디렉토리 삭제

## 체크섬 검증

모든 백업 작업은 MD5 체크섬을 사용하여 파일 무결성을 보장합니다:

```bash
# 원본 파일 체크섬
md5sum /path/to/file

# 압축 파일 체크섬
gunzip -c /path/to/file.gz | md5sum

# GCS 파일 체크섬
gsutil hash -m gs://bucket/path/to/file.gz
```

## 모니터링

### CronJob 상태 확인

```bash
# 모든 CronJob 상태
kubectl get cronjobs -n storage

# 최근 실행된 Job
kubectl get jobs -n storage --sort-by=.metadata.creationTimestamp
```

### 실패한 Job 확인

```bash
# 실패한 Job 목록
kubectl get jobs -n storage --field-selector status.successful=0

# 실패한 Job 로그
kubectl logs -n storage job/<job-name>
```

### 백업 통계

```bash
# Hot Data 사용량
kubectl exec -n storage <any-pod> -- du -sh /mnt/nvme/hot-data

# Cold Data 사용량
kubectl exec -n storage <any-pod> -- du -sh /mnt/hdd/cold-data

# GCS 사용량
gsutil du -sh gs://YOUR_BUCKET_NAME/archive
```

## 스케줄 변경

### Hot to Cold 백업 스케줄 변경

```yaml
spec:
  schedule: "0 2 * * *"  # 매일 새벽 2시 (Cron 표현식)
```

Cron 표현식 예시:
- `0 2 * * *`: 매일 2시
- `0 */6 * * *`: 6시간마다
- `0 2 * * 1`: 매주 월요일 2시
- `0 2 1 * *`: 매월 1일 2시

### 보관 기간 변경

`cronjobs.yaml`의 스크립트에서:

```bash
# Hot to Cold: 2일 -> 3일로 변경
DAYS=3

# Cold to Archive: 7일 -> 14일로 변경
DAYS=14
```

## 복구 방법

### Cold Data에서 복구

```bash
# 압축 해제
gunzip /mnt/hdd/cold-data/path/to/file.gz

# Hot Data로 복사
cp /mnt/hdd/cold-data/path/to/file /mnt/nvme/hot-data/path/to/file
```

### Archive에서 복구

```bash
# GCS에서 다운로드
gsutil cp gs://YOUR_BUCKET_NAME/archive/path/to/file.gz /tmp/

# 압축 해제
gunzip /tmp/file.gz

# 원하는 위치로 복사
cp /tmp/file /mnt/nvme/hot-data/path/to/file
```

### 대량 복구

```bash
# 특정 디렉토리 전체 복구
gsutil -m cp -r gs://YOUR_BUCKET_NAME/archive/project1/ /tmp/restore/

# 압축 해제
find /tmp/restore -name "*.gz" -exec gunzip {} \;

# Hot Data로 복사
cp -r /tmp/restore/* /mnt/nvme/hot-data/
```

## 비용 최적화

### GCS Storage Class

Archive 데이터는 GCS Archive Storage Class 사용 권장:
- 가장 저렴한 스토리지
- 접근 빈도가 낮은 데이터에 적합
- 최소 보관 기간: 365일

```bash
# 버킷 생성 시 Storage Class 지정
gcloud storage buckets create gs://YOUR_BUCKET_NAME \
  --storage-class=ARCHIVE
```

### 수명 주기 정책

오래된 아카이브 자동 삭제:

```bash
# lifecycle.json 생성
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 3650,
          "matchesPrefix": ["archive/"]
        }
      }
    ]
  }
}
EOF

# 정책 적용
gsutil lifecycle set lifecycle.json gs://YOUR_BUCKET_NAME
```

## 문제 해결

### 백업 실패

```bash
# Job 이벤트 확인
kubectl describe job -n storage <job-name>

# Pod 로그 확인
kubectl logs -n storage <pod-name>

# Pod 상태 확인
kubectl get pods -n storage -l job-name=<job-name>
```

### 권한 오류

```bash
# GCP 인증 확인
kubectl exec -n storage <pod-name> -- gcloud auth list

# 버킷 권한 확인
gsutil iam get gs://YOUR_BUCKET_NAME
```

### 디스크 부족

```bash
# 스토리지 사용량 확인
kubectl exec -n storage <pod-name> -- df -h

# 큰 파일 찾기
kubectl exec -n storage <pod-name> -- du -h /mnt/nvme/hot-data | sort -rh | head -20
```

## 알림 설정

백업 실패 시 알림을 받으려면 Kubernetes Events를 모니터링하거나 Prometheus Alertmanager를 설정하세요.

### 이메일 알림 예시 (Alertmanager)

```yaml
- alert: BackupJobFailed
  expr: kube_job_status_failed{namespace="storage"} > 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Backup job failed in storage namespace"
    description: "Job {{ $labels.job_name }} has failed"
```

## 보안 고려사항

### Secrets 보호

```bash
# Secret 암호화 (Sealed Secrets 사용)
kubeseal --format=yaml < secrets.yaml > sealed-secrets.yaml
```

### 네트워크 정책

백업 Job은 인터넷 접근이 필요합니다 (GCS):
```yaml
egress:
  - to:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 443
```

### 감사 로그

GCS 접근 로그 활성화:
```bash
gsutil logging set on -b gs://logs-bucket gs://YOUR_BUCKET_NAME
```
