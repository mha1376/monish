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

# collect_remote / collect_all should return command results for each server
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
    if [[ $cmd == "df -h / --output=pcent | tail -n 1" ]]; then
        if [[ $host == host1 ]]; then
            echo "10%"
        else
            echo "20%"
        fi
    elif [[ $cmd == *"free -m"* ]]; then
        if [[ $host == host1 ]]; then
            echo "30%"
        else
            echo "40%"
        fi
    else
        echo "$user@$host:$cmd"
    fi
}

expected_remote=$'alpha\tuser1@host1:uptime\nbeta\tuser2@host2:uptime'
result_remote="$(collect_remote uptime)"
if [ "$result_remote" != "$expected_remote" ]; then
    echo "collect_remote mismatch" >&2
    echo "Expected:\n$expected_remote" >&2
    echo "Got:\n$result_remote" >&2
    exit 1
fi

expected_disk=$'alpha\t10%\nbeta\t20%'
result_disk="$(collect_disk_usage)"
if [ "$result_disk" != "$expected_disk" ]; then
    echo "collect_disk_usage mismatch" >&2
    echo "Expected:\n$expected_disk" >&2
    echo "Got:\n$result_disk" >&2
    exit 1
fi

expected_ram=$'alpha\t30%\nbeta\t40%'
result_ram="$(collect_ram_usage)"
if [ "$result_ram" != "$expected_ram" ]; then
    echo "collect_ram_usage mismatch" >&2
    echo "Expected:\n$expected_ram" >&2
    echo "Got:\n$result_ram" >&2
    exit 1
fi

expected_all=$'alpha\tuser1@host1:uptime\t10%\t30%\nbeta\tuser2@host2:uptime\t20%\t40%'
result_all="$(collect_all uptime)"
if [ "$result_all" != "$expected_all" ]; then
    echo "collect_all mismatch" >&2
    echo "Expected:\n$expected_all" >&2
    echo "Got:\n$result_all" >&2
    exit 1
fi

data=$'alpha\tuser1@host1:uptime\t10%\t30%\nbeta\tuser2@host2:uptime\t20%\t40%'
expected_json=$'[
  {"name":"alpha","host":"","uptime":"user1@host1:uptime","disk_usage":"10%","ram_usage":"30%"},
  {"name":"beta","host":"","uptime":"user2@host2:uptime","disk_usage":"20%","ram_usage":"40%"}
]'
result_json="$(render_json "$data")"
if [ "$result_json" != "$expected_json" ]; then
    echo "render_json mismatch" >&2
    echo "Expected:\n$expected_json" >&2
    echo "Got:\n$result_json" >&2
    exit 1
fi

tput() { :; }
result_table="$(render_table "$data")"
expected_table=$(printf '%-20s %-20s %-10s %-10s\n' "NAME" "UPTIME" "DISK%" "RAM%"; \
                 printf '%-20s %-20s %-10s %-10s\n' "alpha" "user1@host1:uptime" "10%" "30%"; \
                 printf '%-20s %-20s %-10s %-10s' "beta" "user2@host2:uptime" "20%" "40%")
if [ "$result_table" != "$expected_table" ]; then
    echo "render_table mismatch" >&2
    echo "Expected:\n$expected_table" >&2
    echo "Got:\n$result_table" >&2
    exit 1
fi

