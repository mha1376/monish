#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

out=$(./monish.sh --json --once -c monish.conf.example)
echo "$out" | grep -q '^\['
if command -v jq >/dev/null 2>&1; then
  echo "$out" | jq -e '. | length >= 1' >/dev/null
else
  echo "$out" | grep -q '"status"'
fi
echo "smoke test passed"
