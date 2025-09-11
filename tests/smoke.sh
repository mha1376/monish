#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/modules/render.sh"

# Use a server name containing quotes to ensure escaping works
json_output=$(render_json_line 'server "alpha"' '42.0')

echo "$json_output"

# Validate JSON using jq
echo "$json_output" | jq -e . >/dev/null