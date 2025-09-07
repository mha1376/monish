#!/usr/bin/env bash
set -euo pipefail

# Monish main entrypoint

VERSION="0.1.0"

print_help() {
  cat <<'HLP'
monish - lightweight server monitor
Usage: ./monish.sh [options]
  -c, --config FILE   config file path (default: ./monish.conf or ./monish.conf.example)
      --once          run one iteration and exit
      --json          output JSON (implies --once)
      --version       show version
      --help          this help
HLP
}

CONFIG=""; ONCE=false; JSON=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config)
      CONFIG="$2"; shift 2;;
    --once)
      ONCE=true; shift;;
    --json)
      JSON=true; ONCE=true; shift;;
    --version)
      echo "$VERSION"; exit 0;;
    --help)
      print_help; exit 0;;
    *)
      echo "Unknown option: $1" >&2; exit 1;;
  esac
done

if [[ -z "$CONFIG" ]]; then
  if [[ -f ./monish.conf ]]; then
    CONFIG=./monish.conf
  else
    CONFIG=./monish.conf.example
  fi
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=modules/util.sh
source "$SCRIPT_DIR/modules/util.sh"
# shellcheck source=modules/config.sh
source "$SCRIPT_DIR/modules/config.sh"
# shellcheck source=modules/collectors.sh
source "$SCRIPT_DIR/modules/collectors.sh"
# shellcheck source=modules/render.sh
source "$SCRIPT_DIR/modules/render.sh"

parse_config "$CONFIG"

cleanup() {
  stty sane 2>/dev/null || true
  $JSON || tput cnorm 2>/dev/null || true
}
trap cleanup EXIT INT TERM

main_loop() {
  $JSON || tput civis 2>/dev/null || true
  while true; do
    local data
    data=$(collect_all)
    if $JSON; then
      render_json "$data"
      break
    else
      render_table "$data"
    fi
    $ONCE && break
    local key=""
    read -t "$REFRESH_SEC" -n 1 key && [[ $key == "q" ]] && break
  done
}

main_loop
