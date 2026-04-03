#!/bin/bash

# sing-box client installation via singctl
# This script installs singctl first, then installs sing-box client by singctl

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_singctl() {
    log "Installing singctl tap and formula..."

    # A. Install singctl
    retry_command "singctl tap" brew tap sixban6/singctl
    retry_command "singctl installation" brew install sixban6/singctl/singctl

    if ! command_exists singctl; then
        log_error "singctl was not found after installation"
        return 1
    fi

    log_success "singctl installed successfully"
}

install_singbox_client() {
    log "Installing sing-box client using singctl..."

    # B. Install sing-box client via singctl
    retry_command "sing-box client installation" singctl sb install

    log_success "sing-box client installed successfully via singctl"
}

main() {
    check_macos
    check_not_root

    if ! command_exists brew; then
        log_error "Homebrew is required but not installed. Please run homebrew.sh first."
        exit 1
    fi

    install_singctl
    install_singbox_client
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
