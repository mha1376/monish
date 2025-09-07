#!/usr/bin/env bash
set -euo pipefail

command_exists() { command -v "$1" >/dev/null 2>&1; }

humanize_seconds() {
  local s=$1 d h m
  d=$((s/86400)); s=$((s%86400))
  h=$((s/3600)); s=$((s%3600))
  m=$((s/60))
  local out=""
  [[ $d -gt 0 ]] && out+="${d}d "
  [[ $h -gt 0 ]] && out+="${h}h "
  out+="${m}m"
  echo "$out"
}

run_ssh() {
  local host=$1 user=$2 port=$3 auth=$4 key=$5 opts=$6 cmd=$7
  local ssh_cmd=(ssh -p "$port")
  IFS=' ' read -r -a extra <<<"$opts"
  ssh_cmd+=("${extra[@]}")
  if [[ $auth == key ]]; then
    ssh_cmd+=(-i "$key")
  elif [[ $auth == password ]]; then
    command_exists sshpass || return 1
    ssh_cmd=(sshpass -p "${SSH_PASSWORD:-}" "${ssh_cmd[@]}")
  fi
  ssh_cmd+=("$user@$host" "$cmd")
  "${ssh_cmd[@]}"
}

limit_jobs() {
  local max=$1
  while [[ $(jobs -p | wc -l) -ge $max ]]; do
    wait -n 2>/dev/null || true
  done
}
