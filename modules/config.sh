#!/usr/bin/env bash

# Parse configuration file setting variables in the calling shell.
# Lines beginning with # or ; are ignored as comments. # or ; inside
# quotes are preserved.

parse_config() {
    local file="$1"
    local key value
    SERVER_NAME=""
    REFRESH_SEC=3
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
            SERVER_NAME="${SERVER_NAME:+$SERVER_NAME }${BASH_REMATCH[1]}"
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
                host|port|user|auth|key_path|ssh_options|concurrency|ping_count|ping_timeout)
                    printf -v "$key" '%s' "$value"
                    ;;
            esac
        fi
    done < "$file"
}
