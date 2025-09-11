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

# render_json_line name host uptime disk_usage ram_usage
# Renders a single JSON object with provided fields
render_json_line() {
  local name host uptime disk_usage ram_usage
  name="$(escape_json "$1")"
  host="$(escape_json "$2")"
  uptime="$(escape_json "$3")"
  disk_usage="$(escape_json "$4")"
  ram_usage="$(escape_json "$5")"
  printf '{"name":"%s","host":"%s","uptime":"%s","disk_usage":"%s","ram_usage":"%s"}\n' "$name" "$host" "$uptime" "$disk_usage" "$ram_usage"
}

# render_json data
# Renders the collected data as a JSON array. Each input line is expected to be
# tab-separated fields: name, uptime, disk usage, ram usage. Host is omitted for now.
render_json() {
  local data="$1"
  local first=true
  printf '['
  while IFS=$'\t' read -r name uptime disk_usage ram_usage || [[ -n "$name" ]]; do
    [[ -z "$name" ]] && continue
    if $first; then
      first=false
    else
      printf ','
    fi
    local json_line
    json_line=$(render_json_line "$name" "" "$uptime" "$disk_usage" "$ram_usage" | tr -d '\n')
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
  printf '%-20s %-20s %-10s %-10s\n' "NAME" "UPTIME" "DISK%" "RAM%"
  while IFS=$'\t' read -r name uptime disk_usage ram_usage || [[ -n "$name" ]]; do
    [[ -z "$name" ]] && continue
    printf '%-20s %-20s %-10s %-10s\n' "$name" "$uptime" "$disk_usage" "$ram_usage"
  done <<< "$data"
}
