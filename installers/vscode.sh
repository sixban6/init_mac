#!/bin/bash

# VS Code installation and configuration
# This script installs Visual Studio Code via Homebrew Cask

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# VS Code installation
install_vscode() {
    log "Checking VS Code installation..."
    
    if is_app_installed "Visual Studio Code"; then
        log_success "VS Code already installed"
        configure_vscode
        return 0
    fi
    
    log "Installing VS Code..."
    retry_command "VS Code installation" brew install --cask visual-studio-code
    
    configure_vscode
    
    log_success "VS Code installed successfully"
}

configure_vscode() {
    # Create 'code' command in PATH if not exists
    if ! command_exists code; then
        local config_block='# VS Code command line
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"'
        
        add_to_shell_profile "$config_block" "VS Code command line"
        
        log_success "VS Code command line tool configured"
    else
        log_success "VS Code command line tool already available"
    fi
}

main() {
    check_macos
    check_not_root
    
    # Check if Homebrew is available
    if ! command_exists brew; then
        log_error "Homebrew is required but not installed. Please run homebrew.sh first."
        exit 1
    fi
    
    install_vscode
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi