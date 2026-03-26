# Logging functions for ai-dev-env-setup

# Debug logging (only when DEBUG=1)
log_debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        echo -e "${COLOR_BLUE}[DEBUG]${COLOR_RESET} $*" >&2
    fi
}

# Info logging
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*" >&2
}

# Warning logging
log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" >&2
}

# Error logging
log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

# Success logging
log_success() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*" >&2
}
