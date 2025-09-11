#!/usr/bin/env bash
# Collector utilities for assembling server output
#
# This script writes each server's output to numbered files in a temporary
# directory. When collecting the results, the files are read back in
# numeric filename order so that the server output order matches the
# order provided in the SERVER_NAME variable.

collect_servers() {
    [[ -n ${SERVER_NAME:-} ]] || { echo "SERVER_NAME not set" >&2; return 1; }
    local tmpdir
    tmpdir=$(mktemp -d)
    local i=0
    for server in $SERVER_NAME; do
        printf '%s\n' "$server" > "$tmpdir/$i"
        i=$((i + 1))
    done

    # Concatenate each file in numeric order of the filename to preserve
    # the order of SERVER_NAME. Using a numeric glob avoids relying on
    # the contents of the files for ordering.
    for f in "$tmpdir"/[0-9]*; do
        cat "$f"
    done

    rm -rf "$tmpdir"
}

# collect_remote: run a command on each configured server via SSH.
# Outputs the server name followed by a tab and the command result.
collect_remote() {
    [[ -n ${SERVER_NAME:-} ]] || { echo "SERVER_NAME not set" >&2; return 1; }
    local cmd=${1:-uptime}
    for server in $SERVER_NAME; do
        local host=${HOST[$server]}
        local user=${USER[$server]}
        local port=${PORT[$server]:-22}
        local auth=${AUTH[$server]:-key}
        local key=${KEY_PATH[$server]:-}
        local opts=${SSH_OPTIONS[$server]:-}
        local password=${PASSWORD[$server]:-}
        local output
        SSH_PASSWORD="$password" output=$(run_ssh "$host" "$user" "$port" "$auth" "$key" "$opts" "$cmd")
        printf '%s\t%s\n' "$server" "$output"
    done
}

# collect_disk_usage: fetch disk usage percentage for each server's root filesystem.
# Uses df -h / and extracts the percentage used column.
collect_disk_usage() {
    [[ -n ${SERVER_NAME:-} ]] || { echo "SERVER_NAME not set" >&2; return 1; }
    for server in $SERVER_NAME; do
        local host=${HOST[$server]}
        local user=${USER[$server]}
        local port=${PORT[$server]:-22}
        local auth=${AUTH[$server]:-key}
        local key=${KEY_PATH[$server]:-}
        local opts=${SSH_OPTIONS[$server]:-}
        local password=${PASSWORD[$server]:-}
        local cmd="df -h / --output=pcent | tail -n 1 | awk '{\$1=\$1};1'"
        local usage
        SSH_PASSWORD="$password" usage=$(run_ssh "$host" "$user" "$port" "$auth" "$key" "$opts" "$cmd")
        printf '%s\t%s\n' "$server" "$usage"
    done
}

# collect_ram_usage: fetch RAM usage percentage (used/total) for each server.
# Uses free -m and extracts the used memory percentage.
collect_ram_usage() {
    [[ -n ${SERVER_NAME:-} ]] || { echo "SERVER_NAME not set" >&2; return 1; }
    for server in $SERVER_NAME; do
        local host=${HOST[$server]}
        local user=${USER[$server]}
        local port=${PORT[$server]:-22}
        local auth=${AUTH[$server]:-key}
        local key=${KEY_PATH[$server]:-}
        local opts=${SSH_OPTIONS[$server]:-}
        local password=${PASSWORD[$server]:-}
        local cmd="free -m | awk '/^Mem:/ {printf \"%d%%\", (\$3/\$2)*100}'"
        local usage
        SSH_PASSWORD="$password" usage=$(run_ssh "$host" "$user" "$port" "$auth" "$key" "$opts" "$cmd")
        printf '%s\t%s\n' "$server" "$usage"
    done
}

# collect_all: gather data from all configured collectors. Currently this
# collects remote command output, disk usage, and RAM usage for each server,
# returning tab-separated fields: name, command output, disk usage, ram usage.
collect_all() {
    [[ -n ${SERVER_NAME:-} ]] || { echo "SERVER_NAME not set" >&2; return 1; }
    local cmd=${1:-uptime}
    declare -A _disk _ram
    while IFS=$'\t' read -r srv du; do
        _disk["$srv"]="$du"
    done < <(collect_disk_usage)
    while IFS=$'\t' read -r srv ru; do
        _ram["$srv"]="$ru"
    done < <(collect_ram_usage)
    while IFS=$'\t' read -r srv out; do
        printf '%s\t%s\t%s\t%s\n' "$srv" "$out" "${_disk[$srv]}" "${_ram[$srv]}"
    done < <(collect_remote "$cmd")
}
