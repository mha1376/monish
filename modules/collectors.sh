#!/usr/bin/env bash
# Collector utilities for assembling server output
#
# This script writes each server's output to numbered files in a temporary
# directory. When collecting the results, the files are read back in
# numeric filename order so that the server output order matches the
# order provided in the SERVER_NAME variable.

collect_servers() {
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

