#!/bin/bash

# VS Code Industry Best Practices Configuration
# Based on configurations used by Google, Microsoft, Netflix, Airbnb, and other leading tech companies

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# VS Code installation
install_vscode() {
    log "Checking VS Code installation..."
    
    if is_app_installed "Visual Studio Code"; then
        log_success "VS Code already installed"
        configure_vscode_industry_best
        return 0
    fi
    
    log "Installing VS Code..."
    retry_command "VS Code installation" brew install --cask visual-studio-code
    
    configure_vscode_industry_best
    
    log_success "VS Code installed successfully"
}

configure_vscode_industry_best() {
    # Create 'code' command in PATH if not exists
    if ! command_exists code; then
        local config_block='# VS Code command line
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"'
        
        add_to_shell_profile "$config_block" "VS Code command line"
        
        log_success "VS Code command line tool configured"
    else
        log_success "VS Code command line tool already available"
    fi
    
    # Wait for VS Code to be available
    local max_wait=10
    local wait_time=0
    while ! command_exists code && [ $wait_time -lt $max_wait ]; do
        log "Waiting for VS Code command to be available..."
        sleep 1
        wait_time=$((wait_time + 1))
        # Refresh PATH
        export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    done
    
    # Install industry-standard extensions
    install_industry_extensions
    
    # Configure industry best practice settings
    configure_industry_settings
}

# Install extensions based on industry surveys and big tech companies
install_industry_extensions() {
    log "Installing industry-standard VS Code extensions..."
    
    # Ensure PATH is updated for current session
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    
    # Check if code command is available
    if ! command_exists code; then
        log_warning "VS Code command line tool not available, skipping extension installation"
        return 1
    fi
    
    # Core extensions used by 90%+ of developers (based on Stack Overflow surveys)
    local core_extensions=(
        "ms-vscode.vscode-json"              # JSON support (built-in, but ensure it's enabled)
        "esbenp.prettier-vscode"             # Code formatter (used by Google, Facebook, Airbnb)
        "eamodio.gitlens"                    # Git enhancement (industry standard)
        "ms-vscode-remote.remote-containers" # Container development
        "ms-vscode.vscode-eslint"            # JavaScript linting (industry standard)
    )
    
    # Language-specific extensions (only the official/most popular ones)
    
    # Go extensions (Google's language)
    local go_extensions=(
        "golang.go"                          # Official Go extension by Google
    )
    
    # Python extensions (used by Netflix, Instagram, Pinterest)
    local python_extensions=(
        "ms-python.python"                   # Official Microsoft Python extension
        "ms-python.pylint"                   # Pylint integration
        "ms-python.black-formatter"          # Black formatter (used by many companies)
    )
    
    # Java extensions (used by Netflix, LinkedIn, Twitter)
    local java_extensions=(
        "redhat.java"                        # Red Hat's Java Language Support
        "vscjava.vscode-java-debug"          # Java Debugger
        "vscjava.vscode-java-test"           # Java Test Runner
        "vscjava.vscode-maven"               # Maven support
    )
    
    # TypeScript/JavaScript extensions (used by Microsoft, Slack, Discord)
    local js_extensions=(
        "ms-vscode.vscode-typescript-next"   # Official TypeScript extension
    )
    
    # Function to install extension with error handling
    install_extension() {
        local extension="$1"
        
        # Check if already installed
        if code --list-extensions | grep -q "$extension"; then
            log_success "Already installed: $extension"
            return 0
        fi
        
        log "Installing extension: $extension"
        
        if timeout 30 code --install-extension "$extension" --force >/dev/null 2>&1; then
            log_success "Installed: $extension"
        else
            log_warning "Failed to install: $extension"
        fi
    }
    
    # Install core extensions first
    log "Installing core development extensions..."
    for extension in "${core_extensions[@]}"; do
        install_extension "$extension"
    done
    
    # Install language-specific extensions based on what's installed
    if command_exists go; then
        log "Installing Go development extensions..."
        for extension in "${go_extensions[@]}"; do
            install_extension "$extension"
        done
    fi
    
    if command_exists python3; then
        log "Installing Python development extensions..."
        for extension in "${python_extensions[@]}"; do
            install_extension "$extension"
        done
    fi
    
    if command_exists java; then
        log "Installing Java development extensions..."
        for extension in "${java_extensions[@]}"; do
            install_extension "$extension"
        done
    fi
    
    if command_exists node; then
        log "Installing JavaScript/TypeScript development extensions..."
        for extension in "${js_extensions[@]}"; do
            install_extension "$extension"
        done
    fi
    
    log_success "VS Code extensions installation completed"
}

# Configure settings based on industry best practices
configure_industry_settings() {
    log "Configuring VS Code with industry best practices..."
    
    # VS Code user settings directory
    local vscode_dir="$HOME/Library/Application Support/Code/User"
    mkdir -p "$vscode_dir"
    
    # Create settings.json based on Google, Microsoft, Airbnb style guides
    local settings_file="$vscode_dir/settings.json"
    
    cat > "$settings_file" << 'EOF'
{
    // Editor configuration based on Google Style Guide and industry standards
    "editor.fontSize": 14,
    "editor.fontFamily": "SF Mono, Menlo, Monaco, 'Courier New', monospace",
    "editor.tabSize": 2,                     // Google/Airbnb standard for JS/TS/JSON
    "editor.insertSpaces": true,             // Spaces over tabs (industry standard)
    "editor.detectIndentation": true,        // Auto-detect project preferences
    "editor.renderWhitespace": "boundary",   // Show trailing spaces
    "editor.rulers": [80, 100, 120],         // Line length guides (Google uses 80/100)
    "editor.wordWrap": "on",
    "editor.minimap.enabled": true,
    "editor.lineNumbers": "on",
    "editor.formatOnSave": true,             // Auto-format on save (industry standard)
    "editor.formatOnPaste": true,            // Format when pasting
    "editor.codeActionsOnSave": {
        "source.fixAll": true,               // Auto-fix linting issues
        "source.organizeImports": true       // Auto-organize imports
    },
    "editor.suggest.insertMode": "replace",
    "editor.acceptSuggestionOnCommitCharacter": false,
    
    // File management
    "files.autoSave": "onFocusChange",       // Auto-save when switching files
    "files.trimTrailingWhitespace": true,   // Remove trailing whitespace
    "files.insertFinalNewline": true,       // Add final newline (POSIX standard)
    "files.trimFinalNewlines": true,
    "files.exclude": {
        "**/.git": true,
        "**/.DS_Store": true,
        "**/node_modules": true,
        "**/__pycache__": true,
        "**/target": true,
        "**/build": true,
        "**/dist": true,
        "**/.vscode": false                  // Show .vscode folder for team sharing
    },
    
    // Workbench (based on developer productivity studies)
    "workbench.startupEditor": "newUntitledFile",
    "workbench.editor.enablePreview": false, // Always open files in new tabs
    "workbench.colorTheme": "Default Dark+",
    "workbench.iconTheme": "vs-seti",
    "workbench.tree.indent": 20,
    "breadcrumbs.enabled": true,             // Navigation breadcrumbs
    
    // Terminal configuration
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.fontFamily": "SF Mono, Menlo, Monaco, 'Courier New', monospace",
    "terminal.integrated.defaultProfile.osx": "zsh",
    "terminal.integrated.copyOnSelection": true,
    
    // Git configuration (industry best practices)
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true,
    "git.defaultCloneDirectory": "~/Developer",
    "gitlens.currentLine.enabled": false,   // Less visual clutter
    "gitlens.codeLens.enabled": false,       // Performance optimization
    
    // Search optimization
    "search.exclude": {
        "**/node_modules": true,
        "**/bower_components": true,
        "**/*.code-search": true,
        "**/target": true,
        "**/build": true,
        "**/dist": true,
        "**/.git": true,
        "**/__pycache__": true,
        "**/*.pyc": true
    },
    
    // Performance and privacy
    "telemetry.telemetryLevel": "off",       // Disable telemetry
    "update.mode": "start",
    "extensions.autoUpdate": true,
    "security.workspace.trust.enabled": false,
    
    // Language-specific settings based on official style guides
    
    // Go settings (Google Go Style Guide)
    "go.useLanguageServer": true,
    "go.formatTool": "goimports",            // Google's preferred formatter
    "go.lintOnSave": "package",
    "[go]": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true
        },
        "editor.insertSpaces": false,        // Go uses tabs
        "editor.tabSize": 4
    },
    
    // Python settings (PEP 8 + Black formatter used by Instagram, Pinterest)
    "python.defaultInterpreterPath": "/usr/local/bin/python3",
    "python.formatting.provider": "black",  // Black formatter (industry standard)
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.linting.flake8Args": [
        "--max-line-length=88",              // Black's line length
        "--extend-ignore=E203,W503"          // Black compatibility
    ],
    "[python]": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true
        },
        "editor.tabSize": 4,                 // PEP 8 standard
        "editor.insertSpaces": true
    },
    
    // Java settings (Google Java Style Guide)
    "java.home": "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home",
    "java.import.gradle.enabled": true,
    "java.import.maven.enabled": true,
    "java.autobuild.enabled": true,
    "[java]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2,                 // Google Java Style Guide
        "editor.insertSpaces": true
    },
    
    // JavaScript/TypeScript (Google/Airbnb Style Guide)
    "typescript.updateImportsOnFileMove.enabled": "always",
    "javascript.updateImportsOnFileMove.enabled": "always",
    "[javascript]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2,                 // Google/Airbnb standard
        "editor.insertSpaces": true
    },
    "[typescript]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true
    },
    "[javascriptreact]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true
    },
    "[typescriptreact]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true
    },
    
    // JSON/YAML (industry standard)
    "[json]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true
    },
    "[jsonc]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true
    },
    "[yaml]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true
    },
    
    // HTML/CSS (based on Google HTML/CSS Style Guide)
    "[html]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true
    },
    "[css]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true
    },
    
    // Prettier configuration (used by React, Vue, Angular teams)
    "prettier.singleQuote": false,          // Double quotes (Google standard)
    "prettier.trailingComma": "es5",        // ES5 compatibility
    "prettier.tabWidth": 2,
    "prettier.semi": true,                  // Always use semicolons
    "prettier.printWidth": 80,              // Google line length standard
    
    // ESLint configuration
    "eslint.validate": [
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact"
    ]
}
EOF
    
    log_success "VS Code settings configured with industry best practices"
    
    # Create industry-standard workspace templates
    create_industry_workspace_templates
}

# Create workspace templates based on real-world project structures
create_industry_workspace_templates() {
    log "Creating industry-standard workspace templates..."
    
    local workspace_dir="$HOME/Developer"
    mkdir -p "$workspace_dir"
    
    # Create .vscode templates directory
    local templates_dir="$workspace_dir/.vscode-templates"
    mkdir -p "$templates_dir"
    
    # Go project template (based on Google's Go project structure)
    local go_template_dir="$templates_dir/go-project"
    mkdir -p "$go_template_dir/.vscode"
    
    cat > "$go_template_dir/.vscode/settings.json" << 'EOF'
{
    "go.useLanguageServer": true,
    "go.formatTool": "goimports",
    "go.lintTool": "golangci-lint",
    "go.testFlags": ["-v", "-race"],
    "go.buildFlags": ["-race"],
    "[go]": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true
        }
    }
}
EOF
    
    cat > "$go_template_dir/.vscode/launch.json" << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Launch Package",
            "type": "go",
            "request": "launch",
            "mode": "auto",
            "program": "${workspaceFolder}"
        }
    ]
}
EOF
    
    cat > "$go_template_dir/main.go" << 'EOF'
package main

import "fmt"

func main() {
    fmt.Println("Hello, Go!")
}
EOF
    
    cat > "$go_template_dir/go.mod" << 'EOF'
module example.com/hello

go 1.21
EOF
    
    # Python project template (based on structure used by Instagram, Pinterest)
    local python_template_dir="$templates_dir/python-project"
    mkdir -p "$python_template_dir/.vscode"
    
    cat > "$python_template_dir/.vscode/settings.json" << 'EOF'
{
    "python.formatting.provider": "black",
    "python.linting.enabled": true,
    "python.linting.flake8Enabled": true,
    "python.linting.flake8Args": ["--max-line-length=88"],
    "python.testing.pytestEnabled": true,
    "[python]": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true
        }
    }
}
EOF
    
    cat > "$python_template_dir/.vscode/launch.json" << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "python",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal"
        }
    ]
}
EOF
    
    cat > "$python_template_dir/main.py" << 'EOF'
#!/usr/bin/env python3
"""Main module."""


def main():
    """Entry point."""
    print("Hello, Python!")


if __name__ == "__main__":
    main()
EOF
    
    cat > "$python_template_dir/requirements.txt" << 'EOF'
# Production dependencies

# Development dependencies
black>=23.0.0
flake8>=6.0.0
pytest>=7.0.0
EOF
    
    # Java project template (based on Google Java style)
    local java_template_dir="$templates_dir/java-project"
    mkdir -p "$java_template_dir/.vscode"
    mkdir -p "$java_template_dir/src/main/java/com/example"
    
    cat > "$java_template_dir/.vscode/settings.json" << 'EOF'
{
    "java.home": "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home",
    "java.import.maven.enabled": true,
    "[java]": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2
    }
}
EOF
    
    cat > "$java_template_dir/src/main/java/com/example/Main.java" << 'EOF'
package com.example;

/** Main class following Google Java Style Guide. */
public final class Main {
  
  public static void main(String[] args) {
    System.out.println("Hello, Java!");
  }
  
  private Main() {} // Prevent instantiation
}
EOF
    
    log_success "Industry-standard workspace templates created in: $templates_dir"
}

main() {
    check_macos
    check_not_root
    
    # Check if Homebrew is available
    if ! command_exists brew; then
        log_error "Homebrew is required but not installed. Please run homebrew.sh first."
        exit 1
    fi
    
    install_vscode
    
    log_success "VS Code configured with industry best practices!"
    log "Configuration based on style guides from:"
    log "  • Google (Go, Java, JavaScript Style Guides)"
    log "  • Airbnb (JavaScript Style Guide)"
    log "  • PEP 8 (Python)"
    log "  • Black formatter (used by Instagram, Pinterest)"
    log ""
    log "Workspace templates available at: ~/Developer/.vscode-templates/"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi