#!/bin/bash
set -euo pipefail

if ! declare -f log_info >/dev/null; then
    DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    source "$DIR/util.sh"
fi

check_expiry() {
    local cert_file="$1"
    local renew_days="$2"

    if [ ! -f "$cert_file" ]; then
        log_info "No certificate found at $cert_file. Needs issuance."
        return 0 # Needs renewal/issuance
    fi

    local end_date
    end_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
    local end_epoch
    end_epoch=$(date -d "$end_date" +%s)
    local now_epoch
    now_epoch=$(date +%s)
    
    local days_left=$(( (end_epoch - now_epoch) / 86400 ))
    log_info "Certificate expires in $days_left days."

    if [ "$days_left" -lt "$renew_days" ]; then
        log_info "Certificate expires in less than $renew_days days. Renewal required."
        return 0 # Needs renewal
    fi

    log_info "Certificate is still valid for more than $renew_days days."
    return 1 # Valid
}

run_certbot() {
    local domain="$1"
    local email="$2"
    local token="$3"
    local prop_seconds="$4"
    local config_dir="/etc/lecf"

    mkdir -p "$config_dir"
    local creds_file="$config_dir/cloudflare.ini"
    
    # Store credentials
    echo "dns_cloudflare_api_token = $token" > "$creds_file"
    chmod 600 "$creds_file"

    log_info "Running certbot for $domain and *.$domain..."
    PYTHONWARNINGS="ignore" certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials "$creds_file" \
        --dns-cloudflare-propagation-seconds "$prop_seconds" \
        --non-interactive \
        --agree-tos \
        --email "$email" \
        -d "$domain" \
        -d "*.$domain"

    # Cleanup credentials
    rm -f "$creds_file"
    log_info "Certbot execution completed successfully."
}

copy_certs() {
    local domain="$1"
    local dest_dir="$2"

    local src_dir="/etc/letsencrypt/live/$domain"
    local target_dir="$dest_dir/$domain"

    if [ ! -d "$src_dir" ]; then
        log_error "Source certificate directory not found: $src_dir"
        exit 1
    fi

    log_info "Copying certificates from $src_dir to $target_dir"
    mkdir -p "$target_dir"
    
    cp -L "$src_dir/fullchain.pem" "$target_dir/fullchain.pem.tmp"
    cp -L "$src_dir/privkey.pem" "$target_dir/privkey.pem.tmp"
    
    mv "$target_dir/fullchain.pem.tmp" "$target_dir/fullchain.pem"
    mv "$target_dir/privkey.pem.tmp" "$target_dir/privkey.pem"
    
    log_info "Certificates copied successfully."
}
