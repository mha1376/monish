#!/usr/bin/env bash
set -euo pipefail

# assumes config arrays and util functions loaded

collect_local() {
  local load mem disk up
  load=$(awk '{print $1}' /proc/loadavg)
  mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2} END{printf "%.0f",(1-a/t)*100}' /proc/meminfo)
  disk=$(df -P / | awk 'NR==2{print $5}' | tr -d '%')
  if command_exists uptime && uptime -p >/dev/null 2>&1; then
    up=$(uptime -p | sed 's/^up //')
  else
    up=$(awk '{print int($1)}' /proc/uptime)
    up=$(humanize_seconds "$up")
  fi
  printf '%s\t%s\t%s\t%s\n' "$load" "$mem" "$disk" "$up"
}

collect_remote() {
  local host=$1 user=$2 port=$3 auth=$4 key=$5 opts=$6
  local cmd='load=$(awk '\''{print $1}'\'' /proc/loadavg);\
mem=$(awk '\''/MemTotal/{t=$2}/MemAvailable/{a=$2} END{printf "%.0f",(1-a/t)*100}'\'' /proc/meminfo);\
disk=$(df -P / | awk '\''NR==2{print $5}'\'' | tr -d "%");\
up=$(awk '\''{print int($1)}'\'' /proc/uptime);\
printf "%s %s %s %s\n" "$load" "$mem" "$disk" "$up"'
  if out=$(run_ssh "$host" "$user" "$port" "$auth" "$key" "$opts" "$cmd" 2>/dev/null); then
    read -r load mem disk up <<<"$out"
    up=$(humanize_seconds "$up")
    printf '%s\t%s\t%s\t%s\n' "$load" "$mem" "$disk" "$up"
    return 0
  fi
  return 1
}

collect_one_server() {
  local i=$1 name host user port auth key opts
  name=${SERVER_NAME[i]}
  host=${SERVER_HOST[i]}
  user=${SERVER_USER[i]}
  port=${SERVER_PORT[i]}
  auth=${SERVER_AUTH[i]}
  key=${SERVER_KEY_PATH[i]}
  opts=${SERVER_SSH_OPTIONS[i]}

  local ping_ms="" status="OK" load="" mem="" disk="" up=""
  if out=$(ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$host" 2>/dev/null); then
    ping_ms=$(echo "$out" | awk -F'time=' '/time=/{print $2}' | cut -d' ' -f1)
  fi
  if [[ $host == "localhost" || $host == "127.0.0.1" ]]; then
    if out=$(collect_local); then
      read -r load mem disk up <<<"$out"
    else
      status="ERR"
    fi
  else
    if out=$(collect_remote "$host" "$user" "$port" "$auth" "$key" "$opts"); then
      read -r load mem disk up <<<"$out"
    else
      status="ERR"
    fi
  fi
  [[ -z $load || -z $mem || -z $disk || -z $up ]] && status="ERR"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$host" "$ping_ms" "$load" "$mem" "$disk" "$up" "$status"
}

collect_all() {
  local tmpdir=$(mktemp -d)
  for i in $(seq 0 $((SERVER_COUNT-1))); do
    limit_jobs "$CONCURRENCY"
    collect_one_server "$i" >"$tmpdir/$i" &
  done
  wait
  sort -n "$tmpdir"/* 2>/dev/null | cat
  rm -rf "$tmpdir"
}
