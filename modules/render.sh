#!/usr/bin/env bash
set -euo pipefail

# escape_json: escape characters in a string for safe JSON embedding
# Replaces backslashes and double quotes with escaped versions
escape_json() {
  local input="$1"
  input="${input//\\/\\\\}"  # escape backslashes
  input="${input//\"/\\\"}"  # escape double quotes
  printf '%s' "$input"
}

# render_json_line name host uptime
# Renders a single JSON object with provided fields
render_json_line() {
  local name host uptime
  name="$(escape_json "$1")"
  host="$(escape_json "$2")"
  uptime="$(escape_json "$3")"
  printf '{"name":"%s","host":"%s","uptime":"%s"}\n' "$name" "$host" "$uptime"
}
