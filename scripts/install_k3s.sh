#!/usr/bin/env bash
set -euo pipefail
# k3s 설치 스크립트 (containerd 사용)

# 디버그: 환경변수 DEBUG=true 로 실행하면 더 자세한 출력
DEBUG=${DEBUG:-false}
if [ "$DEBUG" = "true" ]; then
  set -x
fi

K3S_VERSION=${K3S_VERSION:-}

LOGFILE=${LOGFILE:-/var/log/install_k3s.log}
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
chmod 0644 "$LOGFILE" || true

log() {
  echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') - $*" | tee -a "$LOGFILE"
}

err_trap() {
  rc=$?
  log "오류 발생 (exit code $rc). 로그 파일: $LOGFILE"
  exit $rc
}
trap err_trap ERR

if command -v k3s >/dev/null 2>&1; then
  log "k3s가 이미 설치되어 있습니다. 버전: $(k3s --version || true)"
  log "설치를 건너뜁니다. 재설치하거나 제거하려면 scripts/uninstall_k3s.sh 사용"
  exit 0
fi

log "k3s 설치를 시작합니다..."

# 필요한 도구 확인
if ! command -v curl >/dev/null 2>&1; then
  log "curl을 찾을 수 없어 설치합니다..."
  apt-get update
  apt-get install -y --no-install-recommends curl
fi

# 기본 실행 옵션
export INSTALL_K3S_EXEC="--container-runtime-endpoint unix:///run/containerd/containerd.sock --disable=traefik"

# 간단한 네트워크/접근성 검사
if ! curl -fsS --max-time 10 https://get.k3s.io >/dev/null 2>&1; then
  log "https://get.k3s.io 에 접근할 수 없습니다. 네트워크 또는 DNS를 확인하세요."
  exit 2
fi

# k3s 설치 (출력은 로그에 기록)
if [[ -n "$K3S_VERSION" ]]; then
  log "지정된 K3S_VERSION=$K3S_VERSION 으로 설치를 수행합니다. (출력: $LOGFILE)"
  curl -fsL https://get.k3s.io 2>>"$LOGFILE" | INSTALL_K3S_VERSION="$K3S_VERSION" sh - >>"$LOGFILE" 2>&1
else
  log "최신 k3s 설치를 수행합니다. (출력: $LOGFILE)"
  curl -fsL https://get.k3s.io 2>>"$LOGFILE" | sh - >>"$LOGFILE" 2>&1
fi

log "k3s 설치 완료. kubeconfig는 /etc/rancher/k3s/k3s.yaml 입니다."
log "설치 로그는 $LOGFILE 에 기록되어 있습니다. 문제가 있으면 해당 파일을 확인하세요."
