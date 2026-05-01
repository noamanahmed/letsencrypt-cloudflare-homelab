#!/bin/bash
set -euo pipefail

# source util.sh if not sourced
if ! declare -f log_error >/dev/null; then
    DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    source "$DIR/util.sh"
fi

validate_env() {
    log_info "Validating environment..."
    
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Must run as root"
        exit 1
    fi

    local required_cmds=("certbot" "openssl" "curl" "dig" "grep" "awk" "sed")
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required command missing: $cmd"
            exit 1
        fi
    done

    # Check for certbot cloudflare plugin
    if ! PYTHONWARNINGS="ignore" certbot plugins 2>&1 | grep -iq cloudflare; then
        log_error "certbot cloudflare plugin is not installed. (python3-certbot-dns-cloudflare or certbot-dns-cloudflare)"
        exit 1
    fi

    log_info "Environment validation passed."
}
