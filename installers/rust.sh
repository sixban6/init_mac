#!/bin/bash

# Rust installation and configuration
# This script installs Rust via Homebrew and configures Cargo China mirror

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Rust installation and configuration
install_rust() {
    log "Checking Rust installation..."
    
    if command_exists rustc; then
        local current_version
        current_version=$(rustc --version | cut -d' ' -f2)
        local latest_version
        latest_version=$(brew info rust 2>/dev/null | head -1 | grep -o 'stable [0-9.]*' | cut -d' ' -f2 || echo "unknown")
        
        if version_ge "$current_version" "$latest_version"; then
            log_success "Rust is up to date (version: $current_version)"
            return 0
        else
            log_warning "Rust version $current_version is outdated, updating to $latest_version"
        fi
    fi
    
    log "Installing/updating Rust..."
    
    # Verify Rust package integrity before installation
    verify_homebrew_package "rust" || log_warning "Rust package verification skipped"
    
    retry_command "Rust installation" brew install rust
    
    # Configure Rust environment
    local config_block='# Rust environment
export CARGO_HOME="$HOME/.cargo"
export PATH="$CARGO_HOME/bin:$PATH"'
    
    add_to_shell_profile "$config_block" "Rust environment"
    
    # Set current session environment
    export CARGO_HOME="$HOME/.cargo"
    export PATH="$CARGO_HOME/bin:$PATH"
    
    # Configure Cargo China mirror
    local cargo_config_dir="$HOME/.cargo"
    local cargo_config_file="$cargo_config_dir/config"
    
    if [[ ! -d "$cargo_config_dir" ]]; then
        mkdir -p "$cargo_config_dir"
    fi
    
    if [[ ! -f "$cargo_config_file" ]]; then
        cat > "$cargo_config_file" << 'EOF'
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"

[registries.crates-io]
protocol = "sparse"

[net]
git-fetch-with-cli = true
EOF
        log_success "Cargo China mirror configured: $cargo_config_file"
    fi
    
    log_success "Rust installed and configured successfully with China mirror"
}

main() {
    check_macos
    check_not_root
    
    # Check if Homebrew is available
    if ! command_exists brew; then
        log_error "Homebrew is required but not installed. Please run homebrew.sh first."
        exit 1
    fi
    
    install_rust
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi