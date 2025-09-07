#!/bin/bash

# Go installation and configuration
# This script installs Go via Homebrew and configures China proxy

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Go installation and configuration
install_go() {
    log "Checking Go installation..."
    
    if command_exists go; then
        local current_version
        current_version=$(go version | cut -d' ' -f3 | sed 's/go//')
        local latest_version
        latest_version=$(brew info go 2>/dev/null | head -1 | grep -o 'stable [0-9.]*' | cut -d' ' -f2 || echo "unknown")
        
        if version_ge "$current_version" "$latest_version"; then
            log_success "Go is up to date (version: $current_version)"
            return 0
        else
            log_warning "Go version $current_version is outdated, updating to $latest_version"
        fi
    fi
    
    log "Installing/updating Go..."
    
    # Verify Go package integrity before installation
    verify_homebrew_package "go" || log_warning "Go package verification skipped"
    
    retry_command "Go installation" brew install go
    
    # Configure Go environment
    local config_block='# Go environment
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
# Go China mirror proxy
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn'
    
    add_to_shell_profile "$config_block" "Go environment"
    
    # Set current session environment
    export GOPATH="$HOME/go"
    export PATH="$PATH:$GOPATH/bin"
    export GOPROXY="https://goproxy.cn,direct"
    export GOSUMDB="sum.golang.google.cn"
    
    # Create GOPATH directory
    mkdir -p "$HOME/go/src" "$HOME/go/bin" "$HOME/go/pkg"
    
    log_success "Go installed and configured successfully with China proxy"
}

main() {
    check_macos
    check_not_root
    
    # Check if Homebrew is available
    if ! command_exists brew; then
        log_error "Homebrew is required but not installed. Please run homebrew.sh first."
        exit 1
    fi
    
    install_go
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi