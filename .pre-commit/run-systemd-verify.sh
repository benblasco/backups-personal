#!/usr/bin/env bash
set -euo pipefail
for f in "$@"; do
  systemd-analyze verify "$f"
done
