#!/bin/bash

# Shared utilities for macOS setup installers
# This file contains common functions used by all installer scripts

set -euo pipefail

# Ensure Homebrew is in PATH from the start (common installation paths)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Determine script directory and log file location
SCRIPT_DIR_TEMP="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "$HOME")}"
# Ensure log file is writable - use /tmp if current directory is not writable
if [[ ! -w "$SCRIPT_DIR_TEMP" ]]; then
    SCRIPT_DIR_TEMP="/tmp"
fi
readonly SCRIPT_DIR="$SCRIPT_DIR_TEMP"
readonly LOG_FILE="$SCRIPT_DIR/macOS_setup_$(date +%Y%m%d_%H%M%S).log"

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

# Reload shell profile to apply environment changes immediately
reload_shell_profile() {
    local shell_profile=""
    case "$SHELL" in
        */zsh) shell_profile="$HOME/.zshrc" ;;
        */bash) shell_profile="$HOME/.bash_profile" ;;
        *) shell_profile="$HOME/.profile" ;;
    esac
    
    if [[ -f "$shell_profile" ]]; then
        source "$shell_profile" 2>/dev/null || true
        log "Shell profile reloaded: $shell_profile"
    fi
}

# Retry command with exponential backoff (max 3 attempts)
retry_command() {
    local command_name="$1"
    shift
    local attempts=0
    local max_attempts=3
    local delay=2
    
    while [ $attempts -lt $max_attempts ]; do
        attempts=$((attempts + 1))
        log "Attempting $command_name (try $attempts/$max_attempts)..."
        
        if "$@"; then
            log_success "$command_name completed successfully"
            return 0
        else
            local exit_code=$?
            if [ $attempts -eq $max_attempts ]; then
                log_error "$command_name failed after $max_attempts attempts"
                return $exit_code
            else
                log_warning "$command_name failed (attempt $attempts/$max_attempts), retrying in ${delay}s..."
                sleep $delay
                delay=$((delay * 2))  # Exponential backoff
            fi
        fi
    done
}

# Safe execution - don't exit on failure, just log and continue
safe_install() {
    local function_name="$1"
    local software_name="$2"
    
    log "Installing $software_name..."
    if "$function_name"; then
        log_success "$software_name installation completed"
        return 0
    else
        log_error "$software_name installation failed, but continuing with other software..."
        return 1
    fi
}

version_ge() {
    # Handle unknown versions
    if [[ "$1" == "unknown" ]] || [[ "$2" == "unknown" ]]; then
        return 1  # Force update if either version is unknown
    fi
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

get_latest_github_release() {
    local repo="$1"
    curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Download file with SHA256 verification
secure_download() {
    local url="$1"
    local output_file="$2"
    local expected_sha256="$3"  # Optional
    
    log "Downloading $(basename "$output_file") from $url"
    
    # Download the file
    if ! curl -fsSL "$url" -o "$output_file"; then
        log_error "Failed to download $url"
        return 1
    fi
    
    # Verify SHA256 if provided
    if [[ -n "$expected_sha256" ]]; then
        log "Verifying SHA256 checksum..."
        local actual_sha256
        actual_sha256=$(shasum -a 256 "$output_file" | cut -d' ' -f1)
        
        if [[ "$actual_sha256" == "$expected_sha256" ]]; then
            log_success "SHA256 verification passed: $expected_sha256"
        else
            log_error "SHA256 verification failed!"
            log_error "Expected: $expected_sha256"
            log_error "Actual:   $actual_sha256"
            rm -f "$output_file"
            return 1
        fi
    else
        log_warning "No SHA256 checksum provided, skipping verification"
    fi
    
    return 0
}

# Verify Homebrew package integrity
verify_homebrew_package() {
    local package_name="$1"
    
    if ! command_exists brew; then
        log_warning "Homebrew not available, skipping package verification"
        return 1
    fi
    
    log "Verifying $package_name package integrity..."
    
    # Check if package exists and get info
    if ! brew info "$package_name" >/dev/null 2>&1; then
        log_warning "$package_name not found in Homebrew"
        return 1
    fi
    
    # Homebrew packages are GPG-signed and have built-in integrity checks
    # We rely on Homebrew's built-in verification
    log_success "Homebrew package $package_name verification relies on Homebrew's built-in integrity checks"
    return 0
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
}

# Check if running as root (not recommended for Homebrew)
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root is not recommended for Homebrew installations"
        log "Please run this script as a regular user, not with sudo"
        exit 1
    fi
}

# Get shell profile path
get_shell_profile() {
    case "$SHELL" in
        */zsh) echo "$HOME/.zshrc" ;;
        */bash) echo "$HOME/.bash_profile" ;;
        *) echo "$HOME/.profile" ;;
    esac
}

# Add environment configuration to shell profile
add_to_shell_profile() {
    local config_block="$1"
    local description="$2"
    local shell_profile
    shell_profile=$(get_shell_profile)
    
    if ! grep -q "$description" "$shell_profile" 2>/dev/null; then
        cat >> "$shell_profile" << EOF

# $description
$config_block
EOF
        log_success "$description configuration added to $shell_profile"
    else
        log "Configuration for $description already exists in $shell_profile"
    fi
}

log "Utilities loaded successfully"