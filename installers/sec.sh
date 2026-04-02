#!/bin/bash

# Security tools installation
# Install objective-see tools: Lulu and BlockBlock

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_security_tools() {
    log "Checking security tools installation..."

    if ! command_exists brew; then
        log_error "Homebrew is required to install security tools. Please run installers/homebrew.sh first."
        return 1
    fi

    local casks=("lulu" "blockblock")

    for cask in "${casks[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            log_success "$cask already installed"
            continue
        fi

        log "Installing $cask via Homebrew cask..."
        retry_command "$cask installation" brew install --cask "$cask"
        log_success "$cask installed successfully"
    done

    log_success "Security tools installation completed (lulu + blockblock)"
}

main() {
    check_macos
    check_not_root
    install_security_tools
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
