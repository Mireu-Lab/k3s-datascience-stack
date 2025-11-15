#!/bin/bash
# 데이터 티어링 CronJob 제거 스크립트

echo "데이터 티어링 CronJob 제거 중..."

kubectl delete -f 01-data-tiering-cronjob.yaml --ignore-not-found

echo "데이터 티어링 CronJob 제거 완료!"
