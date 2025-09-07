#!/usr/bin/env bash
set -euo pipefail

declare -Ag DEFAULTS=()
declare -ag SERVER_NAME SERVER_HOST SERVER_USER SERVER_PORT SERVER_AUTH SERVER_KEY_PATH SERVER_SSH_OPTIONS

parse_config() {
  local file="$1"
  local section="" name="" idx=-1 line key value
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%%#*}; line=${line%%;*}
    line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [[ -z $line ]] && continue
    if [[ $line == "[defaults]" ]]; then
      section=defaults
      continue
    elif [[ $line == \[server* ]]; then
      name=${line#"[server \""}
      name=${name%"\"]"}
      section=server
      ((idx++))
      SERVER_NAME[idx]="$name"
      continue
    fi
    if [[ $line == *=* ]]; then
      key=$(echo "${line%%=*}" | tr -d ' ')
      value=$(echo "${line#*=}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//')
      if [[ $section == defaults ]]; then
        DEFAULTS[$key]="$value"
      elif [[ $section == server ]]; then
        case $key in
          host) SERVER_HOST[idx]="$value";;
          user) SERVER_USER[idx]="$value";;
          port) SERVER_PORT[idx]="$value";;
          auth) SERVER_AUTH[idx]="$value";;
          key_path) SERVER_KEY_PATH[idx]="$value";;
          ssh_options) SERVER_SSH_OPTIONS[idx]="$value";;
        esac
      fi
    fi
  done < "$file"

  local total=$((idx+1))
  for i in $(seq 0 $((total-1))); do
    : "${SERVER_HOST[i]:?Missing host for ${SERVER_NAME[i]}}"
    SERVER_USER[i]=${SERVER_USER[i]:-${DEFAULTS[user]:-root}}
    SERVER_PORT[i]=${SERVER_PORT[i]:-${DEFAULTS[port]:-22}}
    SERVER_AUTH[i]=${SERVER_AUTH[i]:-${DEFAULTS[auth]:-agent}}
    SERVER_KEY_PATH[i]=${SERVER_KEY_PATH[i]:-${DEFAULTS[key_path]:-$HOME/.ssh/id_rsa}}
    SERVER_SSH_OPTIONS[i]=${SERVER_SSH_OPTIONS[i]:-${DEFAULTS[ssh_options]:-"-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no"}}
  done
  SERVER_COUNT=$total
  REFRESH_SEC=${DEFAULTS[refresh_sec]:-3}
  CONCURRENCY=${DEFAULTS[concurrency]:-10}
  PING_COUNT=${DEFAULTS[ping_count]:-1}
  PING_TIMEOUT=${DEFAULTS[ping_timeout]:-1}
}
