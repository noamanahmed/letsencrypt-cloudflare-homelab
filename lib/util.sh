#!/bin/bash
set -euo pipefail

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_debug() {
    # uncomment to enable debug
    # echo "[DEBUG] $*"
    true
}
