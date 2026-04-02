#!/bin/bash

# Homebrew installation and configuration
# This script installs Homebrew and configures the fastest available mirror

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Homebrew installation and update
install_homebrew() {
    log "Checking Homebrew installation..."

    if command_exists brew; then
        local current_version
        current_version=$(brew --version | head -1 | grep -o '[0-9.]*' | head -1)

        log "Current Homebrew version: $current_version"
        log "Checking for Homebrew updates..."

        local update_output
        update_output=$(brew update 2>&1 || true)

        if echo "$update_output" | grep -q "Already up-to-date"; then
            log_success "Homebrew is up to date (version: $current_version)"
        else
            log_success "Homebrew update check completed"
        fi

        return 0
    fi

    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Ensure Homebrew is available in current shell
    export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

    # Persist PATH for future shells
    add_to_shell_profile 'export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"' "Homebrew PATH"

    log_success "Homebrew installed successfully"
}

install_switch_brew_script() {
    local source_script="$SCRIPT_DIR/switch_brew.sh"
    local target_dir="/usr/local/bin"
    local target_script="$target_dir/switch_brew.sh"

    if [[ ! -f "$source_script" ]]; then
        log_error "switch_brew.sh not found: $source_script"
        return 1
    fi

    chmod +x "$source_script"

    log "Installing switch_brew.sh to $target_script..."

    if mkdir -p "$target_dir" 2>/dev/null && cp "$source_script" "$target_script" 2>/dev/null; then
        chmod +x "$target_script"
        log_success "switch_brew.sh installed to $target_script"
        return 0
    fi

    if command_exists sudo; then
        log "Permission denied for $target_dir, retrying with sudo..."
        if sudo mkdir -p "$target_dir" && sudo cp "$source_script" "$target_script" && sudo chmod +x "$target_script"; then
            log_success "switch_brew.sh installed to $target_script (via sudo)"
            return 0
        fi
    fi

    log_error "Failed to install switch_brew.sh to $target_script"
    return 1
}

configure_homebrew_mirror() {
    local runner="/usr/local/bin/switch_brew.sh"

    log "Configuring Homebrew mirror using automatic benchmark..."

    if [[ -x "$runner" ]]; then
        "$runner"
    elif [[ -f "$SCRIPT_DIR/switch_brew.sh" ]]; then
        bash "$SCRIPT_DIR/switch_brew.sh"
    else
        log_error "switch_brew.sh not found, cannot configure mirror"
        return 1
    fi

    if command_exists brew; then
        brew update || log_warning "Homebrew update failed, but continuing..."
    fi

    log_success "Homebrew mirror configuration completed"
}

main() {
    check_macos
    check_not_root

    install_homebrew
    install_switch_brew_script
    configure_homebrew_mirror
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
