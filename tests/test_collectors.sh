#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/modules/collectors.sh"
source "$ROOT_DIR/modules/config.sh"
source "$ROOT_DIR/modules/render.sh"

# Regression test: the output of collect_servers must match the order of
# SERVER_NAME provided by the config file. This previously failed because the
# implementation sorted by file contents rather than numeric filename.

cq=$(mktemp)
cat <<'CFG' > "$cq"
[server "100"]
host=localhost
[server "5"]
host=localhost
[server "20"]
host=localhost
CFG
parse_config "$cq"
if env | grep -q '^SERVER_NAME='; then
    echo "SERVER_NAME should not be exported" >&2
    exit 1
fi
result="$(collect_servers)"
# Command substitution strips the trailing newline, so the expected string
# deliberately omits it as well.
expected=$'100\n5\n20'
if [ "$result" != "$expected" ]; then
    echo "Expected:\n$expected" >&2
    echo "Got:\n$result" >&2
    exit 1
fi

# collect_servers should fail when SERVER_NAME is unset
unset SERVER_NAME
if output=$(collect_servers 2>&1); then
    echo "expected collect_servers to fail without SERVER_NAME" >&2
    exit 1
fi
if [[ "$output" != "SERVER_NAME not set" ]]; then
    echo "unexpected error: $output" >&2
    exit 1
fi

# collect_remote should return command results for each server
cfg=$(mktemp)
cat <<'CFG' > "$cfg"
[server "alpha"]
host=host1
user=user1
[server "beta"]
host=host2
user=user2
CFG
parse_config "$cfg"

run_ssh() {
    local host=$1 user=$2 port=$3 auth=$4 key=$5 opts=$6 cmd=$7
    echo "$user@$host:$cmd"
}

expected_remote=$'alpha\tuser1@host1:uptime\nbeta\tuser2@host2:uptime'
result_remote="$(collect_remote uptime)"
if [ "$result_remote" != "$expected_remote" ]; then
    echo "collect_remote mismatch" >&2
    echo "Expected:\n$expected_remote" >&2
    echo "Got:\n$result_remote" >&2
    exit 1
fi

# collect_ram_usage / collect_all should report RAM percentage per server
run_ssh() {
    local host=$1
    if [[ $host == host1 ]]; then
        printf '%s\n' "              total        used        free" "Mem:          1000         400         600"
    else
        printf '%s\n' "              total        used        free" "Mem:          2000        1500         500"
    fi
}

expected_ram=$'alpha\t40.0\nbeta\t75.0'
result_ram="$(collect_ram_usage)"
if [ "$result_ram" != "$expected_ram" ]; then
    echo "collect_ram_usage mismatch" >&2
    echo "Expected:\n$expected_ram" >&2
    echo "Got:\n$result_ram" >&2
    exit 1
fi

result_all="$(collect_all)"
if [ "$result_all" != "$expected_ram" ]; then
    echo "collect_all mismatch" >&2
    echo "Expected:\n$expected_ram" >&2
    echo "Got:\n$result_all" >&2
    exit 1
fi

# Rendering helpers
tput() { :; }
json="$(render_json "$result_all")"
expected_json=$'[\n  {"name":"alpha","ram_usage":"40.0"},\n  {"name":"beta","ram_usage":"75.0"}\n]'
if [ "$json" != "$expected_json" ]; then
    echo "render_json mismatch" >&2
    echo "Expected:\n$expected_json" >&2
    echo "Got:\n$json" >&2
    exit 1
fi

table="$(render_table "$result_all")"
expected_table=$(printf '%-20s%-10s\n' "NAME" "RAM%"; printf '%-20s%-10s\n' "alpha" "40.0"; printf '%-20s%-10s\n' "beta" "75.0")
if [ "$table" != "$expected_table" ]; then
    echo "render_table mismatch" >&2
    echo "Expected:\n$expected_table" >&2
    echo "Got:\n$table" >&2
    exit 1
fi

