# 데이터 티어링 자동화 CronJob

## 개요
Hadoop HDFS 데이터를 자동으로 티어링하는 시스템:
1. **Hot Data (NVME SSD)**: 최대 2일 보관
2. **Cold Data (SATA HDD)**: 2일 후 자동 이동, 최소 2일 보관
3. **Archive Data (GCS)**: 1주일 후 tar.xz 압축하여 GCS로 백업

## 실행 스케줄
- Hot → Cold: 매일 오전 2시
- Cold → Archive: 매일 오전 4시
- 파일 체크섬 검증: 데이터 이동 전후

## 설치 명령어
```bash
kubectl apply -f 01-data-tiering-cronjob.yaml
```
