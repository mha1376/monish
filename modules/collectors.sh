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

# collect_all: gather data from all configured collectors. For now this
# simply returns the server names in the order provided by SERVER_NAME.
# This placeholder prevents the main script from failing when invoking
# collect_all and can be extended with additional collectors later.
collect_all() {
    collect_servers
}
