#!/usr/bin/env bash

 # Interactive prompt functions for ai-dev-env-setup

 # Prompt with default value (user can press Enter to accept default)
 # Usage: value=$(prompt_with_default "Enter value" "default_value")
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

 # Yes/No confirmation with default
 # Usage: if confirm "Continue?"; then ...
 confirm() {
     local prompt="$1"
     local default="${2:-n}"  # n or y

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

 # Select option from menu
 # Usage: choice=$(select_option "Option 1" "Option 2" "Option 3")
 select_option() {
     local title="$1"
     shift
     local options=("$@")
     local selected=0

     # If only one option, return it
     if [[ ${#options[@]} -eq 1 ]]; then
         echo "1"
         return
     fi

     # Display menu
     echo "$title"
     echo "-------------"
     local i=1
     for option in "${options[@]}"; do
         echo "$i) $option"
         ((i++))
     done
     echo ""

     # Get selection
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

 # Read secret (password) with masked input
 # Usage: password=$(read_secret "Enter password")
 read_secret() {
     local prompt="$1"
     local secret=""
     local stty_settings=""

     # Save terminal settings
     stty_settings=$(stty -g 2>/dev/null) || true

     # Disable echo
     stty -echo 2>/dev/null || true

     # Prompt and read
     printf "%s: " "$prompt"
     read -r secret
     printf "\n"

     # Restore terminal settings
     stty "$stty_settings" 2>/dev/null || true

     echo "$secret"
 }

 # Select option by index, returning the value
 # Usage: selected=$(select_from "Select:" "Option 1" "Option 2")
 select_from() {
     local title="$1"
     shift
     local options=("$@")

     local idx
     idx=$(select_option "$title" "${options[@]}")
     echo "${options[$((idx-1))]}"
 }
