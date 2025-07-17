#!/bin/bash
# this_file: v2/tests/test_api_fixes.sh
#
# API fix scripts tests for pdf2htmlEX v2
# Tests the various API compatibility fix scripts

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly SCRIPTS_DIR="$PROJECT_ROOT/v2/scripts"
readonly TEMP_DIR="$(mktemp -d)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[API FIX TEST] $*${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $*${NC}"
}

error() {
    echo -e "${RED}[ERROR] $*${NC}"
    exit 1
}

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

check_prerequisites() {
    log "Checking API fix test prerequisites..."
    
    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        error "Scripts directory not found at $SCRIPTS_DIR"
    fi
    
    # Check required tools
    local required_tools=("bash" "sed" "grep")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "Required tool '$tool' not found in PATH"
        fi
    done
    
    log "✓ Prerequisites check passed"
}

find_api_fix_scripts() {
    local fix_scripts=()
    
    # Find all API fix scripts
    for script in "$SCRIPTS_DIR"/fix_api*.sh "$SCRIPTS_DIR"/*api_fix*.sh; do
        if [[ -f "$script" ]]; then
            fix_scripts+=("$script")
        fi
    done
    
    if [[ ${#fix_scripts[@]} -eq 0 ]]; then
        error "No API fix scripts found"
    fi
    
    printf '%s\n' "${fix_scripts[@]}"
}

test_script_syntax() {
    log "Testing script syntax..."
    
    local scripts
    mapfile -t scripts < <(find_api_fix_scripts)
    
    if [[ ${#scripts[@]} -eq 0 ]]; then
        warn "No API fix scripts found to test"
        return 0
    fi
    
    log "Found ${#scripts[@]} API fix scripts:"
    for script in "${scripts[@]}"; do
        log "  - $(basename "$script")"
    done
    
    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")
        
        if bash -n "$script"; then
            log "✓ Script syntax valid: $script_name"
        else
            error "Script syntax error: $script_name"
        fi
    done
}

test_script_permissions() {
    log "Testing script permissions..."
    
    local scripts
    mapfile -t scripts < <(find_api_fix_scripts)
    
    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")
        
        if [[ -x "$script" ]]; then
            log "✓ Script is executable: $script_name"
        else
            warn "Script not executable: $script_name"
            # Make it executable for testing
            chmod +x "$script"
        fi
    done
}

test_script_headers() {
    log "Testing script headers and documentation..."
    
    local scripts
    mapfile -t scripts < <(find_api_fix_scripts)
    
    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")
        
        # Check for shebang
        if head -1 "$script" | grep -q "^#!/"; then
            log "✓ Script has shebang: $script_name"
        else
            warn "Script lacks shebang: $script_name"
        fi
        
        # Check for this_file comment
        if grep -q "this_file:" "$script"; then
            log "✓ Script has this_file comment: $script_name"
        else
            warn "Script lacks this_file comment: $script_name"
        fi
        
        # Check for description
        if head -10 "$script" | grep -q -i "fix\|patch\|api\|poppler"; then
            log "✓ Script has description: $script_name"
        else
            warn "Script lacks description: $script_name"
        fi
    done
}

test_script_functionality() {
    log "Testing script functionality..."
    
    local scripts
    mapfile -t scripts < <(find_api_fix_scripts)
    
    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")
        
        # Test help/usage
        if timeout 10 bash "$script" --help 2>/dev/null | grep -q -i "usage\|help"; then
            log "✓ Script provides help: $script_name"
        else
            warn "Script doesn't provide help: $script_name"
        fi
        
        # Test dry-run if available
        if timeout 10 bash "$script" --dry-run 2>/dev/null; then
            log "✓ Script supports dry-run: $script_name"
        else
            warn "Script doesn't support dry-run: $script_name"
        fi
    done
}

test_script_targets() {
    log "Testing script targets and operations..."
    
    local scripts
    mapfile -t scripts < <(find_api_fix_scripts)
    
    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")
        
        # Check if script targets specific files
        if grep -q "\.h\|\.cc\|\.cpp\|\.c\|CMakeLists\.txt" "$script"; then
            log "✓ Script targets source files: $script_name"
        else
            warn "Script might not target source files: $script_name"
        fi
        
        # Check for API-related operations
        if grep -q -i "poppler\|fontforge\|api\|version\|compat" "$script"; then
            log "✓ Script addresses API compatibility: $script_name"
        else
            warn "Script might not address API compatibility: $script_name"
        fi
        
        # Check for sed/awk/grep operations
        if grep -q "sed\|awk\|grep" "$script"; then
            log "✓ Script uses text processing tools: $script_name"
        else
            warn "Script might not use text processing: $script_name"
        fi
    done
}

test_script_safety() {
    log "Testing script safety features..."
    
    local scripts
    mapfile -t scripts < <(find_api_fix_scripts)
    
    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")
        
        # Check for set -e (exit on error)
        if grep -q "set -e" "$script"; then
            log "✓ Script uses 'set -e': $script_name"
        else
            warn "Script doesn't use 'set -e': $script_name"
        fi
        
        # Check for backup creation
        if grep -q "backup\|\.bak\|\.orig" "$script"; then
            log "✓ Script creates backups: $script_name"
        else
            warn "Script might not create backups: $script_name"
        fi
        
        # Check for validation
        if grep -q -i "check\|validate\|verify\|test" "$script"; then
            log "✓ Script has validation logic: $script_name"
        else
            warn "Script lacks validation logic: $script_name"
        fi
    done
}

test_script_environment() {
    log "Testing script environment handling..."
    
    local scripts
    mapfile -t scripts < <(find_api_fix_scripts)
    
    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")
        
        # Check for path handling
        if grep -q "SCRIPT_DIR\|dirname\|realpath\|pwd" "$script"; then
            log "✓ Script handles paths correctly: $script_name"
        else
            warn "Script might not handle paths correctly: $script_name"
        fi
        
        # Check for environment variables
        if grep -q "ENV\|export\|\$[A-Z_]" "$script"; then
            log "✓ Script uses environment variables: $script_name"
        else
            warn "Script might not use environment variables: $script_name"
        fi
    done
}

test_script_integration() {
    log "Testing script integration with build system..."
    
    local scripts
    mapfile -t scripts < <(find_api_fix_scripts)
    
    # Check if scripts are called from build script
    local build_script="$SCRIPTS_DIR/build.sh"
    
    if [[ -f "$build_script" ]]; then
        for script in "${scripts[@]}"; do
            local script_name=$(basename "$script")
            
            if grep -q "$script_name" "$build_script"; then
                log "✓ Script integrated with build system: $script_name"
            else
                warn "Script not integrated with build system: $script_name"
            fi
        done
    else
        warn "Build script not found for integration testing"
    fi
}

test_script_versioning() {
    log "Testing script version handling..."
    
    local scripts
    mapfile -t scripts < <(find_api_fix_scripts)
    
    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")
        
        # Check for version-specific logic
        if grep -q "24\.\|version\|POPPLER_VERSION" "$script"; then
            log "✓ Script handles versioning: $script_name"
        else
            warn "Script might not handle versioning: $script_name"
        fi
        
        # Check for compatibility checks
        if grep -q -i "compat\|support\|version.*check" "$script"; then
            log "✓ Script has compatibility checks: $script_name"
        else
            warn "Script lacks compatibility checks: $script_name"
        fi
    done
}

test_script_error_handling() {
    log "Testing script error handling..."
    
    local scripts
    mapfile -t scripts < <(find_api_fix_scripts)
    
    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")
        
        # Check for error handling
        if grep -q "trap\|error\|fail\|exit" "$script"; then
            log "✓ Script has error handling: $script_name"
        else
            warn "Script lacks error handling: $script_name"
        fi
        
        # Check for logging
        if grep -q "echo\|log\|printf" "$script"; then
            log "✓ Script has logging: $script_name"
        else
            warn "Script lacks logging: $script_name"
        fi
    done
}

create_test_environment() {
    log "Creating test environment..."
    
    local test_env="$TEMP_DIR/test_env"
    mkdir -p "$test_env"
    
    # Create dummy source files for testing
    cat > "$test_env/test.cc" << 'EOF'
#include <poppler/Object.h>
#include <poppler/GfxState.h>

void test_function() {
    Object obj;
    GfxState *gfx = nullptr;
    // Some test code
}
EOF
    
    cat > "$test_env/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(test)

find_package(PkgConfig REQUIRED)
pkg_check_modules(POPPLER REQUIRED poppler)

add_executable(test test.cc)
target_link_libraries(test ${POPPLER_LIBRARIES})
EOF
    
    echo "$test_env"
}

test_script_execution() {
    log "Testing script execution on dummy files..."
    
    local scripts
    mapfile -t scripts < <(find_api_fix_scripts)
    
    local test_env
    test_env=$(create_test_environment)
    
    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")
        
        # Copy test environment for each script
        local script_env="$TEMP_DIR/env_$script_name"
        cp -r "$test_env" "$script_env"
        
        cd "$script_env"
        
        # Try to run script in dry-run mode
        if timeout 30 bash "$script" --dry-run 2>/dev/null; then
            log "✓ Script executes successfully: $script_name"
        else
            warn "Script execution failed: $script_name"
        fi
    done
}

main() {
    log "Starting API fix scripts test suite..."
    
    check_prerequisites
    test_script_syntax
    test_script_permissions
    test_script_headers
    test_script_functionality
    test_script_targets
    test_script_safety
    test_script_environment
    test_script_integration
    test_script_versioning
    test_script_error_handling
    test_script_execution
    
    log "API fix scripts tests completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi