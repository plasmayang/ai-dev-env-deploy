#!/bin/bash

get_script_dir_for_update() {
    local source="${BASH_SOURCE[0]}"
    while [[ -h "$source" ]]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

UPDATE_LIB_DIR="$(get_script_dir_for_update)"
# shellcheck source=/dev/null
[[ -f "${UPDATE_LIB_DIR}/prompt.sh" ]] && source "${UPDATE_LIB_DIR}/prompt.sh"
# shellcheck source=/dev/null
[[ -f "${UPDATE_LIB_DIR}/logging.sh" ]] && source "${UPDATE_LIB_DIR}/logging.sh"

check_for_updates() {
    if [[ -z "${VERSION_URL:-}" ]]; then
        log_debug "VERSION_URL not set, skipping update check"
        return 0
    fi

    log_debug "Checking for updates..."

    local remote_version
    remote_version=$(curl -fsSL "$VERSION_URL" 2>/dev/null) || {
        log_debug "Could not fetch version from $VERSION_URL"
        return 0
    }

    if [[ -z "$remote_version" ]]; then
        log_debug "Empty version response"
        return 0
    fi

    if version_greater "$remote_version" "$VERSION"; then
        log_info "Update available: v$remote_version (current: v$VERSION)"
        return 1
    else
        log_debug "Already on latest version: v$VERSION"
        return 0
    fi
}

version_greater() {
    local v1="$1"
    local v2="$2"

    v1="${v1#v}"
    v2="${v2#v}"

    local IFS='.'
    local i ver1=($v1) ver2=($v2)

    for ((i=0; i<${#ver1[@]} || i<${#ver2[@]}; i++)); do
        local num1=${ver1[i]:-0}
        local num2=${ver2[i]:-0}
        ((num1 > num2)) && return 0
        ((num1 < num2)) && return 1
    done

    return 1
}

fetch_latest_script() {
    local output="${1:-/tmp/setup.sh.new}"

    if [[ -z "${SCRIPT_URL:-}" ]]; then
        log_error "SCRIPT_URL not set"
        return 1
    fi

    log_info "Fetching latest version from $SCRIPT_URL..."

    if curl -fsSL "$SCRIPT_URL" -o "$output"; then
        chmod +x "$output"
        log_success "Downloaded to $output"
        return 0
    else
        log_error "Failed to download latest version"
        return 1
    fi
}

apply_update() {
    local tmp_script
    tmp_script=$(mktemp_file)

    if ! fetch_latest_script "$tmp_script"; then
        rm -f "$tmp_script"
        return 1
    fi

    if [[ -n "${CHECKSUM_URL:-}" ]]; then
        local expected_hash
        expected_hash=$(curl -fsSL "$CHECKSUM_URL" 2>/dev/null | grep 'setup.sh' | awk '{print $1}')

        if [[ -n "$expected_hash" ]]; then
            if ! verify_checksum "$tmp_script" "$expected_hash"; then
                log_error "Checksum verification failed for new version"
                rm -f "$tmp_script"
                return 1
            fi
        fi
    fi

    log_info "Applying update..."

    local current_script
    current_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup.sh"

    if cp "$tmp_script" "$current_script"; then
        rm -f "$tmp_script"
        log_success "Update applied. Re-running with new version..."
        exec "$current_script" "$@"
    else
        log_error "Failed to apply update"
        rm -f "$tmp_script"
        return 1
    fi
}

prompt_update() {
    if confirm "Would you like to update now?"; then
        apply_update
    else
        log_info "Update skipped. You can update later with: $0 update"
    fi
}
