#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$REPO_ROOT/.pre-commit/systemd-verify-root"
SYSTEM_UNIT_DIR="$ROOT/etc/systemd/system"
LIB_UNIT_DIR="$ROOT/usr/lib/systemd/system"

mkdir -p "$SYSTEM_UNIT_DIR" "$LIB_UNIT_DIR" "$ROOT/var/usrlocal/bin" "$ROOT/var/mnt/sg1" "$ROOT/usr/bin"

if [[ ! -x "$ROOT/var/usrlocal/bin/rclone-notify.sh" ]]; then
  printf '#!/bin/sh\n' >"$ROOT/var/usrlocal/bin/rclone-notify.sh"
  chmod +x "$ROOT/var/usrlocal/bin/rclone-notify.sh"
fi
if [[ ! -x "$ROOT/usr/bin/rclone" ]]; then
  printf '#!/bin/sh\n' >"$ROOT/usr/bin/rclone"
  chmod +x "$ROOT/usr/bin/rclone"
fi

for target in sysinit.target basic.target multi-user.target; do
  if [[ ! -f "$LIB_UNIT_DIR/$target" && -f "/usr/lib/systemd/system/$target" ]]; then
    cp "/usr/lib/systemd/system/$target" "$LIB_UNIT_DIR/"
  fi
done

status=0
for f in "$@"; do
  unit="$(basename "$f")"
  cp "$f" "$SYSTEM_UNIT_DIR/$unit"
  if ! systemd-analyze --root="$ROOT" verify "/etc/systemd/system/$unit"; then
    status=1
  fi
done
exit "$status"
