#!/bin/bash

# Modular macOS Development Environment Setup Script
# Features: iTerm2, Homebrew, Git, Go, Python, Java (OpenJDK), Rust, Node.js, sing-box, VS Code
# Each component is installed via separate, customizable scripts

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLERS_DIR="$SCRIPT_DIR/installers"

# Load shared utilities
source "$INSTALLERS_DIR/utils.sh"

# Available installers (in recommended installation order)
declare -a AVAILABLE_INSTALLERS=(
    "homebrew"
    "git"
    "iterm2"
    "go"
    "python"
    "java"
    "rust"
    "nodejs"
    "vscode"
    "singbox"
)

# Function to display usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [COMPONENTS]

Modular macOS Development Environment Setup

OPTIONS:
    -h, --help      Show this help message
    -l, --list      List all available components
    -a, --all       Install all components (default)
    -s, --selective Run in selective mode (choose components interactively)

COMPONENTS:
    You can specify individual components to install:
$(printf "    %s\n" "${AVAILABLE_INSTALLERS[@]}")

Examples:
    $0                          # Install all components
    $0 --all                    # Install all components
    $0 homebrew git iterm2      # Install only specified components
    $0 --selective              # Choose components interactively
    $0 --list                   # List available components

Each component is installed by a separate script in installers/ directory.
You can also run individual installers directly:
    ./installers/homebrew.sh   # Install only Homebrew
    ./installers/git.sh        # Install only Git
EOF
}

# Function to list available components
list_components() {
    log "Available installation components:"
    for installer in "${AVAILABLE_INSTALLERS[@]}"; do
        local script_path="$INSTALLERS_DIR/${installer}.sh"
        if [[ -f "$script_path" ]]; then
            local description
            description=$(grep "^# .*installation" "$script_path" | head -1 | sed 's/^# //')
            log_success "  $installer - $description"
        else
            log_warning "  $installer - Script not found: $script_path"
        fi
    done
}

# Function for selective installation
selective_install() {
    log "Selective installation mode"
    echo "Choose components to install (press Enter to toggle, 'a' for all, 'n' for none, 'd' when done):"
    
    declare -a selected=()
    local i=0
    
    # Initialize selection array
    for installer in "${AVAILABLE_INSTALLERS[@]}"; do
        selected[i]=false
        ((i++))
    done
    
    while true; do
        clear
        echo "=== Selective Installation Mode ==="
        echo
        i=0
        for installer in "${AVAILABLE_INSTALLERS[@]}"; do
            local status="[ ]"
            if [[ "${selected[i]}" == "true" ]]; then
                status="[x]"
            fi
            echo "$((i+1)). $status $installer"
            ((i++))
        done
        echo
        echo "Commands: 1-${#AVAILABLE_INSTALLERS[@]} (toggle), 'a' (all), 'n' (none), 'd' (done)"
        read -p "Your choice: " choice
        
        case "$choice" in
            [1-9]|[1][0-9])
                local idx=$((choice-1))
                if [[ $idx -ge 0 && $idx -lt ${#AVAILABLE_INSTALLERS[@]} ]]; then
                    if [[ "${selected[idx]}" == "true" ]]; then
                        selected[idx]=false
                    else
                        selected[idx]=true
                    fi
                fi
                ;;
            a|A)
                for i in "${!selected[@]}"; do
                    selected[i]=true
                done
                ;;
            n|N)
                for i in "${!selected[@]}"; do
                    selected[i]=false
                done
                ;;
            d|D)
                break
                ;;
        esac
    done
    
    # Build selected components array
    declare -a components_to_install=()
    i=0
    for installer in "${AVAILABLE_INSTALLERS[@]}"; do
        if [[ "${selected[i]}" == "true" ]]; then
            components_to_install+=("$installer")
        fi
        ((i++))
    done
    
    if [[ ${#components_to_install[@]} -eq 0 ]]; then
        log_warning "No components selected for installation"
        return 1
    fi
    
    log "Selected components: ${components_to_install[*]}"
    install_components "${components_to_install[@]}"
}

# Function to run individual installer
run_installer() {
    local installer="$1"
    local script_path="$INSTALLERS_DIR/${installer}.sh"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "Installer script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        chmod +x "$script_path"
    fi
    
    log "Running installer: $installer"
    if bash "$script_path"; then
        log_success "$installer installation completed"
        return 0
    else
        local exit_code=$?
        log_error "$installer installation failed (exit code: $exit_code)"
        return $exit_code
    fi
}

# Function to install specified components
install_components() {
    local components=("$@")
    local total=${#components[@]}
    local current=0
    local failed_installers=()
    
    log "Starting installation of $total components..."
    
    for installer in "${components[@]}"; do
        current=$((current + 1))
        log "[$current/$total] Installing $installer..."
        
        if ! run_installer "$installer"; then
            failed_installers+=("$installer")
            log_warning "Continuing with remaining components..."
        fi
        
        echo
    done
    
    # Installation summary
    log "Installation Summary:"
    log "Total components: $total"
    log "Successful: $((total - ${#failed_installers[@]}))"
    
    if [[ ${#failed_installers[@]} -gt 0 ]]; then
        log_warning "Failed installations: ${failed_installers[*]}"
        echo
        log "Failed components can be installed individually:"
        for failed in "${failed_installers[@]}"; do
            log "  ./installers/${failed}.sh"
        done
    else
        log_success "All components installed successfully!"
    fi
}

# Function to validate components
validate_components() {
    local components=("$@")
    local invalid_components=()
    
    for component in "${components[@]}"; do
        local found=false
        for available in "${AVAILABLE_INSTALLERS[@]}"; do
            if [[ "$component" == "$available" ]]; then
                found=true
                break
            fi
        done
        
        if [[ "$found" == "false" ]]; then
            invalid_components+=("$component")
        fi
    done
    
    if [[ ${#invalid_components[@]} -gt 0 ]]; then
        log_error "Invalid components: ${invalid_components[*]}"
        log "Available components: ${AVAILABLE_INSTALLERS[*]}"
        return 1
    fi
    
    return 0
}

# Main execution function
main() {
    log "Starting modular macOS development environment setup..."
    log "Script directory: $SCRIPT_DIR"
    log "Installers directory: $INSTALLERS_DIR"
    
    # Check basic requirements
    check_macos
    check_not_root
    
    # Verify installers directory exists
    if [[ ! -d "$INSTALLERS_DIR" ]]; then
        log_error "Installers directory not found: $INSTALLERS_DIR"
        log "Please ensure you have the complete setup package"
        exit 1
    fi
    
    # Parse command line arguments
    local components_to_install=()
    local install_mode="all"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list)
                list_components
                exit 0
                ;;
            -a|--all)
                install_mode="all"
                shift
                ;;
            -s|--selective)
                install_mode="selective"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                components_to_install+=("$1")
                install_mode="specified"
                shift
                ;;
        esac
    done
    
    # Execute based on mode
    case "$install_mode" in
        "all")
            log "Installing all available components..."
            install_components "${AVAILABLE_INSTALLERS[@]}"
            ;;
        "selective")
            selective_install
            ;;
        "specified")
            if ! validate_components "${components_to_install[@]}"; then
                exit 1
            fi
            log "Installing specified components: ${components_to_install[*]}"
            install_components "${components_to_install[@]}"
            ;;
    esac
    
    log_success "Setup completed! Please restart your terminal to apply all changes."
    log "Individual installers are available in: $INSTALLERS_DIR"
    log "You can run them individually anytime: ./installers/<component>.sh"
}

# Run main function
main "$@"