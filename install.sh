#!/bin/bash
set -euo pipefail

# Installer for lecf
# Usage: sudo ./install.sh [PREFIX]
# Default PREFIX is /usr/local

PREFIX="${1:-/usr/local}"
BIN_DIR="$PREFIX/bin"
LIB_DIR="$PREFIX/lib/lecf"
HOOKS_DIR="/etc/lecf/hooks/post-renew.d"
CERTS_DIR="/etc/lecf/certs"

if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Must run as root to install to $PREFIX" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

echo "[INFO] Installing lecf to $PREFIX..."

mkdir -p "$BIN_DIR"
mkdir -p "$LIB_DIR"
mkdir -p "$HOOKS_DIR"
mkdir -p "$CERTS_DIR"

# Install libraries
cp -f "$SCRIPT_DIR"/lib/*.sh "$LIB_DIR/"
chmod +x "$LIB_DIR"/*.sh

# Install hooks examples if not present
for hook in "$SCRIPT_DIR"/hooks/post-renew.d/*; do
    if [ -f "$hook" ]; then
        hook_name="$(basename "$hook")"
        if [ ! -f "$HOOKS_DIR/$hook_name" ]; then
            cp "$hook" "$HOOKS_DIR/"
        fi
    fi
done

# Install binary
cp -f "$SCRIPT_DIR/bin/lecf" "$BIN_DIR/lecf"
chmod +x "$BIN_DIR/lecf"

echo "[INFO] Successfully installed lecf to $BIN_DIR/lecf"
echo "[INFO] Libraries installed in $LIB_DIR"
echo "[INFO] Hooks directory ready at $HOOKS_DIR"
