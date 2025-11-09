#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
  echo "루트로 실행하세요. 예: sudo $0"
  exit 1
fi

if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
  echo "k3s 제거 스크립트 실행 중..."
  /usr/local/bin/k3s-uninstall.sh
  echo "k3s 제거 완료"
else
  echo "k3s 제거 스크립트를 찾을 수 없습니다. 수동으로 제거를 시도합니다..."
  systemctl stop k3s || true
  systemctl disable k3s || true
  rm -rf /etc/rancher /var/lib/rancher /var/lib/kubelet /var/lib/containerd /var/lib/etcd || true
  echo "기본 디렉토리 제거 완료 (남은 파일은 수동 확인 필요)"
fi
