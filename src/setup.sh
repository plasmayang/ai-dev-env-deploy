#!/usr/bin/env bash
#
# AI Development Environment Setup
# Self-service configuration via curl | bash
 
#

_SCRIPT_SOURCE="${BASH_SOURCE[0]:-${0}}"

set -euo pipefail

# Version (semver)
readonly VERSION="1.0.0"

# URLs (will be configured during deployment)
readonly SCRIPT_URL="${SCRIPT_URL:-}"
readonly VERSION_URL="${VERSION_URL:-}"
readonly CHECKSUM_URL="${CHECKSUM_URL:-}"

# Application name for config directory
readonly APP_NAME="ai-dev-env"

# Colors for output (if terminal supports)
if [[ -t 1 ]]; then
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_RESET='\033[0m'
else
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_RESET=''
fi

# Source library functions
SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_SOURCE}")" && pwd)"
readonly SCRIPT_DIR

# Load libraries if they exist
load_library() {
    local lib_name="$1"
    local lib_path="${SCRIPT_DIR}/lib/${lib_name}.sh"
    if [[ -f "$lib_path" ]]; then
        # shellcheck source=/dev/null
        source "$lib_path"
    fi
}

# Source all required libraries in dependency order
source_libraries() {
    load_library "core"
    load_library "logging"
    load_library "config"
    load_library "detect"
    load_library "prompt"
    load_library "update"
}

ALLOWED_CDN_DOMAINS=(
    "cdn.jsdelivr.net"
    "raw.githubusercontent.com"
)

validate_source() {
    local url="${SCRIPT_URL:-}"
    
    if [[ -z "$url" ]]; then
        return 0
    fi
    
    local domain
    domain=$(echo "$url" | awk -F/ '{print $3}')
    
    local allowed
    for allowed in "${ALLOWED_CDN_DOMAINS[@]}"; do
        [[ "$domain" == "$allowed" ]] && return 0
    done
    
    log_error "Source URL domain '$domain' is not in the allowed list."
    log_error "Allowed domains: ${ALLOWED_CDN_DOMAINS[*]}"
    log_error "This script should be downloaded from an official source."
    return 1
}

main() {
    local command="${1:-help}"
    shift 2>/dev/null || true
    
    source_libraries
    
    if ! validate_source; then
        exit 1
    fi
    
    case "$command" in
        install)
            cmd_install
            ;;
        configure)
            cmd_configure
            ;;
        update)
            cmd_update
            ;;
        version|--version|-v)
            echo "ai-dev-env-setup v${VERSION}"
            ;;
        help|--help|-h|*)
            show_help
            ;;
    esac
}

show_help() {
    cat << 'EOF'
AI Development Environment Setup

Usage: setup.sh <command>

Commands:
    install      Install dependencies
    configure   Configure credentials and settings
    update      Check for and apply updates
    version     Show version information
    help        Show this help message

For more information, visit the documentation.
EOF
}

cmd_install() {
    echo
    log_info "=========================================="
    log_info "  AI Development Environment Setup"
    log_info "=========================================="
    echo
    
    local os_type arch pkg_mgr install_cmd
    
    os_type=$(detect_os)
    arch=$(detect_arch)
    pkg_mgr=$(detect_package_manager)
    
    log_info "Detected System:"
    log_info "  OS: $os_type"
    log_info "  Architecture: $arch"
    log_info "  Package Manager: ${pkg_mgr:-unknown}"
    echo
    
    log_info "Checking prerequisites..."
    
    local missing_deps=()
    
    if ! is_installed "curl"; then
        missing_deps+=("curl")
    fi
    
    if ! is_installed "git"; then
        missing_deps+=("git")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warn "Missing required dependencies: ${missing_deps[*]}"
        echo
        
        if [[ -n "$pkg_mgr" ]]; then
            install_cmd=$(get_install_command)
            if [[ -n "$install_cmd" ]]; then
                log_info "Install with:"
                case "$pkg_mgr" in
                    apt)
                        log_info "  sudo apt-get update && sudo $install_cmd ${missing_deps[*]}"
                        ;;
                    dnf|yum)
                        log_info "  sudo $install_cmd ${missing_deps[*]}"
                        ;;
                    pacman)
                        log_info "  sudo pacman -S ${missing_deps[*]}"
                        ;;
                    apk)
                        log_info "  apk add ${missing_deps[*]}"
                        ;;
                    brew)
                        log_info "  brew install ${missing_deps[*]}"
                        ;;
                    *)
                        log_info "  $install_cmd ${missing_deps[*]}"
                        ;;
                esac
            fi
        fi
        
        echo
        die "Please install missing dependencies and run setup again."
    fi
    
    log_success "All prerequisites verified!"
    echo
    
    log_info "Initializing configuration directory..."
    ensure_config_dir
    
    local config_file
    config_file=$(get_config_file)
    if [[ -f "$config_file" ]]; then
        log_info "Found existing configuration at $config_file"
    else
        log_info "Created configuration directory: $(get_config_dir)"
    fi
    
    echo
    log_success "=========================================="
    log_success "  Installation Complete!"
    log_success "=========================================="
    echo
    log_info "Next steps:"
    log_info "  1. Run 'setup.sh configure' to set up AI credentials"
    log_info "  2. Configure your OpenAI API key and GitHub token"
    log_info "  3. Choose your preferred IDE and AI model"
    echo
}

cmd_configure() {
    echo
    log_info "=========================================="
    log_info "  AI Development Environment Configuration"
    log_info "=========================================="
    echo
    
    ensure_config_dir
    
    log_info "This wizard will help you configure your AI development tools."
    log_info "Press Enter to accept default values shown in brackets."
    echo
    
    local config_file
    config_file=$(get_config_file)
    
    if [[ -f "$config_file" ]] && [[ -s "$config_file" ]]; then
        log_info "Loading existing configuration from: $config_file"
        echo
    fi
    
    echo "--- API Credentials ---"
    
    local openai_api_key
    openai_api_key=$(prompt_missing_config "openai_api_key" "OpenAI API Key (sk-...)" "" "true")
    
    local github_token
    github_token=$(prompt_missing_config "github_token" "GitHub Personal Access Token (ghp_...)" "" "true")
    
    echo
    echo "--- IDE Selection ---"
    
    local ide_choice
    ide_choice=$(select_from "Select your primary IDE:" "VSCode" "Cursor" "CLion" "Vim/Neovim" "Other")
    set_config "preferred_ide" "$ide_choice"
    
    echo
    echo "--- AI Model Selection ---"
    
    local model_choice
    model_choice=$(select_from "Select default AI model:" "gpt-4o" "gpt-4o-mini" "claude-3-5-sonnet" "o3-mini")
    set_config "default_model" "$model_choice"
    
    echo
    echo "--- Preferences ---"
    
    local theme_choice
    theme_choice=$(select_from "Select theme preference:" "dark" "light" "system")
    set_config "editor_theme" "$theme_choice"
    
    local shell_choice
    shell_choice=$(select_from "Select your shell:" "bash" "zsh" "fish")
    set_config "shell" "$shell_choice"
    
    echo
    log_success "=========================================="
    log_success "  Configuration Complete!"
    log_success "=========================================="
    echo
    
    log_info "Configuration saved to: $config_file"
    echo
    
    log_info "Current configuration:"
    echo "  OpenAI API Key: ${openai_api_key:0:8}...${openai_api_key: -4}"
    echo "  GitHub Token: ${github_token:0:8}...${github_token: -4}"
    echo "  Preferred IDE: $ide_choice"
    echo "  Default Model: $model_choice"
    echo "  Theme: $theme_choice"
    echo "  Shell: $shell_choice"
    echo
    
    log_info "Run 'setup.sh update' to check for updates."
}

cmd_update() {
    if check_for_updates; then
        log_success "You are on the latest version: v${VERSION}"
    else
        prompt_update
    fi
}

# Run main if executed directly (not sourced)
if [[ "${_SCRIPT_SOURCE}" == "${0}" ]]; then
    main "$@"
fi
