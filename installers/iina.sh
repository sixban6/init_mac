#!/bin/bash

# IINA installation
# This script installs IINA via Homebrew cask

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_iina() {
    log "Checking IINA installation..."

    if ! command_exists brew; then
        log_error "Homebrew is required to install IINA. Please run installers/homebrew.sh first."
        return 1
    fi

    if brew list --cask iina &>/dev/null; then
        log_success "IINA already installed"
        return 0
    fi

    log "Installing IINA via Homebrew cask..."
    retry_command "IINA installation" brew install --cask iina
    log_success "IINA installed successfully"
}

main() {
    check_macos
    check_not_root
    install_iina
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
