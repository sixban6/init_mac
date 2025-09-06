#!/bin/bash

# Test script for macOS Development Environment Setup
# Validates all installations and configurations

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_LOG="$SCRIPT_DIR/test_results.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Logging functions
test_log() {
    echo -e "${BLUE}[TEST] $*${NC}" | tee -a "$TEST_LOG"
}

test_pass() {
    echo -e "${GREEN}[PASS] ✓ $*${NC}" | tee -a "$TEST_LOG"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}[FAIL] ✗ $*${NC}" | tee -a "$TEST_LOG"
    ((TESTS_FAILED++))
}

test_warning() {
    echo -e "${YELLOW}[WARN] ⚠ $*${NC}" | tee -a "$TEST_LOG"
}

# Test utilities
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TESTS_TOTAL++))
    test_log "Running: $test_name"
    
    if $test_function; then
        test_pass "$test_name"
    else
        test_fail "$test_name"
    fi
    echo
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_app_installed() {
    [ -d "/Applications/$1.app" ]
}

version_ge() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# Individual test functions
test_xcode_tools() {
    if command_exists git && command_exists make && command_exists gcc; then
        local git_version
        git_version=$(git --version)
        test_log "Xcode Command Line Tools detected: $git_version"
        return 0
    fi
    return 1
}

test_iterm2() {
    if is_app_installed "iTerm"; then
        test_log "iTerm2 found at /Applications/iTerm.app"
        
        # Check if it's set as default terminal (basic check)
        local default_handler
        default_handler=$(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null | grep -A3 -B3 "iterm2" || echo "")
        if [[ -n "$default_handler" ]]; then
            test_log "iTerm2 appears to be configured as default terminal"
        else
            test_warning "iTerm2 may not be set as default terminal"
        fi
        return 0
    fi
    return 1
}

test_homebrew() {
    if command_exists brew; then
        local brew_version
        brew_version=$(brew --version | head -1)
        test_log "Homebrew version: $brew_version"
        
        # Test if China mirrors are configured
        local bottle_domain="${HOMEBREW_BOTTLE_DOMAIN:-}"
        if [[ "$bottle_domain" == *"tuna.tsinghua.edu.cn"* ]]; then
            test_log "China mirror configured: $bottle_domain"
        else
            test_warning "China mirror may not be configured"
        fi
        
        # Test basic brew functionality
        if brew list >/dev/null 2>&1; then
            test_log "Homebrew is functional"
            return 0
        fi
    fi
    return 1
}

test_go() {
    if command_exists go; then
        local go_version
        go_version=$(go version)
        test_log "Go version: $go_version"
        
        # Test GOPATH configuration
        local gopath="${GOPATH:-}"
        if [[ -n "$gopath" && -d "$gopath" ]]; then
            test_log "GOPATH configured: $gopath"
        else
            test_warning "GOPATH may not be properly configured"
        fi
        
        # Test Go workspace structure
        if [[ -d "$HOME/go/src" && -d "$HOME/go/bin" && -d "$HOME/go/pkg" ]]; then
            test_log "Go workspace structure exists"
        else
            test_warning "Go workspace structure incomplete"
        fi
        
        # Test Go compilation
        local temp_dir
        temp_dir=$(mktemp -d)
        cat > "$temp_dir/hello.go" << 'EOF'
package main
import "fmt"
func main() {
    fmt.Println("Hello, Go!")
}
EOF
        
        if (cd "$temp_dir" && go run hello.go >/dev/null 2>&1); then
            test_log "Go compilation test passed"
            rm -rf "$temp_dir"
            return 0
        else
            rm -rf "$temp_dir"
            return 1
        fi
    fi
    return 1
}

test_python() {
    if command_exists python3; then
        local python_version
        python_version=$(python3 --version)
        test_log "Python version: $python_version"
        
        # Test pip3
        if command_exists pip3; then
            local pip_version
            pip_version=$(pip3 --version)
            test_log "pip version: $pip_version"
        else
            test_warning "pip3 not found"
        fi
        
        # Test Python functionality
        if python3 -c "print('Hello, Python!')" >/dev/null 2>&1; then
            test_log "Python execution test passed"
        else
            return 1
        fi
        
        # Test essential packages
        local missing_packages=()
        for package in setuptools wheel; do
            if ! python3 -c "import $package" >/dev/null 2>&1; then
                missing_packages+=("$package")
            fi
        done
        
        if [[ ${#missing_packages[@]} -eq 0 ]]; then
            test_log "Essential Python packages installed"
            return 0
        else
            test_warning "Missing packages: ${missing_packages[*]}"
            return 1
        fi
    fi
    return 1
}

test_vscode() {
    if is_app_installed "Visual Studio Code"; then
        test_log "VS Code found at /Applications/Visual Studio Code.app"
        
        # Test command line tool
        if command_exists code; then
            local code_version
            code_version=$(code --version | head -1)
            test_log "VS Code CLI version: $code_version"
            
            # Test basic functionality
            if code --help >/dev/null 2>&1; then
                test_log "VS Code CLI is functional"
                return 0
            fi
        else
            test_warning "VS Code command line tool not found"
            return 1
        fi
    fi
    return 1
}

test_java() {
    if command_exists java; then
        local java_version
        java_version=$(java -version 2>&1 | head -1)
        test_log "Java version: $java_version"
        
        # Test if it's Zulu JDK
        if java -version 2>&1 | grep -q -i "zulu"; then
            test_log "Zulu JDK detected"
        else
            test_warning "Java JDK may not be Zulu version"
        fi
        
        # Test JAVA_HOME configuration
        local java_home="${JAVA_HOME:-}"
        if [[ -n "$java_home" && -d "$java_home" ]]; then
            test_log "JAVA_HOME configured: $java_home"
        else
            test_warning "JAVA_HOME may not be properly configured"
        fi
        
        # Test javac compiler
        if command_exists javac; then
            local javac_version
            javac_version=$(javac -version 2>&1)
            test_log "Java compiler version: $javac_version"
        else
            return 1
        fi
        
        # Test Java compilation and execution
        local temp_dir
        temp_dir=$(mktemp -d)
        cat > "$temp_dir/HelloJava.java" << 'EOF'
public class HelloJava {
    public static void main(String[] args) {
        System.out.println("Hello, Java!");
    }
}
EOF
        
        local original_dir="$PWD"
        cd "$temp_dir"
        
        if javac HelloJava.java 2>/dev/null && java HelloJava 2>/dev/null | grep -q "Hello, Java!"; then
            test_log "Java compilation and execution test passed"
            cd "$original_dir"
            rm -rf "$temp_dir"
            return 0
        else
            cd "$original_dir"
            rm -rf "$temp_dir"
            return 1
        fi
    fi
    return 1
}

test_git() {
    if command_exists git; then
        local git_version
        git_version=$(git --version)
        test_log "Git version: $git_version"
        
        # Check if it's Homebrew Git (usually newer than system Git)
        local git_path
        git_path=$(which git)
        if [[ "$git_path" == "/usr/local/bin/git" ]] || [[ "$git_path" == *"homebrew"* ]]; then
            test_log "Using Homebrew Git: $git_path"
        else
            test_warning "May be using system Git: $git_path"
        fi
        
        # Test basic Git functionality
        if git --help >/dev/null 2>&1; then
            test_log "Git is functional"
            return 0
        fi
    fi
    return 1
}

test_rust() {
    if command_exists rustc; then
        local rust_version
        rust_version=$(rustc --version)
        test_log "Rust version: $rust_version"
        
        # Test Cargo
        if command_exists cargo; then
            local cargo_version
            cargo_version=$(cargo --version)
            test_log "Cargo version: $cargo_version"
        else
            test_warning "Cargo not found"
        fi
        
        # Test CARGO_HOME configuration
        local cargo_home="${CARGO_HOME:-$HOME/.cargo}"
        if [[ -d "$cargo_home" ]]; then
            test_log "CARGO_HOME configured: $cargo_home"
        else
            test_warning "CARGO_HOME directory not found"
        fi
        
        # Test Rust compilation
        local temp_dir
        temp_dir=$(mktemp -d)
        cat > "$temp_dir/hello.rs" << 'EOF'
fn main() {
    println!("Hello, Rust!");
}
EOF
        
        local original_dir="$PWD"
        cd "$temp_dir"
        
        if rustc hello.rs -o hello_rust 2>/dev/null && ./hello_rust 2>/dev/null | grep -q "Hello, Rust!"; then
            test_log "Rust compilation and execution test passed"
            cd "$original_dir"
            rm -rf "$temp_dir"
            return 0
        else
            cd "$original_dir"
            rm -rf "$temp_dir"
            return 1
        fi
    fi
    return 1
}

test_nodejs() {
    if command_exists node; then
        local node_version
        node_version=$(node --version)
        test_log "Node.js version: $node_version"
        
        # Test npm
        if command_exists npm; then
            local npm_version
            npm_version=$(npm --version)
            test_log "npm version: $npm_version"
            
            # Test npm global configuration
            local npm_prefix
            npm_prefix=$(npm config get prefix 2>/dev/null || echo "")
            if [[ "$npm_prefix" == *".npm-global"* ]]; then
                test_log "npm global directory configured: $npm_prefix"
            else
                test_warning "npm global directory may not be configured"
            fi
        else
            test_warning "npm not found"
        fi
        
        # Test Node.js execution
        local temp_dir
        temp_dir=$(mktemp -d)
        cat > "$temp_dir/hello.js" << 'EOF'
console.log("Hello, Node.js!");
EOF
        
        local original_dir="$PWD"
        cd "$temp_dir"
        
        if node hello.js 2>/dev/null | grep -q "Hello, Node.js!"; then
            test_log "Node.js execution test passed"
            cd "$original_dir"
            rm -rf "$temp_dir"
            return 0
        else
            cd "$original_dir"
            rm -rf "$temp_dir"
            return 1
        fi
    fi
    return 1
}

test_singbox() {
    if command_exists sing-box; then
        local singbox_version
        singbox_version=$(sing-box version 2>/dev/null | head -1 2>/dev/null || echo "unknown")
        if [[ "$singbox_version" != "unknown" ]]; then
            test_log "sing-box version: $singbox_version"
        else
            test_log "sing-box installed but version detection failed"
        fi
        
        # Test configuration directory
        local config_dir="$HOME/.config/sing-box"
        if [[ -d "$config_dir" ]]; then
            test_log "sing-box configuration directory exists: $config_dir"
            
            # Check for configuration file
            local config_file="$config_dir/config.json"
            if [[ -f "$config_file" ]]; then
                test_log "sing-box configuration file exists: $config_file"
                
                # Validate JSON configuration
                if command_exists jq && jq empty "$config_file" >/dev/null 2>&1; then
                    test_log "sing-box configuration file is valid JSON"
                elif python3 -m json.tool "$config_file" >/dev/null 2>&1; then
                    test_log "sing-box configuration file is valid JSON (verified with Python)"
                else
                    test_warning "sing-box configuration file may have JSON syntax errors"
                fi
            else
                test_warning "sing-box configuration file not found"
            fi
        else
            test_warning "sing-box configuration directory not found"
        fi
        
        # Test basic functionality (help command)
        if sing-box help >/dev/null 2>&1; then
            test_log "sing-box is functional"
            return 0
        else
            test_warning "sing-box may not be functioning correctly"
            return 1
        fi
    fi
    return 1
}

test_shell_profile() {
    local shell_profile=""
    case "$SHELL" in
        */zsh) shell_profile="$HOME/.zshrc" ;;
        */bash) shell_profile="$HOME/.bash_profile" ;;
        *) shell_profile="$HOME/.profile" ;;
    esac
    
    if [[ -f "$shell_profile" ]]; then
        test_log "Shell profile found: $shell_profile"
        
        # Check for expected configurations
        local configs_found=0
        if grep -q "HOMEBREW_BOTTLE_DOMAIN" "$shell_profile"; then
            test_log "Homebrew configuration found in profile"
            ((configs_found++))
        fi
        
        if grep -q "GOPATH" "$shell_profile"; then
            test_log "Go configuration found in profile"
            ((configs_found++))
        fi
        
        if grep -q "python3" "$shell_profile"; then
            test_log "Python configuration found in profile"
            ((configs_found++))
        fi
        
        if grep -q "Visual Studio Code" "$shell_profile"; then
            test_log "VS Code configuration found in profile"
            ((configs_found++))
        fi
        
        if grep -q "JAVA_HOME" "$shell_profile"; then
            test_log "Java configuration found in profile"
            ((configs_found++))
        fi
        
        if grep -q "CARGO_HOME" "$shell_profile"; then
            test_log "Rust configuration found in profile"
            ((configs_found++))
        fi
        
        if grep -q "npm-global" "$shell_profile"; then
            test_log "Node.js configuration found in profile"
            ((configs_found++))
        fi
        
        if [[ $configs_found -ge 3 ]]; then
            return 0
        else
            test_warning "Some configurations missing from shell profile"
            return 1
        fi
    else
        test_warning "Shell profile not found: $shell_profile"
        return 1
    fi
}

test_overall_integration() {
    test_log "Testing overall integration (read-only)..."
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Create a simple test project in temp directory (safe)
    mkdir -p "$temp_dir/test_project"
    local original_dir="$PWD"
    cd "$temp_dir/test_project"
    
    # Test Go project (temporary files only)
    cat > main.go << 'EOF'
package main
import "fmt"
func main() {
    fmt.Println("Integration test successful!")
}
EOF
    
    # Test Python script (temporary files only)
    cat > test.py << 'EOF'
#!/usr/bin/env python3
print("Python integration test successful!")
EOF
    
    local integration_passed=true
    
    # Test Go compilation and execution (in temp dir)
    if command_exists go && go build -o test_go main.go 2>/dev/null; then
        if ./test_go 2>/dev/null | grep -q "Integration test successful"; then
            test_log "Go integration test passed"
        else
            integration_passed=false
        fi
    else
        test_log "Go compilation test skipped (Go not available)"
        integration_passed=false
    fi
    
    # Test Python execution (in temp dir)
    if command_exists python3 && python3 test.py 2>/dev/null | grep -q "Python integration test successful"; then
        test_log "Python integration test passed"
    else
        integration_passed=false
    fi
    
    # Always return to original directory and clean up
    cd "$original_dir"
    rm -rf "$temp_dir"
    
    if $integration_passed; then
        test_log "Integration test passed: Go and Python working correctly"
        return 0
    else
        test_log "Integration test failed: Some tools may not be properly configured"
        return 1
    fi
}

# Performance test
test_performance() {
    test_log "Running performance tests (non-intrusive)..."
    
    local start_time end_time duration
    
    # Test brew performance (read-only command)
    if command_exists brew; then
        start_time=$(date +%s.%N 2>/dev/null || date +%s)
        brew list >/dev/null 2>&1
        end_time=$(date +%s.%N 2>/dev/null || date +%s)
        
        # Use basic arithmetic if bc not available
        if command_exists bc; then
            duration=$(echo "$end_time - $start_time" | bc -l)
            if (( $(echo "$duration < 5.0" | bc -l) )); then
                test_log "Homebrew performance test passed (${duration}s)"
            else
                test_warning "Homebrew performance slow (${duration}s)"
            fi
        else
            test_log "Homebrew performance test completed (bc not available for timing)"
        fi
    else
        test_log "Homebrew performance test skipped (brew not available)"
    fi
    
    # Test Go compilation performance (in temp dir only)
    if command_exists go; then
        local temp_dir
        temp_dir=$(mktemp -d)
        cat > "$temp_dir/perf.go" << 'EOF'
package main
import "fmt"
func main() {
    for i := 0; i < 100; i++ {
        fmt.Sprintf("test %d", i)
    }
}
EOF
        
        start_time=$(date +%s.%N 2>/dev/null || date +%s)
        (cd "$temp_dir" && go build -o perf_test perf.go) >/dev/null 2>&1
        local build_result=$?
        end_time=$(date +%s.%N 2>/dev/null || date +%s)
        
        # Clean up immediately
        rm -rf "$temp_dir"
        
        if [[ $build_result -eq 0 ]]; then
            if command_exists bc; then
                duration=$(echo "$end_time - $start_time" | bc -l)
                test_log "Go compilation performance test passed (${duration}s)"
            else
                test_log "Go compilation performance test passed"
            fi
            return 0
        else
            test_warning "Go compilation test failed"
            return 1
        fi
    else
        test_log "Go performance test skipped (go not available)"
        return 1
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}Starting macOS Development Environment Tests${NC}"
    echo -e "${BLUE}Test log: $TEST_LOG${NC}"
    echo > "$TEST_LOG"
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        test_fail "Not running on macOS"
        exit 1
    fi
    
    # Run all tests
    run_test "Xcode Command Line Tools" test_xcode_tools
    run_test "iTerm2 Installation" test_iterm2
    run_test "Homebrew Installation and Configuration" test_homebrew
    run_test "Git Installation and Configuration" test_git
    run_test "Go Installation and Configuration" test_go
    run_test "Python Installation and Configuration" test_python
    run_test "Java JDK Installation and Configuration" test_java
    run_test "Rust Installation and Configuration" test_rust
    run_test "Node.js Installation and Configuration" test_nodejs
    run_test "sing-box Installation and Configuration" test_singbox
    run_test "VS Code Installation" test_vscode
    run_test "Shell Profile Configuration" test_shell_profile
    run_test "Overall Integration" test_overall_integration
    run_test "Performance Tests" test_performance
    
    # Summary
    echo
    echo -e "${BLUE}=== Test Summary ===${NC}"
    echo -e "${BLUE}Total tests: $TESTS_TOTAL${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! Your development environment is ready.${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed. Please check the log and rerun setup if needed.${NC}"
        exit 1
    fi
}

# Handle script dependencies
if ! command_exists bc; then
    echo "Installing bc for performance tests..."
    if command_exists brew; then
        brew install bc
    else
        echo "Warning: bc not available, skipping performance tests"
    fi
fi

# Run main function
main "$@"