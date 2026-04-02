#!/bin/bash

# Brave Browser installation
# This script installs Brave Browser via Homebrew cask

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_brave_browser() {
    log "Checking Brave Browser installation..."

    if ! command_exists brew; then
        log_error "Homebrew is required to install Brave Browser. Please run installers/homebrew.sh first."
        return 1
    fi

    if brew list --cask brave-browser &>/dev/null; then
        log_success "Brave Browser already installed"
        return 0
    fi

    log "Installing Brave Browser via Homebrew cask..."
    retry_command "Brave Browser installation" brew install --cask brave-browser
    log_success "Brave Browser installed successfully"
}

main() {
    check_macos
    check_not_root
    install_brave_browser
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
