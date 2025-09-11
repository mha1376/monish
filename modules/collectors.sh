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

# collect_ram_usage: run `free -m` on each server and report used/total %
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
        local output pct
        SSH_PASSWORD="$password" output=$(run_ssh "$host" "$user" "$port" "$auth" "$key" "$opts" "free -m")
        pct=$(awk '/^Mem:/ {printf "%.1f", ($3/$2)*100}' <<<"$output")
        printf '%s\t%s\n' "$server" "$pct"
    done
}

# collect_all: gather data from all configured collectors. Currently this
# returns RAM usage for each server.
collect_all() {
    collect_ram_usage
}
