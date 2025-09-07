#!/bin/bash

# sing-box installation and configuration
# This script installs sing-box via Homebrew and creates basic configuration

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# sing-box installation and configuration
install_singbox() {
    log "Checking sing-box installation..."
    
    if command_exists sing-box; then
        local current_version
        current_version=$(sing-box version 2>/dev/null | head -1 | cut -d' ' -f3 2>/dev/null || echo "unknown")
        local latest_version
        latest_version=$(brew info sing-box 2>/dev/null | head -1 | grep -o 'stable [0-9.]*' | cut -d' ' -f2 || echo "unknown")
        
        if [[ "$current_version" != "unknown" ]] && [[ "$latest_version" != "unknown" ]] && version_ge "$current_version" "$latest_version"; then
            log_success "sing-box is up to date (version: $current_version)"
            return 0
        else
            log_warning "sing-box version $current_version may be outdated, updating to $latest_version"
        fi
    fi
    
    log "Installing/updating sing-box..."
    
    # Add sing-box tap
    if ! brew tap | grep -q "sagernet/sing-box"; then
        brew tap sagernet/sing-box
    fi
    
    retry_command "sing-box installation" brew install sing-box
    
    # Create configuration directory if it doesn't exist
    local config_dir="$HOME/.config/sing-box"
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
        log_success "sing-box configuration directory created: $config_dir"
    fi
    
    # Create basic configuration file if it doesn't exist
    local config_file="$config_dir/config.json"
    if [[ ! -f "$config_file" ]]; then
        cat > "$config_file" << 'EOF'
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "mixed",
      "listen": "::",
      "listen_port": 2080,
      "sniff": true,
      "sniff_override_destination": true
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}
EOF
        log_success "Basic sing-box configuration created: $config_file"
        log "Please edit $config_file to configure your proxy settings"
    fi
    
    log_success "sing-box installed and configured successfully"
}

main() {
    check_macos
    check_not_root
    
    # Check if Homebrew is available
    if ! command_exists brew; then
        log_error "Homebrew is required but not installed. Please run homebrew.sh first."
        exit 1
    fi
    
    install_singbox
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi