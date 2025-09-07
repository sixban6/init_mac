#!/bin/bash

# Homebrew installation and configuration
# This script installs Homebrew and configures China mirrors

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Homebrew installation and update
install_homebrew() {
    log "Checking Homebrew installation..."
    
    if command_exists brew; then
        # Get current and latest versions
        local current_version
        current_version=$(brew --version | head -1 | grep -o '[0-9.]*' | head -1)
        
        log "Current Homebrew version: $current_version"
        
        # Check if Homebrew needs update (by running update command)
        log "Checking for Homebrew updates..."
        local update_output
        update_output=$(brew update 2>&1)
        
        if echo "$update_output" | grep -q "Already up-to-date"; then
            log_success "Homebrew is up to date (version: $current_version)"
        else
            log_success "Homebrew updated to latest version"
        fi
        
        configure_homebrew_china_mirror
        return 0
    fi
    
    log "Installing Homebrew..."
    
    # Install Homebrew using official installation script
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    log_success "Homebrew installed successfully"
    configure_homebrew_china_mirror
}

configure_homebrew_china_mirror() {
    log "Configuring Homebrew China mirrors..."
    
    # Set China mirrors if brew is available
    if command_exists brew; then
        # Configure brew repo
        local brew_repo
        brew_repo=$(brew --repo 2>/dev/null)
        if [[ -n "$brew_repo" && -d "$brew_repo" ]]; then
            (cd "$brew_repo" && git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git 2>/dev/null) || true
        fi
        
        # Configure homebrew-core repo
        local core_repo="$(brew --repo)/Library/Taps/homebrew/homebrew-core"
        if [[ -d "$core_repo" ]]; then
            (cd "$core_repo" && git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git 2>/dev/null) || true
        fi
    fi
    
    # Add environment variables to shell profile
    local config_block='export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
# Homebrew China Mirror
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
export HOMEBREW_BREW_GIT_REMOTE=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
export HOMEBREW_CORE_GIT_REMOTE=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git'
    
    add_to_shell_profile "$config_block" "Homebrew Environment"
    
    # Set current session PATH for Homebrew
    export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
    export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
    
    # Update Homebrew if available
    if command_exists brew; then
        brew update || log_warning "Homebrew update failed, but continuing..."
    fi
    
    log_success "Homebrew China mirrors configured"
}

main() {
    check_macos
    check_not_root
    install_homebrew
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi