#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../modules/config.sh"

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; exit 1; }

test_hash_in_quotes() {
    local cfg
    cfg=$(mktemp)
    cat <<'CFG' > "$cfg"
[server "alpha"]
ssh_options="ProxyCommand ssh -W %h:%p jump#host"
CFG
    parse_config "$cfg"
    [[ "${SSH_OPTIONS[alpha]}" == 'ProxyCommand ssh -W %h:%p jump#host' ]]
}

test_hash_outside_quotes() {
    local cfg
    cfg=$(mktemp)
    cat <<'CFG' > "$cfg"
[server "alpha"]
user=me # comment
CFG
    parse_config "$cfg"
    [[ "${USER[alpha]}" == 'me' ]]
}

test_semicolon_in_quotes() {
    local cfg
    cfg=$(mktemp)
    cat <<'CFG' > "$cfg"
[server "alpha"]
ssh_options="ProxyCommand ssh -W %h:%p jump;host"
CFG
    parse_config "$cfg"
    [[ "${SSH_OPTIONS[alpha]}" == 'ProxyCommand ssh -W %h:%p jump;host' ]]
}

test_invalid_key_rejected() {
    local cfg
    cfg=$(mktemp)
    cat <<'CFG' > "$cfg"
[server "alpha"]
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
[server "alpha"]
user=\$(touch "$tmp")
CFG
    parse_config "$cfg"
    [[ "${USER[alpha]}" == "\$(touch \"$tmp\")" && ! -e "$tmp" ]]
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

test_password_key() {
    local cfg
    cfg=$(mktemp)
    cat <<'CFG' > "$cfg"
[server "alpha"]
password=s3cr3t
CFG
    parse_config "$cfg"
    [[ "${PASSWORD[alpha]}" == 's3cr3t' && -z ${SSH_PASSWORD+x} ]]
}

run_tests() {
    test_hash_in_quotes && pass "hash_in_quotes" || fail "hash_in_quotes"
    unset SSH_OPTIONS USER
    test_hash_outside_quotes && pass "hash_outside_quotes" || fail "hash_outside_quotes"
    unset SSH_OPTIONS USER
    test_semicolon_in_quotes && pass "semicolon_in_quotes" || fail "semicolon_in_quotes"
    unset SSH_OPTIONS USER badkey
    test_invalid_key_rejected && pass "invalid_key_rejected" || fail "invalid_key_rejected"
    unset SSH_OPTIONS USER badkey
    test_command_injection_ignored && pass "command_injection_ignored" || fail "command_injection_ignored"
    unset SSH_OPTIONS USER badkey
    test_server_sections && pass "server_sections" || fail "server_sections"
    unset SERVER_NAME REFRESH_SEC
    test_refresh_default && pass "refresh_default" || fail "refresh_default"
    unset PASSWORD SSH_PASSWORD
    test_password_key && pass "password_key" || fail "password_key"
}

run_tests

