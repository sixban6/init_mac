#!/bin/bash

# Telegram installation
# This script installs Telegram via Homebrew cask

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_telegram() {
    log "Checking Telegram installation..."

    if ! command_exists brew; then
        log_error "Homebrew is required to install Telegram. Please run installers/homebrew.sh first."
        return 1
    fi

    if brew list --cask telegram &>/dev/null; then
        log_success "Telegram already installed"
        return 0
    fi

    log "Installing Telegram via Homebrew cask..."
    retry_command "Telegram installation" brew install --cask telegram
    log_success "Telegram installed successfully"
}

main() {
    check_macos
    check_not_root
    install_telegram
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
