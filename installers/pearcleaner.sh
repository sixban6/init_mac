#!/bin/bash

# Pearcleaner installation and uninstallation
# Default action: install

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_pearcleaner() {
    log "Checking Pearcleaner installation..."

    if ! command_exists brew; then
        log_error "Homebrew is required to install Pearcleaner. Please run installers/homebrew.sh first."
        return 1
    fi

    if brew list --cask pearcleaner &>/dev/null; then
        log_success "Pearcleaner already installed"
        return 0
    fi

    log "Installing Pearcleaner via Homebrew cask..."
    retry_command "Pearcleaner installation" brew install --cask pearcleaner
    log_success "Pearcleaner installed successfully"
}

uninstall_pearcleaner() {
    log "Checking Pearcleaner uninstall status..."

    if ! command_exists brew; then
        log_error "Homebrew is required to uninstall Pearcleaner."
        return 1
    fi

    if ! brew list --cask pearcleaner &>/dev/null; then
        log_warning "Pearcleaner is not installed"
        return 0
    fi

    log "Uninstalling Pearcleaner..."
    retry_command "Pearcleaner uninstallation" brew uninstall --cask pearcleaner
    log_success "Pearcleaner uninstalled successfully"
}

show_usage() {
    cat << EOF_USAGE
Usage: $0 [--install|--uninstall]

Options:
  --install     Install Pearcleaner (default)
  --uninstall   Uninstall Pearcleaner
  -h, --help    Show this help message
EOF_USAGE
}

main() {
    check_macos
    check_not_root

    local action="install"

    case "${1:-}" in
        --uninstall)
            action="uninstall"
            ;;
        --install|"")
            action="install"
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac

    if [[ "$action" == "install" ]]; then
        install_pearcleaner
    else
        uninstall_pearcleaner
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
