#!/bin/bash

# Git installation and configuration
# This script installs Git via Homebrew and configures China mirrors

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Git installation and upgrade
install_git() {
    log "Checking Git installation..."
    
    local system_git_version=""
    local brew_git_version=""
    local should_install=false
    
    # Check system Git version
    if command_exists git; then
        system_git_version=$(git --version 2>/dev/null | cut -d' ' -f3 || echo "unknown")
        log "System Git version: $system_git_version"
    fi
    
    # Get latest Homebrew Git version
    if command_exists brew; then
        brew_git_version=$(brew info git 2>/dev/null | head -1 | grep -o 'stable [0-9.]*' | cut -d' ' -f2 || echo "unknown")
        log "Latest Homebrew Git version: $brew_git_version"
        
        # Force upgrade if Homebrew version is newer or if system Git doesn't exist
        if [[ -z "$system_git_version" ]] || ! version_ge "$system_git_version" "$brew_git_version"; then
            should_install=true
        fi
    else
        log_error "Homebrew is required to install Git"
        return 1
    fi
    
    if $should_install; then
        log "Installing/upgrading Git to latest version..."
        
        # Verify Git package integrity before installation
        verify_homebrew_package "git" || log_warning "Git package verification skipped"
        
        # Install Git via Homebrew (this will be the latest version)
        retry_command "Git installation" brew install git
        
        # Configure shell to use Homebrew Git first
        local config_block='# Git environment - Use Homebrew Git
export PATH="/usr/local/bin:$PATH"'
        
        add_to_shell_profile "$config_block" "Git environment"
        
        # Update current session PATH
        export PATH="/usr/local/bin:$PATH"
        
        # Verify installation
        local new_version
        new_version=$(git --version | cut -d' ' -f3)
        log_success "Git upgraded successfully to version $new_version"
    else
        log_success "Git is already up to date (version: $system_git_version)"
    fi
    
    # Configure China mirrors for Git
    configure_git_china_mirrors
}

# Configure Git China mirrors
configure_git_china_mirrors() {
    log "Configuring Git basic settings..."
    
    # Configure basic Git settings for better performance in China
    git config --global http.postBuffer 1048576000
    git config --global http.maxRequestBuffer 100M
    git config --global core.preloadindex true
    git config --global core.fscache true
    git config --global gc.auto 256
    
    # Note: Users can manually configure GitHub mirrors if needed:
    # git config --global url."https://mirror.ghproxy.com/https://github.com/".insteadOf "https://github.com/"
    
    log_success "Git performance settings configured for China network"
}

main() {
    check_macos
    check_not_root
    
    # Check if Homebrew is available
    if ! command_exists brew; then
        log_error "Homebrew is required but not installed. Please run homebrew.sh first."
        exit 1
    fi
    
    install_git
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi