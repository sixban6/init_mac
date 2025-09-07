#!/bin/bash

# Python installation and configuration
# This script installs Python 3 via Homebrew and configures pip China mirror

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Python installation and configuration
install_python() {
    log "Checking Python installation..."
    
    if command_exists python3; then
        local current_version
        current_version=$(python3 --version | cut -d' ' -f2)
        local latest_version
        latest_version=$(brew info python@3 2>/dev/null | head -1 | grep -o 'stable [0-9.]*' | cut -d' ' -f2 || echo "unknown")
        
        if version_ge "$current_version" "${latest_version#*@}"; then
            log_success "Python is up to date (version: $current_version)"
            return 0
        else
            log_warning "Python version $current_version is outdated, updating to latest"
        fi
    fi
    
    log "Installing/updating Python..."
    
    # Verify Python package integrity before installation
    verify_homebrew_package "python@3" || log_warning "Python package verification skipped"
    
    retry_command "Python installation" brew install python@3
    
    # Configure Python environment
    local config_block='# Python environment
export PATH="/usr/local/opt/python@3/bin:$PATH"
alias python=python3
alias pip=pip3'
    
    add_to_shell_profile "$config_block" "Python environment"
    
    # Configure pip to use China mirror
    local pip_config_dir="$HOME/.pip"
    local pip_config_file="$pip_config_dir/pip.conf"
    
    if [[ ! -d "$pip_config_dir" ]]; then
        mkdir -p "$pip_config_dir"
    fi
    
    if [[ ! -f "$pip_config_file" ]]; then
        cat > "$pip_config_file" << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
        log_success "pip China mirror configured: $pip_config_file"
    fi
    
    # Install essential Python packages
    python3 -m pip install --break-system-packages --upgrade pip setuptools wheel || {
        log_warning "Failed to install Python packages with --break-system-packages, trying with --user"
        python3 -m pip install --user --upgrade pip setuptools wheel
    }
    
    log_success "Python installed and configured successfully with China mirror"
}

main() {
    check_macos
    check_not_root
    
    # Check if Homebrew is available
    if ! command_exists brew; then
        log_error "Homebrew is required but not installed. Please run homebrew.sh first."
        exit 1
    fi
    
    install_python
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi