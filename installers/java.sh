#!/bin/bash

# Java (OpenJDK) installation and configuration
# This script installs OpenJDK via Homebrew and configures Java environment

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Java (OpenJDK) installation and configuration
install_java() {
    log "Checking OpenJDK installation..."
    
    # Check if OpenJDK is installed via Homebrew first
    if brew list openjdk &>/dev/null; then
        local brew_version
        brew_version=$(brew list --versions openjdk 2>/dev/null | head -1 | grep -o '[0-9.]*' | head -1)
        local latest_version
        latest_version=$(brew info openjdk 2>/dev/null | head -1 | grep -o 'stable [0-9.]*' | cut -d' ' -f2 2>/dev/null || echo "unknown")
        
        if version_ge "$brew_version" "$latest_version"; then
            log_success "OpenJDK is up to date (version: $brew_version)"
            configure_java_environment
            return 0
        else
            log_warning "OpenJDK version $brew_version is outdated, updating to $latest_version"
        fi
    elif command_exists java; then
        # Java exists but not from Homebrew - check version
        local current_version
        current_version=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1-2 2>/dev/null || echo "unknown")
        if [[ "$current_version" != "unknown" ]]; then
            log_warning "Found system Java version $current_version, installing Homebrew OpenJDK for better management"
        else
            log_warning "Found Java installation but version detection failed, installing Homebrew OpenJDK"
        fi
    fi
    
    log "Installing/updating OpenJDK..."
    
    # Install OpenJDK from Homebrew main repository
    retry_command "OpenJDK installation" brew install openjdk
    
    configure_java_environment
    
    log_success "OpenJDK installed and configured successfully"
}

# Configure Java environment
configure_java_environment() {
    # Find the OpenJDK installation path
    local java_home
    java_home="$(brew --prefix)/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
    
    if [[ -n "$java_home" ]] && [[ -d "$java_home" ]]; then
        local config_block="# Java environment
export JAVA_HOME=$java_home
export PATH=\$JAVA_HOME/bin:\$PATH"
        
        add_to_shell_profile "$config_block" "Java environment"
        
        # Set current session environment
        export JAVA_HOME="$java_home"
        export PATH="$JAVA_HOME/bin:$PATH"
        
        log_success "Java environment configured with JAVA_HOME: $java_home"
    else
        log_warning "Could not determine JAVA_HOME, please configure manually"
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
    
    install_java
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi