#!/usr/bin/env bash
# Configuration file management for ai-dev-env-setup
# Stores config in ~/.config/ai-dev-env/config.json
if [[ -z "${APP_NAME:-}" ]]; then
    APP_NAME="ai-dev-env"
fi

# Safe fallbacks for logging (no-ops if not provided elsewhere)
log_debug() { :; }
log_info() { :; }
log_warn() { :; }

# Lightweight prompt helpers (can be overridden by the host environment)
prompt_with_default() {
  local prompt="$1"
  local default="$2"
  local user_input
  if [[ -n "$default" ]]; then
    read -p "$prompt [$default]: " user_input
  else
    read -p "$prompt: " user_input
  fi
  if [[ -z "$user_input" ]]; then
    echo "$default"
  else
    echo "$user_input"
  fi
}

read_secret() {
  local prompt="$1"
  local value
  if [[ -t 0 ]]; then
    read -s -p "$prompt: " value
    echo
  else
    read -r value
  fi
  echo "$value"
}

# Get config directory path
get_config_dir() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  echo "${config_home}/${APP_NAME}"
}

# Ensure config directory exists
ensure_config_dir() {
  local config_dir
  config_dir=$(get_config_dir)
  if [[ ! -d "$config_dir" ]]; then
    mkdir -p "$config_dir" && log_debug "Created config directory: $config_dir" || log_warn "Could not create config directory: $config_dir"
  fi
}

# Get config file path
get_config_file() {
  echo "$(get_config_dir)/config.json"
}

# Load config from JSON file
# Returns: config content or empty JSON "{}"
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

# Save config to JSON file
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

# Get single config value
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

# Set single config value
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

# Prompt for missing configuration values
# Usage: prompt_missing_config "api_key" "Enter API Key" "default" "true"
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

# Check if jq is available
has_jq() {
  command -v jq >/dev/null 2>&1
}

export APP_NAME
