#!/bin/bash
set -euo pipefail

if ! declare -f log_info >/dev/null; then
    DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    source "$DIR/util.sh"
fi

deploy_apache() {
    local domain="$1"
    local cert_dir="$2"
    
    local target_dir="/etc/apache2/ssl/$domain"
    log_info "Deploying to Apache ($target_dir)"
    
    mkdir -p "$target_dir"
    cp -L "$cert_dir/$domain/fullchain.pem" "$target_dir/fullchain.pem.tmp"
    cp -L "$cert_dir/$domain/privkey.pem" "$target_dir/privkey.pem.tmp"
    
    mv "$target_dir/fullchain.pem.tmp" "$target_dir/fullchain.pem"
    mv "$target_dir/privkey.pem.tmp" "$target_dir/privkey.pem"
    
    if command -v apachectl >/dev/null 2>&1; then
        apachectl configtest

        if command -v systemctl >/dev/null 2>&1; then
            log_info "Reloading Apache via systemctl..."
            systemctl reload apache2
        elif command -v rc-service >/dev/null 2>&1; then
            log_info "Reloading Apache via OpenRC..."
            rc-service apache2 reload
        else
            log_info "Reloading Apache directly..."
            apachectl graceful
        fi
    elif command -v httpd >/dev/null 2>&1; then
        httpd -t

        if command -v rc-service >/dev/null 2>&1; then
            log_info "Reloading Apache via OpenRC..."
            rc-service apache2 reload
        else
            log_info "Reloading Apache directly..."
            httpd -k graceful
        fi
    else
        log_info "Apache binary not found locally. Certificates deployed to $target_dir; reload the web server container/service externally."
    fi
}
