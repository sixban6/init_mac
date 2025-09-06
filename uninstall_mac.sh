#!/bin/bash

# MacOS Development Environment Uninstall Script
# Removes: Python, Java (OpenJDK), Rust, Node.js, sing-box, VS Code
# Keeps: Homebrew, iTerm2, Go, Git
# Follows safe uninstall practices

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if application is installed
is_app_installed() {
    [ -d "/Applications/$1.app" ]
}

# Remove lines from shell profile
remove_from_profile() {
    local pattern="$1"
    local shell_profile=""
    
    case "$SHELL" in
        */zsh) shell_profile="$HOME/.zshrc" ;;
        */bash) shell_profile="$HOME/.bash_profile" ;;
        *) shell_profile="$HOME/.profile" ;;
    esac
    
    if [[ -f "$shell_profile" ]]; then
        # Create backup
        cp "$shell_profile" "${shell_profile}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Remove lines containing the pattern
        grep -v "$pattern" "$shell_profile" > "${shell_profile}.tmp" || true
        mv "${shell_profile}.tmp" "$shell_profile"
        log_success "Removed $pattern from $shell_profile"
    fi
}

# Uninstall Python packages and configuration
uninstall_python() {
    log "Uninstalling Python packages and configuration..."
    
    if command_exists python3; then
        # Remove pip configuration
        if [[ -f "$HOME/.pip/pip.conf" ]]; then
            rm -f "$HOME/.pip/pip.conf"
            log_success "Removed pip configuration"
        fi
        
        # Remove Python environment from shell profile
        remove_from_profile "Python environment"
        remove_from_profile "python3"
        remove_from_profile "pip3"
        
        log_success "Python configuration removed (Homebrew Python kept as dependency)"
    else
        log_warning "Python not found"
    fi
}

# Uninstall Java (OpenJDK)
uninstall_java() {
    log "Uninstalling Java (OpenJDK)..."
    
    if command_exists brew && brew list openjdk &>/dev/null; then
        # Remove Java from Homebrew
        brew uninstall openjdk
        log_success "OpenJDK uninstalled"
        
        # Remove Java environment from shell profile
        remove_from_profile "Java environment"
        remove_from_profile "JAVA_HOME"
        
        # Remove system symlink if exists
        if [[ -L "/Library/Java/JavaVirtualMachines/openjdk.jdk" ]]; then
            sudo rm -f "/Library/Java/JavaVirtualMachines/openjdk.jdk"
            log_success "Removed Java system symlink"
        fi
        
        log_success "Java (OpenJDK) completely uninstalled"
    else
        log_warning "Java (OpenJDK) not found or not installed via Homebrew"
    fi
}

# Uninstall Rust
uninstall_rust() {
    log "Uninstalling Rust..."
    
    if command_exists brew && brew list rust &>/dev/null; then
        # Remove Rust from Homebrew
        brew uninstall rust
        log_success "Rust uninstalled"
        
        # Remove Rust environment from shell profile
        remove_from_profile "Rust environment"
        remove_from_profile "CARGO_HOME"
        remove_from_profile "cargo"
        
        # Remove Cargo configuration
        if [[ -f "$HOME/.cargo/config" ]]; then
            rm -f "$HOME/.cargo/config"
            log_success "Removed Cargo configuration"
        fi
        
        # Remove .cargo directory if empty (but keep if user has custom stuff)
        if [[ -d "$HOME/.cargo" ]] && [[ -z "$(ls -A "$HOME/.cargo" 2>/dev/null)" ]]; then
            rmdir "$HOME/.cargo"
            log_success "Removed empty .cargo directory"
        fi
        
        log_success "Rust completely uninstalled"
    else
        log_warning "Rust not found or not installed via Homebrew"
    fi
}

# Uninstall Node.js
uninstall_nodejs() {
    log "Uninstalling Node.js..."
    
    if command_exists brew && brew list node &>/dev/null; then
        # Remove Node.js from Homebrew
        brew uninstall node
        log_success "Node.js uninstalled"
        
        # Remove Node.js environment from shell profile
        remove_from_profile "Node.js environment"
        remove_from_profile "NPM_CONFIG_PREFIX"
        
        # Remove npm global directory if it was customized
        local npm_global="$HOME/.npm-global"
        if [[ -d "$npm_global" ]]; then
            rm -rf "$npm_global"
            log_success "Removed npm global directory"
        fi
        
        # Clean up npm cache
        if [[ -d "$HOME/.npm" ]]; then
            rm -rf "$HOME/.npm"
            log_success "Removed npm cache"
        fi
        
        log_success "Node.js completely uninstalled"
    else
        log_warning "Node.js not found or not installed via Homebrew"
    fi
}

# Uninstall sing-box
uninstall_singbox() {
    log "Uninstalling sing-box..."
    
    if command_exists brew && brew list sing-box &>/dev/null; then
        # Remove sing-box from Homebrew
        brew uninstall sing-box
        log_success "sing-box uninstalled"
        
        # Remove sing-box configuration directory
        local config_dir="$HOME/.config/sing-box"
        if [[ -d "$config_dir" ]]; then
            rm -rf "$config_dir"
            log_success "Removed sing-box configuration directory"
        fi
        
        log_success "sing-box completely uninstalled"
    else
        log_warning "sing-box not found or not installed via Homebrew"
    fi
}

# Uninstall VS Code
uninstall_vscode() {
    log "Uninstalling VS Code..."
    
    if is_app_installed "Visual Studio Code"; then
        # Remove VS Code application
        rm -rf "/Applications/Visual Studio Code.app"
        log_success "VS Code application removed"
        
        # Remove VS Code command line tools
        if [[ -f "/usr/local/bin/code" ]]; then
            sudo rm -f "/usr/local/bin/code"
            log_success "Removed VS Code command line tool"
        fi
        
        # Remove VS Code from shell profile
        remove_from_profile "VS Code"
        remove_from_profile "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
        
        # Remove VS Code user data (optional - ask user)
        local vscode_data="$HOME/Library/Application Support/Code"
        if [[ -d "$vscode_data" ]]; then
            read -p "Remove VS Code user data and extensions? (y/N): " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$vscode_data"
                rm -rf "$HOME/.vscode"
                log_success "Removed VS Code user data and extensions"
            else
                log_warning "VS Code user data preserved"
            fi
        fi
        
        log_success "VS Code completely uninstalled"
    else
        log_warning "VS Code not found"
    fi
}

# Clean up Homebrew dependencies
cleanup_homebrew() {
    log "Cleaning up unused Homebrew dependencies..."
    
    if command_exists brew; then
        # Remove unused dependencies
        brew autoremove
        
        # Clean up cache
        brew cleanup
        
        log_success "Homebrew cleanup completed"
    fi
}

# Show current status
show_status() {
    log "Current installation status:"
    echo "=================================================="
    log "• Homebrew: $(command_exists brew && echo "✅ Kept ($(brew --version | head -1))" || echo "❌ Not installed")"
    log "• iTerm2: $(is_app_installed "iTerm" && echo "✅ Kept" || echo "❌ Not installed")"
    log "• Git: $(command_exists git && echo "✅ Kept ($(git --version | cut -d' ' -f3))" || echo "❌ Not installed")"
    log "• Go: $(command_exists go && echo "✅ Kept ($(go version | cut -d' ' -f3))" || echo "❌ Not installed")"
    log "• Python: $(command_exists python3 && echo "✅ Kept ($(python3 --version))" || echo "❌ Not installed")"
    echo "=================================================="
    log "• Java: $(command_exists java && echo "❌ Still installed" || echo "✅ Removed")"
    log "• Rust: $(command_exists rustc && echo "❌ Still installed" || echo "✅ Removed")"
    log "• Node.js: $(command_exists node && echo "❌ Still installed" || echo "✅ Removed")"
    log "• sing-box: $(command_exists sing-box && echo "❌ Still installed" || echo "✅ Removed")"
    log "• VS Code: $(is_app_installed "Visual Studio Code" && echo "❌ Still installed" || echo "✅ Removed")"
    echo "=================================================="
}

# Main execution
main() {
    log "Starting macOS development environment uninstall..."
    echo "This will remove: Java, Rust, Node.js, sing-box, VS Code"
    echo "This will keep: Homebrew, iTerm2, Git, Go, Python"
    echo ""
    
    read -p "Continue with uninstallation? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Uninstallation cancelled"
        exit 0
    fi
    
    # Perform uninstallations
    uninstall_vscode
    uninstall_singbox
    uninstall_nodejs
    uninstall_rust
    uninstall_java
    # uninstall_python  # Keep Python - it's too important for development
    
    # Cleanup
    cleanup_homebrew
    
    # Show final status
    echo ""
    log_success "Uninstallation completed!"
    echo ""
    show_status
    
    echo ""
    log "Please restart your terminal or run: source ~/.zshrc"
    log "Some changes may require a system restart to take full effect."
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

# Check for required commands
if ! command_exists brew; then
    log_error "Homebrew not found. Cannot proceed with uninstallation."
    exit 1
fi

# Run main function
main "$@"