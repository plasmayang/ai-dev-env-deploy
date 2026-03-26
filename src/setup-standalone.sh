#!/usr/bin/env bash
#
# AI Development Environment Setup
# Self-contained single-file version for curl | bash
#

set -euo pipefail

readonly VERSION="1.0.0"
readonly APP_NAME="ai-dev-env"
readonly SCRIPT_URL="${SCRIPT_URL:-}"
readonly VERSION_URL="${VERSION_URL:-}"
readonly CHECKSUM_URL="${CHECKSUM_URL:-}"

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

ALLOWED_CDN_DOMAINS=(
    "cdn.jsdelivr.net"
    "raw.githubusercontent.com"
)

log_debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo -e "${COLOR_BLUE}[DEBUG]${COLOR_RESET} $*" >&2
    fi
}

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*" >&2
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" >&2
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

log_success() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*" >&2
}

die() {
    log_error "$@"
    exit 1
}

is_installed() {
    command -v "$1" >/dev/null 2>&1
}

require() {
    if ! is_installed "$1"; then
        die "Required command '$1' not found. Please install it first."
    fi
}

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

mktemp_file() {
    if is_installed mktemp; then
        mktemp
    else
        echo "/tmp/setup-$$.tmp"
    fi
}

detect_os() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l) echo "armv7l" ;;
        *) echo "$arch" ;;
    esac
}

detect_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        local id
        id=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
        echo "${id:-unknown}"
    elif [[ -f /etc/redhat-release ]]; then
        if grep -q "Fedora" /etc/redhat-release; then
            echo "fedora"
        elif grep -q "CentOS" /etc/redhat-release; then
            echo "centos"
        else
            echo "rhel"
        fi
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ -f /etc/alpine-release ]]; then
        echo "alpine"
    else
        echo "unknown"
    fi
}

detect_package_manager() {
    if command -v brew >/dev/null 2>&1; then
        echo "brew"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    else
        echo ""
    fi
}

get_install_command() {
    local pkg_mgr
    pkg_mgr=$(detect_package_manager)
    case "$pkg_mgr" in
        apt) echo "apt-get install -y" ;;
        dnf) echo "dnf install -y" ;;
        yum) echo "yum install -y" ;;
        pacman) echo "pacman -S --noconfirm" ;;
        apk) echo "apk add" ;;
        brew) echo "brew install" ;;
        *) echo "" ;;
    esac
}

prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local value
    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " value
        echo "${value:-$default}"
    else
        read -p "$prompt: " value
        echo "$value"
    fi
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local yn
    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n]: " yn
        [[ -z "$yn" ]] && yn="y"
    else
        read -p "$prompt [y/N]: " yn
        [[ -z "$yn" ]] && yn="n"
    fi
    [[ "$yn" =~ ^[Yy]$ ]]
}

select_option() {
    local title="$1"
    shift
    local options=("$@")
    if [[ ${#options[@]} -eq 1 ]]; then
        echo "1"
        return
    fi
    echo "$title"
    echo "-------------"
    local i=1
    for option in "${options[@]}"; do
        echo "$i) $option"
        ((i++))
    done
    echo ""
    local choice
    while true; do
        read -p "Enter selection [1-${#options[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && \
           [[ "$choice" -ge 1 ]] && \
           [[ "$choice" -le ${#options[@]} ]]; then
            echo "$choice"
            return
        fi
        echo "Invalid selection. Please enter a number between 1 and ${#options[@]}."
    done
}

read_secret() {
    local prompt="$1"
    local secret=""
    local stty_settings=""
    stty_settings=$(stty -g 2>/dev/null) || true
    stty -echo 2>/dev/null || true
    printf "%s: " "$prompt"
    read -r secret
    printf "\n"
    stty "$stty_settings" 2>/dev/null || true
    echo "$secret"
}

select_from() {
    local title="$1"
    shift
    local options=("$@")
    local idx
    idx=$(select_option "$title" "${options[@]}")
    echo "${options[$((idx-1))]}"
}

get_config_dir() {
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    echo "${config_home}/${APP_NAME}"
}

ensure_config_dir() {
    local config_dir
    config_dir=$(get_config_dir)
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir" && log_debug "Created config directory: $config_dir" || log_warn "Could not create config directory: $config_dir"
    fi
}

get_config_file() {
    echo "$(get_config_dir)/config.json"
}

load_config() {
    local config_file
    config_file=$(get_config_file)
    if [[ -f "$config_file" ]]; then
        if command -v jq >/dev/null 2>&1; then
            jq '.' "$config_file" 2>/dev/null || echo "{}"
        else
            cat "$config_file"
        fi
    else
        echo "{}"
    fi
}

save_config() {
    local config_file
    config_file=$(get_config_file)
    local content="$1"
    ensure_config_dir
    if command -v jq >/dev/null 2>&1; then
        echo "$content" | jq '.' > "$config_file"
    else
        echo "$content" > "$config_file"
    fi
    log_debug "Saved config to: $config_file"
}

get_config() {
    local key="$1"
    local default="${2:-}"
    if command -v jq >/dev/null 2>&1; then
        local value
        value=$(load_config | jq -r ".${key} // \"${default}\"")
        echo "$value"
    else
        echo "$default"
    fi
}

set_config() {
    local key="$1"
    local value="$2"
    if command -v jq >/dev/null 2>&1; then
        local config
        config=$(load_config)
        local new_config
        new_config=$(echo "$config" | jq --arg k "$key" --arg v "$value" '. + {($k): $v}')
        save_config "$new_config"
    else
        log_warn "jq not found, cannot set config"
    fi
}

prompt_missing_config() {
    local key="$1"
    local prompt="$2"
    local default="${3:-}"
    local secret="${4:-false}"
    local current_value
    current_value=$(get_config "$key")
    if [[ -z "$current_value" || "$current_value" == "null" ]]; then
        log_info "Configuration '$key' is not set."
        local new_value
        if [[ "$secret" == "true" ]]; then
            new_value=$(read_secret "$prompt")
        else
            new_value=$(prompt_with_default "$prompt" "$default")
        fi
        set_config "$key" "$new_value"
        echo "$new_value"
    else
        echo "$current_value"
    fi
}

has_jq() {
    command -v jq >/dev/null 2>&1
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
    
    local os_type arch pkg_mgr
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
            local install_cmd
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
        log_info "Update available! Run with:"
        log_info "  curl -sL https://raw.githubusercontent.com/plasmayang/ai-dev-env-deploy/main/src/setup.sh | bash"
    fi
}

main() {
    local command="${1:-help}"
    shift 2>/dev/null || true
    
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

main "$@"
