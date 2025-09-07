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

# render_json data
# Renders the collected data as a JSON array. Each line of input is treated
# as a server name. Host and uptime fields are left empty for now.
render_json() {
  local data="$1"
  local first=true
  printf '['
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    if $first; then
      first=false
    else
      printf ','
    fi
    local json_line
    json_line=$(render_json_line "$line" "" "" | tr -d '\n')
    printf '\n  %s' "$json_line"
  done <<< "$data"
  printf '\n]\n'
}

# render_table data
# Displays the collected data in a simple table. Each line of input is
# rendered on its own line under a "NAME" header.
render_table() {
  local data="$1"
  tput clear 2>/dev/null || true
  printf '%-20s\n' "NAME"
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf '%-20s\n' "$line"
  done <<< "$data"
}
