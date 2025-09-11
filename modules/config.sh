#!/usr/bin/env bash

# Parse configuration file setting variables in the calling shell.
# Lines beginning with # or ; are ignored as comments. # or ; inside
# quotes are preserved.

parse_config() {
    local file="$1"
    local key value current_server=""
    local default_host="" default_port="" default_user="" default_auth=""
    local default_key_path="" default_ssh_options="" default_password=""
    local default_concurrency="" default_ping_count="" default_ping_timeout=""
    SERVER_NAME=""
    REFRESH_SEC=3
    declare -gA HOST USER PORT AUTH KEY_PATH SSH_OPTIONS PASSWORD CONCURRENCY PING_COUNT PING_TIMEOUT
    HOST=()
    USER=()
    PORT=()
    AUTH=()
    KEY_PATH=()
    SSH_OPTIONS=()
    PASSWORD=()
    CONCURRENCY=()
    PING_COUNT=()
    PING_TIMEOUT=()
    local section_re='^\[server[[:space:]]+"([^"]+)"\]$'
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Use awk to strip comments only when outside quotes
        line=$(printf '%s\n' "$line" | awk '{
            inquote=0; out="";
            for(i=1;i<=length($0);i++){
                c=substr($0,i,1);
                if(c=="\"") inquote=1-inquote;
                if((c=="#" || c==";") && inquote==0) break;
                out=out c;
            }
            sub(/[ \t]+$/, "", out);
            print out;
        }')

        # Trim leading whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* || "$line" == \;* ]] && continue

        if [[ $line =~ $section_re ]]; then
            current_server="${BASH_REMATCH[1]}"
            SERVER_NAME="${SERVER_NAME:+$SERVER_NAME }$current_server"
            HOST["$current_server"]="$default_host"
            USER["$current_server"]="$default_user"
            PORT["$current_server"]="$default_port"
            AUTH["$current_server"]="$default_auth"
            KEY_PATH["$current_server"]="$default_key_path"
            SSH_OPTIONS["$current_server"]="$default_ssh_options"
            PASSWORD["$current_server"]="$default_password"
            CONCURRENCY["$current_server"]="$default_concurrency"
            PING_COUNT["$current_server"]="$default_ping_count"
            PING_TIMEOUT["$current_server"]="$default_ping_timeout"
            continue
        fi

        if [[ "$line" == *"="* ]]; then
            key="${line%%=*}"
            value="${line#*=}"
            key="${key%"${key##*[![:space:]]}"}"
            value="${value#"${value%%[![:space:]]*}"}"

            if [[ ${#value} -ge 2 ]]; then
                first="${value:0:1}"
                last="${value: -1}"
                if [[ ( $first == '"' && $last == '"' ) || ( $first == "'" && $last == "'" ) ]]; then
                    value="${value:1:-1}"
                fi
            fi

            [[ $value == ~* ]] && value="${value/#~/$HOME}"

            case "$key" in
                refresh_sec)
                    REFRESH_SEC="$value"
                    ;;
                host|port|user|auth|key_path|ssh_options|password|concurrency|ping_count|ping_timeout)
                    if [[ -n "$current_server" ]]; then
                        case "$key" in
                            host)        HOST["$current_server"]="$value" ;;
                            port)        PORT["$current_server"]="$value" ;;
                            user)        USER["$current_server"]="$value" ;;
                            auth)        AUTH["$current_server"]="$value" ;;
                            key_path)    KEY_PATH["$current_server"]="$value" ;;
                            ssh_options) SSH_OPTIONS["$current_server"]="$value" ;;
                            password)    PASSWORD["$current_server"]="$value" ;;
                            concurrency) CONCURRENCY["$current_server"]="$value" ;;
                            ping_count)  PING_COUNT["$current_server"]="$value" ;;
                            ping_timeout) PING_TIMEOUT["$current_server"]="$value" ;;
                        esac
                    else
                        case "$key" in
                            host)        default_host="$value" ;;
                            port)        default_port="$value" ;;
                            user)        default_user="$value" ;;
                            auth)        default_auth="$value" ;;
                            key_path)    default_key_path="$value" ;;
                            ssh_options) default_ssh_options="$value" ;;
                            password)    default_password="$value" ;;
                            concurrency) default_concurrency="$value" ;;
                            ping_count)  default_ping_count="$value" ;;
                            ping_timeout) default_ping_timeout="$value" ;;
                        esac
                    fi
                    ;;
            esac
        fi
    done < "$file"
}
