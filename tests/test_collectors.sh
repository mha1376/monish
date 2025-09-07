#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/modules/collectors.sh"

# Regression test: the output of collect_servers must match the order of
# SERVER_NAME. This previously failed because the implementation sorted by
# file contents rather than numeric filename.

SERVER_NAME="100 5 20"
result="$(collect_servers)"
# Command substitution strips the trailing newline, so the expected string
# deliberately omits it as well.
expected=$'100\n5\n20'
if [ "$result" != "$expected" ]; then
    echo "Expected:\n$expected" >&2
    echo "Got:\n$result" >&2
    exit 1
fi

# collect_all should currently behave identically to collect_servers
result_all="$(collect_all)"
if [ "$result_all" != "$expected" ]; then
    echo "collect_all mismatch" >&2
    echo "Expected:\n$expected" >&2
    echo "Got:\n$result_all" >&2
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

