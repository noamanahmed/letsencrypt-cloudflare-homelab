#!/bin/bash
set -euo pipefail

if ! declare -f log_info >/dev/null; then
    DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    source "$DIR/util.sh"
fi

deploy_nginx() {
    local domain="$1"
    local cert_dir="$2"
    
    local target_dir="/etc/nginx/ssl/$domain"
    log_info "Deploying to Nginx ($target_dir)"
    
    mkdir -p "$target_dir"
    cp -L "$cert_dir/$domain/fullchain.pem" "$target_dir/fullchain.pem.tmp"
    cp -L "$cert_dir/$domain/privkey.pem" "$target_dir/privkey.pem.tmp"
    
    mv "$target_dir/fullchain.pem.tmp" "$target_dir/fullchain.pem"
    mv "$target_dir/privkey.pem.tmp" "$target_dir/privkey.pem"
    
    if command -v systemctl >/dev/null 2>&1; then
        log_info "Reloading Nginx via systemctl..."
        nginx -t && systemctl reload nginx
    else
        log_info "Reloading Nginx directly (systemctl not found)..."
        nginx -t && nginx -s reload
    fi
}
