#!/bin/bash

# Tailscale installation
# This script installs Tailscale via Homebrew cask

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_tailscale() {
    log "Checking Tailscale installation..."

    if ! command_exists brew; then
        log_error "Homebrew is required to install Tailscale. Please run installers/homebrew.sh first."
        return 1
    fi

    if brew list --cask tailscale &>/dev/null; then
        log_success "Tailscale already installed"
        return 0
    fi

    log "Installing Tailscale via Homebrew cask..."
    retry_command "Tailscale installation" brew install --cask tailscale
    log_success "Tailscale installed successfully"
}

main() {
    check_macos
    check_not_root
    install_tailscale
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
