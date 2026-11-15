#!/bin/bash
# Post-renew hook for Nginx
# Make executable with 'chmod +x reload_nginx.sh' to activate.

# Example: If running an external Docker web server container:
if command -v docker >/dev/null 2>&1; then
    docker exec nginx nginx -s reload 2>/dev/null || true
fi
