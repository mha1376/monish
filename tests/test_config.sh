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

test_invalid_key_rejected() {
    local cfg
    cfg=$(mktemp)
    cat <<'CFG' > "$cfg"
badkey=value
CFG
    parse_config "$cfg"
    [[ -z "${badkey+x}" ]]
}

test_command_injection_ignored() {
    local cfg tmp
    cfg=$(mktemp)
    tmp=$(mktemp)
    rm "$tmp"
    cat <<CFG > "$cfg"
user=\$(touch "$tmp")
CFG
    parse_config "$cfg"
    [[ "$user" == "\$(touch \"$tmp\")" && ! -e "$tmp" ]]
}

test_server_sections() {
    local cfg
    cfg=$(mktemp)
    cat <<'CFG' > "$cfg"
[defaults]
refresh_sec=5

[server "alpha"]
host=localhost
[server "beta"]
host=localhost
CFG
    parse_config "$cfg"
    [[ "$SERVER_NAME" == "alpha beta" && "$REFRESH_SEC" == "5" ]]
}

test_refresh_default() {
    local cfg
    cfg=$(mktemp)
    cat <<'CFG' > "$cfg"
[server "alpha"]
host=localhost
CFG
    unset REFRESH_SEC
    parse_config "$cfg"
    [[ "$REFRESH_SEC" == "3" ]]
}

run_tests() {
    test_hash_in_quotes && pass "hash_in_quotes" || fail "hash_in_quotes"
    unset ssh_options user
    test_hash_outside_quotes && pass "hash_outside_quotes" || fail "hash_outside_quotes"
    unset ssh_options user
    test_semicolon_in_quotes && pass "semicolon_in_quotes" || fail "semicolon_in_quotes"
    unset ssh_options user badkey
    test_invalid_key_rejected && pass "invalid_key_rejected" || fail "invalid_key_rejected"
    unset ssh_options user badkey
    test_command_injection_ignored && pass "command_injection_ignored" || fail "command_injection_ignored"
    unset ssh_options user badkey
    test_server_sections && pass "server_sections" || fail "server_sections"
    unset SERVER_NAME REFRESH_SEC
    test_refresh_default && pass "refresh_default" || fail "refresh_default"
}

run_tests

