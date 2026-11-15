#!/bin/bash
# Post-renew hook for Apache
# Make executable with 'chmod +x reload_apache.sh' to activate.

# Example: If running an external Docker web server container:
if command -v docker >/dev/null 2>&1; then
    docker exec apache apachectl graceful 2>/dev/null || true
fi
