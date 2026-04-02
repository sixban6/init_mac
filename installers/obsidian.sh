#!/bin/bash

# Obsidian installation
# This script installs Obsidian via Homebrew cask

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_obsidian() {
    log "Checking Obsidian installation..."

    if ! command_exists brew; then
        log_error "Homebrew is required to install Obsidian. Please run installers/homebrew.sh first."
        return 1
    fi

    if brew list --cask obsidian &>/dev/null; then
        log_success "Obsidian already installed"
        return 0
    fi

    log "Installing Obsidian via Homebrew cask..."
    retry_command "Obsidian installation" brew install --cask obsidian
    log_success "Obsidian installed successfully"
}

main() {
    check_macos
    check_not_root
    install_obsidian
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
