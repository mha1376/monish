#!/usr/bin/env bash
set -euo pipefail

# color helpers
init_colors() {
  RESET=$(tput sgr0)
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  GREY=$(tput setaf 8)
  BOLD=$(tput bold)
}

color_load() { local v=$1; awk -v v="$v" -v g="$GREEN" -v y="$YELLOW" -v r="$RED" 'BEGIN{if(v<1)print g; else if(v<2)print y; else print r}'; }
color_percent() { local v=$1; awk -v v="$v" -v g="$GREEN" -v y="$YELLOW" -v r="$RED" 'BEGIN{if(v<70)print g; else if(v<85)print y; else print r}'; }
color_ping() { local v=$1; if [[ -z $v ]]; then echo "$GREY"; else awk -v v="$v" -v g="$GREEN" -v y="$YELLOW" -v r="$RED" 'BEGIN{if(v<50)print g; else if(v<150)print y; else print r}'; fi }

render_table() {
  init_colors
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  tput clear
  printf "%smonish%s - %s refresh %ss (q to quit)\n" "$BOLD" "$RESET" "$ts" "$REFRESH_SEC"
  printf "%s%-12s %-20s %-8s %-8s %-6s %-6s %-12s %-6s%s\n" "$BOLD" "NAME" "HOST" "PING(ms)" "LOAD1" "RAM%" "DISK%" "UPTIME" "STATUS" "$RESET"
  while IFS=$'\t' read -r name host ping load mem disk up status; do
    local pl cl cm cd cs
    pl=$(color_ping "$ping"); cl=$(color_load "$load"); cm=$(color_percent "$mem"); cd=$(color_percent "$disk")
    cs=$GREEN
    [[ $status != OK ]] && cs=$RED
    printf "%-12s %-20s %s%-8s%s %s%-8s%s %s%-6s%s %s%-6s%s %-12s %s%-6s%s\n" \
      "$name" "${host:0:20}" "$pl" "${ping:-"---"}" "$RESET" "$cl" "$load" "$RESET" "$cm" "$mem" "$RESET" "$cd" "$disk" "$RESET" "$up" "$cs" "$status" "$RESET"
  done <<< "$1"
}

json_num() { [[ -z $1 ]] && echo null || echo "$1"; }

render_json() {
  local lines="$1" first=1 ts
  ts=$(date -Iseconds)
  printf '['
  while IFS=$'\t' read -r name host ping load mem disk up status; do
    [[ $first -eq 0 ]] && printf ','
    printf '\n  {"name":"%s","host":"%s","ping_ms":%s,"load1":%s,"ram_pct":%s,"disk_pct":%s,"uptime":"%s","status":"%s","ts":"%s"}' \
      "$name" "$host" "$(json_num "$ping")" "$(json_num "$load")" "$(json_num "$mem")" "$(json_num "$disk")" "$up" "$status" "$ts"
    first=0
  done <<< "$lines"
  printf '\n]\n'
}
