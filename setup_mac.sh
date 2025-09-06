#!/bin/bash

# MacOS Development Environment Setup Script
# Features: iTerm2, Homebrew (China mirrors), Git, Go, Python, Java (Zulu JDK), Rust, Node.js, sing-box, VS Code
# Follows OCP principles with modular functions

set -euo pipefail

# Determine script directory and log file location
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "$HOME")}"
# Ensure log file is writable - use /tmp if SCRIPT_DIR is not writable
if [[ ! -w "$SCRIPT_DIR" ]]; then
    SCRIPT_DIR="/tmp"
fi
readonly SCRIPT_DIR
readonly LOG_FILE="$SCRIPT_DIR/setup.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions with fallback for permission issues
log() {
    local message="${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $*${NC}"
    echo -e "$message"
    echo -e "$message" >> "$LOG_FILE" 2>/dev/null || true
}

log_success() {
    local message="${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✓ $*${NC}"
    echo -e "$message"
    echo -e "$message" >> "$LOG_FILE" 2>/dev/null || true
}

log_warning() {
    local message="${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠ $*${NC}"
    echo -e "$message"
    echo -e "$message" >> "$LOG_FILE" 2>/dev/null || true
}

log_error() {
    local message="${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ✗ $*${NC}"
    echo -e "$message"
    echo -e "$message" >> "$LOG_FILE" 2>/dev/null || true
}

# Utility functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_app_installed() {
    [ -d "/Applications/$1.app" ]
}

version_ge() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

get_latest_github_release() {
    local repo="$1"
    curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# iTerm2 installation and configuration
install_iterm2() {
    log "Checking iTerm2 installation..."
    
    if is_app_installed "iTerm"; then
        log_success "iTerm2 already installed"
        return 0
    fi
    
    log "Installing iTerm2..."
    local download_url="https://iterm2.com/downloads/stable/latest"
    local temp_file="/tmp/iterm2.zip"
    
    curl -L "$download_url" -o "$temp_file"
    unzip -q "$temp_file" -d /tmp/
    mv "/tmp/iTerm.app" "/Applications/"
    rm "$temp_file"
    
    log_success "iTerm2 installed successfully"
    configure_iterm2
}

configure_iterm2() {
    log "Configuring iTerm2 for development..."
    
    local plist_file="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    
    # Create basic configuration
    defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "73B1CF6B-9E1A-4C27-9190-C1C4E90F3D8A"
    defaults write com.googlecode.iterm2 "New Bookmarks" -array-add '{
        "Name" = "Default";
        "Guid" = "73B1CF6B-9E1A-4C27-9190-C1C4E90F3D8A";
        "Working Directory" = "~";
        "Command" = "";
        "Custom Command" = "No";
    }'
    
    # Set as default terminal
    defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{
        LSHandlerContentType = "public.unix-executable";
        LSHandlerRoleShell = "com.googlecode.iterm2";
    }'
    
    log_success "iTerm2 configured and set as default terminal"
}

# Homebrew installation with China mirrors
install_homebrew() {
    log "Checking Homebrew installation..."
    
    if command_exists brew; then
        log_success "Homebrew already installed"
        configure_homebrew_china_mirror
        return 0
    fi
    
    log "Installing Homebrew with China mirror..."
    
    # Use China mirror for installation
    export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
    export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
    
    /bin/bash -c "$(curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/git/homebrew-install/HEAD/install.sh)"
    
    log_success "Homebrew installed successfully"
    configure_homebrew_china_mirror
}

configure_homebrew_china_mirror() {
    log "Configuring Homebrew China mirrors..."
    
    # Set China mirrors
    cd "$(brew --repo)"
    git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
    
    cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
    git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
    
    # Add environment variables to shell profile
    local shell_profile=""
    case "$SHELL" in
        */zsh) shell_profile="$HOME/.zshrc" ;;
        */bash) shell_profile="$HOME/.bash_profile" ;;
        *) shell_profile="$HOME/.profile" ;;
    esac
    
    if ! grep -q "HOMEBREW_BOTTLE_DOMAIN" "$shell_profile" 2>/dev/null; then
        cat >> "$shell_profile" << 'EOF'

# Homebrew China Mirror
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
export HOMEBREW_BREW_GIT_REMOTE=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
export HOMEBREW_CORE_GIT_REMOTE=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
EOF
        log_success "Homebrew China mirror configuration added to $shell_profile"
    fi
    
    export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
    brew update
    
    log_success "Homebrew China mirrors configured"
}

# Git installation and upgrade
install_git() {
    log "Checking Git installation..."
    
    local system_git_version=""
    local brew_git_version=""
    local should_install=false
    
    # Check system Git version
    if command_exists git; then
        system_git_version=$(git --version 2>/dev/null | cut -d' ' -f3 || echo "unknown")
        log "System Git version: $system_git_version"
    fi
    
    # Get latest Homebrew Git version
    if command_exists brew; then
        brew_git_version=$(brew info git 2>/dev/null | grep -E '^git: ' | head -1 | cut -d' ' -f2 || echo "unknown")
        log "Latest Homebrew Git version: $brew_git_version"
        
        # Force upgrade if Homebrew version is newer or if system Git doesn't exist
        if [[ -z "$system_git_version" ]] || ! version_ge "$system_git_version" "$brew_git_version"; then
            should_install=true
        fi
    else
        log_error "Homebrew is required to install Git"
        return 1
    fi
    
    if $should_install; then
        log "Installing/upgrading Git to latest version..."
        
        # Install Git via Homebrew (this will be the latest version)
        brew install git
        
        # Configure shell to use Homebrew Git first
        local shell_profile=""
        case "$SHELL" in
            */zsh) shell_profile="$HOME/.zshrc" ;;
            */bash) shell_profile="$HOME/.bash_profile" ;;
            *) shell_profile="$HOME/.profile" ;;
        esac
        
        if ! grep -q "/usr/local/bin.*git" "$shell_profile" 2>/dev/null; then
            cat >> "$shell_profile" << 'EOF'

# Git environment - Use Homebrew Git
export PATH="/usr/local/bin:$PATH"
EOF
            log_success "Git environment configuration added to $shell_profile"
        fi
        
        # Update current session PATH
        export PATH="/usr/local/bin:$PATH"
        
        # Verify installation
        local new_version
        new_version=$(git --version | cut -d' ' -f3)
        log_success "Git upgraded successfully to version $new_version"
    else
        log_success "Git is already up to date (version: $system_git_version)"
    fi
    
    # Configure China mirrors for Git
    configure_git_china_mirrors
}

# Configure Git China mirrors
configure_git_china_mirrors() {
    log "Configuring Git basic settings..."
    
    # Configure basic Git settings for better performance in China
    git config --global http.postBuffer 1048576000
    git config --global http.maxRequestBuffer 100M
    git config --global core.preloadindex true
    git config --global core.fscache true
    git config --global gc.auto 256
    
    # Note: Users can manually configure GitHub mirrors if needed:
    # git config --global url."https://mirror.ghproxy.com/https://github.com/".insteadOf "https://github.com/"
    
    log_success "Git performance settings configured for China network"
}

# Go installation and configuration
install_go() {
    log "Checking Go installation..."
    
    if command_exists go; then
        local current_version
        current_version=$(go version | cut -d' ' -f3 | sed 's/go//')
        local latest_version
        latest_version=$(brew info go | grep -E '^go: ' | cut -d' ' -f2)
        
        if version_ge "$current_version" "$latest_version"; then
            log_success "Go is up to date (version: $current_version)"
            return 0
        else
            log_warning "Go version $current_version is outdated, updating to $latest_version"
        fi
    fi
    
    log "Installing/updating Go..."
    brew install go
    
    # Configure Go environment
    local shell_profile=""
    case "$SHELL" in
        */zsh) shell_profile="$HOME/.zshrc" ;;
        */bash) shell_profile="$HOME/.bash_profile" ;;
        *) shell_profile="$HOME/.profile" ;;
    esac
    
    if ! grep -q "GOPATH" "$shell_profile" 2>/dev/null; then
        cat >> "$shell_profile" << 'EOF'

# Go environment
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
# Go China mirror proxy
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
EOF
        log_success "Go environment configuration added to $shell_profile"
    fi
    
    # Set current session environment
    export GOPATH="$HOME/go"
    export PATH="$PATH:$GOPATH/bin"
    export GOPROXY="https://goproxy.cn,direct"
    export GOSUMDB="sum.golang.google.cn"
    
    # Create GOPATH directory
    mkdir -p "$HOME/go/src" "$HOME/go/bin" "$HOME/go/pkg"
    
    log_success "Go installed and configured successfully with China proxy"
}

# Python installation and configuration
install_python() {
    log "Checking Python installation..."
    
    if command_exists python3; then
        local current_version
        current_version=$(python3 --version | cut -d' ' -f2)
        local latest_version
        latest_version=$(brew info python@3 | grep -E '^python@3' | head -1 | cut -d' ' -f2)
        
        if version_ge "$current_version" "${latest_version#*@}"; then
            log_success "Python is up to date (version: $current_version)"
            return 0
        else
            log_warning "Python version $current_version is outdated, updating to latest"
        fi
    fi
    
    log "Installing/updating Python..."
    brew install python@3
    
    # Ensure python3 and pip3 are in PATH
    local shell_profile=""
    case "$SHELL" in
        */zsh) shell_profile="$HOME/.zshrc" ;;
        */bash) shell_profile="$HOME/.bash_profile" ;;
        *) shell_profile="$HOME/.profile" ;;
    esac
    
    if ! grep -q "python3" "$shell_profile" 2>/dev/null; then
        cat >> "$shell_profile" << 'EOF'

# Python environment
export PATH="/usr/local/opt/python@3/bin:$PATH"
alias python=python3
alias pip=pip3
EOF
        log_success "Python environment configuration added to $shell_profile"
    fi
    
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
    
    # Install essential Python packages with China mirror
    python3 -m pip install --upgrade pip setuptools wheel
    
    log_success "Python installed and configured successfully with China mirror"
}

# Java (Zulu JDK) installation and configuration
install_java() {
    log "Checking Java JDK installation..."
    
    if command_exists java; then
        local current_version
        current_version=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1-2)
        local latest_version
        latest_version=$(brew info zulu | grep -E '^zulu' | head -1 | cut -d' ' -f2 | cut -d'.' -f1-2)
        
        if version_ge "$current_version" "$latest_version"; then
            log_success "Java JDK is up to date (version: $current_version)"
            return 0
        else
            log_warning "Java JDK version $current_version is outdated, updating to $latest_version"
        fi
    fi
    
    log "Installing/updating Java (Zulu JDK)..."
    
    # Add Azul tap for Zulu JDK
    brew tap azul/zulu
    brew install --cask zulu
    
    # Configure Java environment
    local shell_profile=""
    case "$SHELL" in
        */zsh) shell_profile="$HOME/.zshrc" ;;
        */bash) shell_profile="$HOME/.bash_profile" ;;
        *) shell_profile="$HOME/.profile" ;;
    esac
    
    # Find the Zulu JDK installation path
    local java_home
    java_home=$(/usr/libexec/java_home -v "$(brew list --cask zulu | grep -o '[0-9]\+' | head -1)" 2>/dev/null || /usr/libexec/java_home 2>/dev/null || echo "")
    
    if [[ -n "$java_home" ]] && ! grep -q "JAVA_HOME" "$shell_profile" 2>/dev/null; then
        cat >> "$shell_profile" << EOF

# Java environment
export JAVA_HOME=$java_home
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
        log_success "Java environment configuration added to $shell_profile"
    elif [[ -n "$java_home" ]]; then
        log_success "Java environment already configured in $shell_profile"
    else
        log_warning "Could not determine JAVA_HOME, please configure manually"
    fi
    
    # Set current session environment
    if [[ -n "$java_home" ]]; then
        export JAVA_HOME="$java_home"
        export PATH="$JAVA_HOME/bin:$PATH"
    fi
    
    log_success "Java (Zulu JDK) installed and configured successfully"
}

# Rust installation and configuration
install_rust() {
    log "Checking Rust installation..."
    
    if command_exists rustc; then
        local current_version
        current_version=$(rustc --version | cut -d' ' -f2)
        local latest_version
        latest_version=$(brew info rust | grep -E '^rust: ' | head -1 | cut -d' ' -f2)
        
        if version_ge "$current_version" "$latest_version"; then
            log_success "Rust is up to date (version: $current_version)"
            return 0
        else
            log_warning "Rust version $current_version is outdated, updating to $latest_version"
        fi
    fi
    
    log "Installing/updating Rust..."
    brew install rust
    
    # Configure Rust environment
    local shell_profile=""
    case "$SHELL" in
        */zsh) shell_profile="$HOME/.zshrc" ;;
        */bash) shell_profile="$HOME/.bash_profile" ;;
        *) shell_profile="$HOME/.profile" ;;
    esac
    
    if ! grep -q "CARGO_HOME" "$shell_profile" 2>/dev/null; then
        cat >> "$shell_profile" << 'EOF'

# Rust environment
export CARGO_HOME="$HOME/.cargo"
export PATH="$CARGO_HOME/bin:$PATH"
EOF
        log_success "Rust environment configuration added to $shell_profile"
    fi
    
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

# Node.js installation and configuration
install_nodejs() {
    log "Checking Node.js installation..."
    
    if command_exists node; then
        local current_version
        current_version=$(node --version | sed 's/v//')
        local latest_version
        latest_version=$(brew info node | grep -E '^node: ' | head -1 | cut -d' ' -f2)
        
        if version_ge "$current_version" "$latest_version"; then
            log_success "Node.js is up to date (version: v$current_version)"
            return 0
        else
            log_warning "Node.js version v$current_version is outdated, updating to v$latest_version"
        fi
    fi
    
    log "Installing/updating Node.js..."
    brew install node
    
    # Verify npm is also available
    if command_exists npm; then
        local npm_version
        npm_version=$(npm --version)
        log_success "npm is available (version: $npm_version)"
        
        # Configure npm global directory to avoid permission issues
        local npm_global="$HOME/.npm-global"
        if [[ ! -d "$npm_global" ]]; then
            mkdir -p "$npm_global"
            npm config set prefix "$npm_global"
        fi
        
        # Configure npm China mirror
        npm config set registry https://registry.npmmirror.com
        npm config set disturl https://npmmirror.com/dist
        npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/
        npm config set electron_mirror https://npmmirror.com/mirrors/electron/
        npm config set puppeteer_download_host https://npmmirror.com/mirrors
        npm config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver
        npm config set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver
        npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs
        npm config set selenium_cdnurl https://npmmirror.com/mirrors/selenium
        npm config set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector
        
        log_success "npm China mirror configured"
        
        # Configure shell environment for npm global packages
        local shell_profile=""
        case "$SHELL" in
            */zsh) shell_profile="$HOME/.zshrc" ;;
            */bash) shell_profile="$HOME/.bash_profile" ;;
            *) shell_profile="$HOME/.profile" ;;
        esac
        
        if ! grep -q "npm-global" "$shell_profile" 2>/dev/null; then
            cat >> "$shell_profile" << 'EOF'

# Node.js and npm environment
export PATH="$HOME/.npm-global/bin:$PATH"
EOF
            log_success "npm global packages configuration added to $shell_profile"
        fi
        
        # Set current session environment
        export PATH="$HOME/.npm-global/bin:$PATH"
    fi
    
    log_success "Node.js installed and configured successfully with China mirror"
}

# sing-box installation and configuration
install_singbox() {
    log "Checking sing-box installation..."
    
    if command_exists sing-box; then
        local current_version
        current_version=$(sing-box version 2>/dev/null | head -1 | cut -d' ' -f3 2>/dev/null || echo "unknown")
        local latest_version
        latest_version=$(brew info sing-box | grep -E '^sing-box: ' | head -1 | cut -d' ' -f2 2>/dev/null || echo "unknown")
        
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
    
    brew install sing-box
    
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

# VS Code installation
install_vscode() {
    log "Checking VS Code installation..."
    
    if is_app_installed "Visual Studio Code"; then
        log_success "VS Code already installed"
        return 0
    fi
    
    log "Installing VS Code..."
    brew install --cask visual-studio-code
    
    # Create 'code' command in PATH if not exists
    if ! command_exists code; then
        local shell_profile=""
        case "$SHELL" in
            */zsh) shell_profile="$HOME/.zshrc" ;;
            */bash) shell_profile="$HOME/.bash_profile" ;;
            *) shell_profile="$HOME/.profile" ;;
        esac
        
        if ! grep -q "Visual Studio Code" "$shell_profile" 2>/dev/null; then
            cat >> "$shell_profile" << 'EOF'

# VS Code command line
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
EOF
            log_success "VS Code command line tool configured"
        fi
    fi
    
    log_success "VS Code installed successfully"
}

# Main execution function
main() {
    log "Starting macOS development environment setup..."
    log "Log file: $LOG_FILE"
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
    
    # Check if running as root (not recommended for Homebrew)
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root is not recommended for Homebrew installations"
        log "Please run this script as a regular user, not with sudo"
        exit 1
    fi
    
    # Install Xcode Command Line Tools if not present
    if ! command_exists git; then
        log "Installing Xcode Command Line Tools..."
        xcode-select --install
        log "Please complete Xcode Command Line Tools installation and run this script again"
        exit 0
    fi
    
    install_iterm2
    install_homebrew
    install_git
    install_go
    install_python
    install_java
    install_rust
    install_nodejs
    install_singbox
    install_vscode
    
    log_success "All installations completed successfully!"
    log "Please restart your terminal or run 'source ~/.zshrc' (or your shell profile) to apply environment changes."
    
    # Display summary
    echo
    log "Installation Summary:"
    log "• iTerm2: $(is_app_installed "iTerm" && echo "✓ Installed" || echo "✗ Not installed")"
    log "• Homebrew: $(command_exists brew && echo "✓ Installed ($(brew --version | head -1))" || echo "✗ Not installed")"
    log "• Git: $(command_exists git && echo "✓ Installed ($(git --version | cut -d' ' -f3))" || echo "✗ Not installed")"
    log "• Go: $(command_exists go && echo "✓ Installed ($(go version | cut -d' ' -f3))" || echo "✗ Not installed")"
    log "• Python: $(command_exists python3 && echo "✓ Installed ($(python3 --version))" || echo "✗ Not installed")"
    log "• Java: $(command_exists java && echo "✓ Installed ($(java -version 2>&1 | head -1 | cut -d'"' -f2))" || echo "✗ Not installed")"
    log "• Rust: $(command_exists rustc && echo "✓ Installed ($(rustc --version | cut -d' ' -f2))" || echo "✗ Not installed")"
    log "• Node.js: $(command_exists node && echo "✓ Installed ($(node --version))" || echo "✗ Not installed")"
    log "• sing-box: $(command_exists sing-box && echo "✓ Installed" || echo "✗ Not installed")"
    log "• VS Code: $(is_app_installed "Visual Studio Code" && echo "✓ Installed" || echo "✗ Not installed")"
}

# Run main function
main "$@"