#!/usr/bin/env bash
set -euo pipefail
# 디스크 초기화 및 마운트 스크립트 (주의: 파티션/포맷을 수행합니다)
# 사용 전 반드시 DEVICE_NVME와 DEVICE_HDD 값을 확인하세요.

DEVICE_NVME=${DEVICE_NVME:-/dev/nvme0n1}
DEVICE_HDD=${DEVICE_HDD:-/dev/sdb}
MOUNT_NVME=${MOUNT_NVME:-/mnt/nvme}
MOUNT_HDD=${MOUNT_HDD:-/mnt/hdd}

echo "== 디스크 초기화 스크립트 =="
echo "NVMe: $DEVICE_NVME -> $MOUNT_NVME"
echo "HDD:  $DEVICE_HDD -> $MOUNT_HDD"

confirm() {
  read -r -p "계속 하시겠습니까? (yes/[no]): " ans
  if [[ "$ans" != "yes" ]]; then
    echo "취소됨"
    exit 1
  fi
}

if [[ $(id -u) -ne 0 ]]; then
  echo "루트로 실행하세요. 예: sudo $0"
  exit 1
fi

echo "중요: 이 스크립트는 지정한 디스크의 모든 데이터를 삭제합니다."
confirm

prepare_device() {
  local dev=$1
  local mountpoint=$2

  if [ ! -b "$dev" ]; then
    echo "블록 디바이스 $dev 가 없습니다. 스킵합니다."
    return 0
  fi

  # 언마운트
  if mountpoint -q "$mountpoint"; then
    echo "$mountpoint 언마운트 중..."
    umount "$mountpoint" || true
  fi

  echo "기존 파일시스템 제거: wipefs $dev"
  wipefs -a "$dev" || true

  echo "파티션 테이블 생성 (GPT)"
  parted -s "$dev" mklabel gpt
  parted -s -a optimal "$dev" mkpart primary 0% 100%

  part="${dev}1"
  # NVMe 디바이스 이름은 nvme0n1p1 또는 nvme0n1p1? 대부분 nvme0n1p1
  if [[ "$dev" =~ nvme ]]; then
    part="${dev}p1"
  fi

  echo "파티션: $part 생성 완료. 파일시스템 만들기 (ext4)"
  mkfs.ext4 -F "$part"

  mkdir -p "$mountpoint"
  uuid=$(blkid -s UUID -o value "$part")
  if ! grep -q "$uuid" /etc/fstab 2>/dev/null; then
    echo "UUID=$uuid $mountpoint ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
  mount "$mountpoint"
  echo "$dev -> $mountpoint 마운트 완료"
}

prepare_device "$DEVICE_NVME" "$MOUNT_NVME"
prepare_device "$DEVICE_HDD" "$MOUNT_HDD"

echo "디스크 준비 완료"
