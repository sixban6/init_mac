#!/bin/bash

# Node.js installation and configuration
# This script installs Node.js via Homebrew and configures npm China mirror

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Node.js installation and configuration
install_nodejs() {
    log "Checking Node.js installation..."
    
    if command_exists node; then
        local current_version
        current_version=$(node --version | sed 's/v//')
        local latest_version
        latest_version=$(brew info node 2>/dev/null | head -1 | grep -o 'stable [0-9.]*' | cut -d' ' -f2 || echo "unknown")
        
        if version_ge "$current_version" "$latest_version"; then
            log_success "Node.js is up to date (version: v$current_version)"
            return 0
        else
            log_warning "Node.js version v$current_version is outdated, updating to v$latest_version"
        fi
    fi
    
    log "Installing/updating Node.js..."
    
    # Verify Node.js package integrity before installation
    verify_homebrew_package "node" || log_warning "Node.js package verification skipped"
    
    retry_command "Node.js installation" brew install node
    
    # Verify npm is also available
    if command_exists npm; then
        local npm_version
        npm_version=$(npm --version)
        log_success "npm is available (version: $npm_version)"
        
        # Configure npm global directory to avoid permission issues
        local npm_global="$HOME/.npm-global"
        if [[ ! -d "$npm_global" ]]; then
            mkdir -p "$npm_global"
            npm config set prefix "$npm_global"
        fi
        
        # Configure npm China mirror (only registry - other options deprecated in npm 11+)
        npm config set registry https://registry.npmmirror.com
        
        log_success "npm China mirror configured"
        
        # Configure shell environment for npm global packages
        local config_block='# Node.js and npm environment
export PATH="$HOME/.npm-global/bin:$PATH"'
        
        add_to_shell_profile "$config_block" "Node.js and npm environment"
        
        # Set current session environment
        export PATH="$HOME/.npm-global/bin:$PATH"
    fi
    
    log_success "Node.js installed and configured successfully with China mirror"
}

main() {
    check_macos
    check_not_root
    
    # Check if Homebrew is available
    if ! command_exists brew; then
        log_error "Homebrew is required but not installed. Please run homebrew.sh first."
        exit 1
    fi
    
    install_nodejs
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi