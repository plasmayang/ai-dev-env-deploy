#!/usr/bin/env bash
# Core utility functions for ai-dev-env-setup

# Get the directory of this script (resolves symlinks)
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [[ -h "$source" ]]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

# Exit with error message
die() {
    log_error "$@"
    exit 1
}

# Check if a command exists
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Require a command to be installed, exit if not
require() {
    if ! is_installed "$1"; then
        die "Required command '$1' not found. Please install it first."
    fi
}

# Prompt to confirm file overwrite
confirm_overwrite() {
    local file="$1"
    if [[ -f "$file" ]]; then
        read -p "File '$file' exists. Overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    return 0
}

# Create a temporary file
mktemp_file() {
    if is_installed mktemp; then
        mktemp
    else
        echo "/tmp/setup-$$.tmp"
    fi
}
