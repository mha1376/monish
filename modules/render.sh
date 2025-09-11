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

# render_json_line name ram_usage
# Renders a single JSON object with provided fields
render_json_line() {
  local name ram
  name="$(escape_json "$1")"
  ram="$(escape_json "$2")"
  printf '{"name":"%s","ram_usage":"%s"}\n' "$name" "$ram"
}

# render_json data
# Renders the collected data as a JSON array. Each line of input is expected
# to be in the form "name<TAB>ram_usage".
render_json() {
  local data="$1"
  local first=true
  printf '['
  while IFS=$'\t' read -r name ram || [[ -n "$name" ]]; do
    [[ -z "$name" ]] && continue
    if $first; then
      first=false
    else
      printf ','
    fi
    local json_line
    json_line=$(render_json_line "$name" "$ram" | tr -d '\n')
    printf '\n  %s' "$json_line"
  done <<< "$data"
  printf '\n]\n'
}

# render_table data
# Displays the collected data in a table with NAME and RAM% columns.
render_table() {
  local data="$1"
  tput clear 2>/dev/null || true
  printf '%-20s%-10s\n' "NAME" "RAM%"
  while IFS=$'\t' read -r name ram || [[ -n "$name" ]]; do
    [[ -z "$name" ]] && continue
    printf '%-20s%-10s\n' "$name" "$ram"
  done <<< "$data"
}
