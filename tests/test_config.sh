#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../modules/config.sh"

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; exit 1; }

test_hash_in_quotes() {
    local cfg
    cfg=$(mktemp)
    cat <<'CFG' > "$cfg"
ssh_options="ProxyCommand ssh -W %h:%p jump#host"
CFG
    parse_config "$cfg"
    [[ "$ssh_options" == 'ProxyCommand ssh -W %h:%p jump#host' ]]
}

test_hash_outside_quotes() {
    local cfg
    cfg=$(mktemp)
    cat <<'CFG' > "$cfg"
user=me # comment
CFG
    parse_config "$cfg"
    [[ "$user" == 'me' ]]
}

test_semicolon_in_quotes() {
    local cfg
    cfg=$(mktemp)
    cat <<'CFG' > "$cfg"
ssh_options="ProxyCommand ssh -W %h:%p jump;host"
CFG
    parse_config "$cfg"
    [[ "$ssh_options" == 'ProxyCommand ssh -W %h:%p jump;host' ]]
}

run_tests() {
    test_hash_in_quotes && pass "hash_in_quotes" || fail "hash_in_quotes"
    unset ssh_options user
    test_hash_outside_quotes && pass "hash_outside_quotes" || fail "hash_outside_quotes"
    unset ssh_options user
    test_semicolon_in_quotes && pass "semicolon_in_quotes" || fail "semicolon_in_quotes"
}

run_tests

