#!/bin/sh
# Run a binary repeatedly and count segfaults / hangs.
# Usage: ./test.sh <binary> [count] [timeout_sec]
set -e

binary="${1:?Usage: $0 <binary> [count] [timeout_sec]}"
count="${2:-200}"
timeout_sec="${3:-3}"

fail=0
hang=0
for i in $(seq 1 "$count"); do
  timeout "$timeout_sec" "$binary" > /dev/null 2>&1
  rc=$?
  if [ $rc -eq 139 ]; then
    fail=$((fail+1))
  elif [ $rc -eq 124 ]; then
    hang=$((hang+1))
  elif [ $rc -ne 0 ]; then
    fail=$((fail+1))
  fi
done
echo "$(basename "$binary"): segfault=$fail hang=$hang / $count"
