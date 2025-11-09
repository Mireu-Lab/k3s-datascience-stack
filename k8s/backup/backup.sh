#!/usr/bin/env bash
set -euo pipefail
# /backup.sh
# NVMe에 저장된 'cold' 이전 대상(예: /mnt/nvme)에서 7일 이상 된 파일을
# /mnt/hdd 로 이동하여 압축 후 GCS로 업로드.

NVME_MOUNT=${NVME_MOUNT:-/mnt/nvme}
HDD_MOUNT=${HDD_MOUNT:-/mnt/hdd}
GCS_BUCKET=${GCS_BUCKET:-}

if [[ -z "$GCS_BUCKET" ]]; then
  echo "GCS_BUCKET 환경변수를 설정하세요 (예: gs://my-bucket)"
  exit 1
fi

TMPDIR=$(mktemp -d)
cd "$NVME_MOUNT"
find . -type f -mtime +7 -print0 | while IFS= read -r -d $'\0' file; do
  full="$NVME_MOUNT/$file"
  destdir="$HDD_MOUNT/$(dirname "$file")"
  mkdir -p "$destdir"
  archive="$TMPDIR/$(basename "$file").tar.gz"
  tar -czf "$archive" -C "$NVME_MOUNT" "$file"
  mv "$archive" "$destdir/"
  rm -f "$full"
  echo "압축 및 이동: $file -> $destdir"
  # 업로드
  if command -v gsutil >/dev/null 2>&1; then
    gsutil cp "$destdir/$(basename "$archive")" "$GCS_BUCKET/"
  else
    echo "gsutil이 존재하지 않아 GCS 업로드를 건너뜁니다."
  fi
done

rm -rf "$TMPDIR"
echo "백업 완료"
