#!/bin/bash
# 데이터 티어링 CronJob 배포 스크립트

# CronJob 배포
kubectl apply -f 01-data-tiering-cronjob.yaml

# 설치 확인
kubectl get cronjobs -n hadoop
kubectl get configmaps -n hadoop | grep data-tiering

echo "데이터 티어링 CronJob 배포 완료!"
echo ""
echo "스케줄:"
echo "  - Hot -> Cold: 매일 오전 2시"
echo "  - Cold -> Archive: 매일 오전 4시"
echo ""
echo "로그 확인:"
echo "  kubectl logs -n hadoop -l job-name=data-tiering-hot-to-cold"
echo "  kubectl logs -n hadoop -l job-name=data-tiering-cold-to-archive"
