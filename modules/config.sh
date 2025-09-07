#!/usr/bin/env bash

# Parse configuration file setting variables in the calling shell.
# Lines beginning with # or ; are ignored as comments. # or ; inside
# quotes are preserved.

parse_config() {
    local file="$1"
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

        if [[ "$line" == *"="* ]]; then
            local key="${line%%=*}"
            local value="${line#*=}"
            key="${key%"${key##*[![:space:]]}"}"
            value="${value#"${value%%[![:space:]]*}"}"
            eval "$key=$value"
        fi
    done < "$file"
}