#!/bin/bash

# iTerm2 installation and configuration
# This script installs iTerm2, Oh My Zsh, and configures the terminal environment

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# iTerm2 installation and configuration
install_iterm2() {
    log "Checking iTerm2 installation..."
    
    if is_app_installed "iTerm"; then
        log_success "iTerm2 already installed"
        configure_iterm2  # Always configure themes, even if already installed
        return 0
    fi
    
    log "Installing iTerm2..."
    local download_url="https://iterm2.com/downloads/stable/latest"
    local temp_file="/tmp/iterm2.zip"
    
    # Download iTerm2
    if secure_download "$download_url" "$temp_file" ""; then
        log "Extracting iTerm2..."
        unzip -q "$temp_file" -d /tmp/
        mv "/tmp/iTerm.app" "/Applications/"
        rm "$temp_file"
    else
        log_error "Failed to download iTerm2"
        return 1
    fi
    
    log_success "iTerm2 installed successfully"
    configure_iterm2
}

configure_iterm2() {
    log "Configuring iTerm2 with Oh My Zsh and modern development theme..."
    
    # Clean up any previous malformed configuration
    defaults delete com.googlecode.iterm2 "PrefsCustomFolder" 2>/dev/null || true
    defaults delete com.googlecode.iterm2 "LoadPrefsFromCustomFolder" 2>/dev/null || true
    
    # Install Oh My Zsh if not already installed
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log "Installing Oh My Zsh..."
        retry_command "Oh My Zsh installation" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh installed"
    else
        log_success "Oh My Zsh already installed"
    fi
    
    # Install Nerd Fonts (modern replacement for Powerline fonts)
    log "Installing Nerd Fonts for proper Oh My Zsh theme display..."
    
    # Install Meslo LG Nerd Font via Homebrew (more reliable than manual installation)
    if command_exists brew; then
        if ! brew list font-meslo-lg-nerd-font &>/dev/null; then
            log "Installing Meslo LG Nerd Font via Homebrew..."
            retry_command "Nerd Font installation" brew install font-meslo-lg-nerd-font
            log_success "Meslo LG Nerd Font installed successfully"
        else
            log_success "Meslo LG Nerd Font already installed"
        fi
    else
        log_warning "Homebrew not available, skipping Nerd Font installation"
    fi
    
    # Install Oh My Zsh plugins
    log "Installing Oh My Zsh plugins..."
    local custom_plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    mkdir -p "$custom_plugins_dir"
    
    # Install zsh-syntax-highlighting
    if [[ ! -d "$custom_plugins_dir/zsh-syntax-highlighting" ]]; then
        retry_command "zsh-syntax-highlighting plugin" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_plugins_dir/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting plugin installed"
    fi
    
    # Install zsh-autosuggestions
    if [[ ! -d "$custom_plugins_dir/zsh-autosuggestions" ]]; then
        retry_command "zsh-autosuggestions plugin" git clone https://github.com/zsh-users/zsh-autosuggestions.git "$custom_plugins_dir/zsh-autosuggestions"
        log_success "zsh-autosuggestions plugin installed"
    fi
    
    # Configure .zshrc
    configure_zshrc
    
    # Configure iTerm2 preferences
    configure_iterm2_preferences
    
    # Configure Oh My Zsh theme based on font availability
    configure_oh_my_zsh_theme
    
    log_success "iTerm2 configured with Oh My Zsh and modern development environment"
    log "Oh My Zsh: Installed with bureau theme (professional developer theme)"
    log "Theme Features: Detailed git status, time display, clean layout, works with any font"
    log "Plugins: zsh-syntax-highlighting, zsh-autosuggestions, and developer tools"
    log "Font: System fonts work perfectly with bureau theme"
    log "Next steps: Restart iTerm2 and enjoy your enhanced terminal experience!"
}

configure_zshrc() {
    log "Configuring .zshrc..."
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]]; then
        # Backup original .zshrc
        cp "$zshrc" "${zshrc}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Update plugins
        if grep -q "plugins=(" "$zshrc"; then
            sed -i.bak 's/plugins=(.*)/plugins=(git brew node npm python ruby rails golang rust docker kubectl zsh-syntax-highlighting zsh-autosuggestions)/' "$zshrc"
        else
            echo 'plugins=(git brew node npm python ruby rails golang rust docker kubectl zsh-syntax-highlighting zsh-autosuggestions)' >> "$zshrc"
        fi
        
        # Add custom configurations
        if ! grep -q "Custom iTerm2 + Oh My Zsh configuration" "$zshrc"; then
            cat >> "$zshrc" << 'EOF'

# Custom iTerm2 + Oh My Zsh configuration
# Hide user@hostname in agnoster theme (optional)
DEFAULT_USER="$(whoami)"

# Development aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias gst='git status'
alias gco='git checkout'
alias gcm='git commit -m'
alias gps='git push'
alias gpl='git pull'
EOF
        fi
        
        log_success ".zshrc configured with bureau theme and plugins"
    fi
}

configure_iterm2_preferences() {
    log "Configuring iTerm2 preferences for development..."
    local plist="com.googlecode.iterm2"
    
    # Window and tab settings
    defaults write "$plist" "UseBorder" -bool false
    defaults write "$plist" "HideTab" -bool false
    defaults write "$plist" "TabsHaveCloseButton" -bool true
    defaults write "$plist" "WindowNumber" -bool false
    defaults write "$plist" "ShowFullScreenTabBar" -bool false
    
    # Set appropriate window size for development (120 columns x 40 rows)
    defaults write "$plist" "Default Bookmark Columns" -int 120
    defaults write "$plist" "Default Bookmark Rows" -int 40
    
    # Font settings - use system fonts (works with any font)
    if ls "$HOME/Library/Fonts/"*Meslo*Nerd* >/dev/null 2>&1; then
        log_success "Nerd Font detected, configuring iTerm2 to use MesloLGS Nerd Font"
        defaults write "$plist" "Normal Font" -string "MesloLGS-NF-Regular 14"
        defaults write "$plist" "Non-ASCII Font" -string "MesloLGS-NF-Regular 14"
        defaults write "$plist" "Font" -string "MesloLGS Nerd Font"
        defaults write "$plist" "Font Size" -int 14
    else
        log "Using system default font"
        defaults write "$plist" "Normal Font" -string "SF Mono Regular 14"
        defaults write "$plist" "Non-ASCII Font" -string "SF Mono Regular 14"
        defaults write "$plist" "Font" -string "SF Mono"
        defaults write "$plist" "Font Size" -int 14
    fi
    
    # Terminal behavior
    defaults write "$plist" "Silence Bell" -bool true
    defaults write "$plist" "FlashingBell" -bool false
    defaults write "$plist" "VisualBell" -bool false
    defaults write "$plist" "BellAlert" -bool false
    
    # Cursor settings
    defaults write "$plist" "CursorBlink" -bool true
    defaults write "$plist" "CursorType" -int 2  # Underline cursor
    
    # Scrollback settings
    defaults write "$plist" "Scrollback Lines" -int 10000
    defaults write "$plist" "Unlimited Scrollback" -bool false
    
    # Performance settings
    defaults write "$plist" "UseMetal" -bool true
    
    log_success "iTerm2 preferences configured for development"
}

# Configure Oh My Zsh theme based on available fonts
configure_oh_my_zsh_theme() {
    log "Configuring Oh My Zsh theme..."
    local zshrc="$HOME/.zshrc"
    
    # Use bureau theme - perfect for developers, no special fonts needed
    log_success "Configuring bureau theme (professional theme for developers)"
    if [[ -f "$zshrc" ]]; then
        # Backup and update theme to bureau
        cp "$zshrc" "${zshrc}.theme_backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
        sed -i.bak 's/ZSH_THEME=".*"/ZSH_THEME="bureau"/' "$zshrc" 2>/dev/null || true
        log_success "bureau theme configured - shows detailed git status, time, and clean layout"
    fi
    
    # Add helpful comment to .zshrc about theme choice
    if [[ -f "$zshrc" ]] && ! grep -q "Bureau theme info" "$zshrc"; then
        cat >> "$zshrc" << 'EOF'

# Bureau theme info:
# - Professional theme perfect for developers
# - Shows detailed git status (staged, unstaged, untracked files)
# - Displays current path, user@host, and time
# - Works with any monospace font (no special fonts required)
# - Color coded: Green=clean/good, Yellow=staged changes, Red=problems
#
# Other good developer themes to try:
# ZSH_THEME="dst"          # Simple, shows command status
# ZSH_THEME="blinks"       # Colorful, git status
# ZSH_THEME="robbyrussell" # Minimal default
EOF
        log_success "Added theme information to .zshrc"
    fi
}

main() {
    check_macos
    check_not_root
    
    # Install Xcode Command Line Tools if not present
    if ! command_exists git; then
        log "Installing Xcode Command Line Tools..."
        xcode-select --install
        log "Please complete Xcode Command Line Tools installation and run this script again"
        exit 0
    fi
    
    install_iterm2
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi