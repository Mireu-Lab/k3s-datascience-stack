#!/usr/bin/env bash
set -euo pipefail
# k3s 설치 스크립트 (containerd 사용)

K3S_VERSION=${K3S_VERSION:-}

if command -v k3s >/dev/null 2>&1; then
  echo "k3s가 이미 설치되어 있습니다. 버전: $(k3s --version || true)"
  echo "설치를 건너뜁니다. 만약 재설치하려면 scripts/uninstall_k3s.sh을 먼저 실행하세요."
  exit 0
fi

echo "k3s 설치를 시작합니다..."

export INSTALL_K3S_EXEC="--container-runtime-endpoint unix:///run/containerd/containerd.sock --disable=traefik"
if [[ -n "$K3S_VERSION" ]]; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" sh -
else
  curl -sfL https://get.k3s.io | sh -
fi

echo "k3s 설치 완료. kubeconfig는 /etc/rancher/k3s/k3s.yaml 입니다."
