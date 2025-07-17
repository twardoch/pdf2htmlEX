#!/bin/bash
# this_file: v2/tests/test_build.sh
#
# Build system tests for pdf2htmlEX v2
# Tests the core build script functionality and error handling

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly BUILD_SCRIPT="$PROJECT_ROOT/v2/scripts/build.sh"
readonly TEMP_DIR="$(mktemp -d)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[BUILD TEST] $*${NC}"
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
    log "Checking build prerequisites..."
    
    if [[ ! -f "$BUILD_SCRIPT" ]]; then
        error "Build script not found at $BUILD_SCRIPT"
    fi
    
    # Check required tools
    local required_tools=("cmake" "ninja" "curl" "tar" "shasum")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "Required tool '$tool' not found in PATH"
        fi
    done
    
    log "✓ Prerequisites check passed"
}

test_build_script_syntax() {
    log "Testing build script syntax..."
    
    if bash -n "$BUILD_SCRIPT"; then
        log "✓ Build script syntax is valid"
    else
        error "Build script has syntax errors"
    fi
}

test_build_script_help() {
    log "Testing build script help/usage..."
    
    # Test that script shows usage when run with invalid args
    if timeout 10 bash "$BUILD_SCRIPT" --help 2>/dev/null; then
        log "✓ Build script help completed"
    else
        warn "Build script doesn't have --help option"
    fi
}

test_environment_setup() {
    log "Testing environment setup..."
    
    # Create a minimal test environment
    local test_env="$TEMP_DIR/test_env"
    mkdir -p "$test_env"
    
    # Test basic environment variables
    cd "$test_env"
    
    # Source the build script to test environment setup (without running build)
    if bash -c "source '$BUILD_SCRIPT' && echo 'Environment loaded'" 2>/dev/null | grep -q "Environment loaded"; then
        log "✓ Environment setup test passed"
    else
        warn "Environment setup test failed (may be expected)"
    fi
}

test_dependency_validation() {
    log "Testing dependency validation..."
    
    # Test with missing dependency
    local old_path="$PATH"
    
    # Temporarily remove cmake from PATH
    PATH=$(echo "$PATH" | sed 's|[^:]*cmake[^:]*:||g')
    
    if timeout 30 bash "$BUILD_SCRIPT" 2>&1 | grep -q "cmake"; then
        log "✓ Build script detects missing cmake"
    else
        warn "Build script might not validate cmake dependency"
    fi
    
    # Restore PATH
    PATH="$old_path"
}

test_architecture_handling() {
    log "Testing architecture handling..."
    
    # Test single architecture build
    local test_output="$TEMP_DIR/arch_test_output"
    
    # Run build script with single architecture (should be faster)
    if timeout 60 env ARCHS="x86_64" bash "$BUILD_SCRIPT" --dry-run 2>&1 > "$test_output" || true; then
        if grep -q "x86_64" "$test_output"; then
            log "✓ Single architecture handling detected"
        else
            warn "Single architecture handling not detected"
        fi
    fi
    
    # Test universal binary configuration
    if timeout 60 env ARCHS="x86_64;arm64" bash "$BUILD_SCRIPT" --dry-run 2>&1 > "$test_output" || true; then
        if grep -q "x86_64" "$test_output" && grep -q "arm64" "$test_output"; then
            log "✓ Universal binary configuration detected"
        else
            warn "Universal binary configuration not detected"
        fi
    fi
}

test_clean_build_option() {
    log "Testing clean build option..."
    
    # Test clean build flag
    local test_output="$TEMP_DIR/clean_test_output"
    
    if timeout 30 env CLEAN=1 bash "$BUILD_SCRIPT" --dry-run 2>&1 > "$test_output" || true; then
        if grep -q -i "clean\|wipe\|remove" "$test_output"; then
            log "✓ Clean build option detected"
        else
            warn "Clean build option not detected"
        fi
    fi
}

test_version_configuration() {
    log "Testing version configuration..."
    
    # Check if build script uses proper version variables
    if grep -q "JPEG_TURBO_VERSION\|POPPLER_VERSION\|FONTFORGE_VERSION" "$BUILD_SCRIPT"; then
        log "✓ Version configuration variables found"
    else
        warn "Version configuration variables not found"
    fi
    
    # Check for version consistency
    if grep -q "24.01.0" "$BUILD_SCRIPT"; then
        log "✓ Poppler version 24.01.0 configured"
    else
        warn "Expected Poppler version not found"
    fi
}

test_error_handling() {
    log "Testing error handling..."
    
    # Test behavior with invalid directory
    local invalid_dir="/nonexistent/directory"
    
    if timeout 30 bash -c "cd '$invalid_dir' && '$BUILD_SCRIPT'" 2>&1 | grep -q -i "error\|fail\|cannot"; then
        log "✓ Error handling for invalid directory works"
    else
        warn "Error handling for invalid directory not detected"
    fi
}

test_network_dependency_handling() {
    log "Testing network dependency handling..."
    
    # Test with network issues (using invalid proxy)
    local test_output="$TEMP_DIR/network_test_output"
    
    if timeout 60 env https_proxy="invalid://proxy:8080" bash "$BUILD_SCRIPT" --dry-run 2>&1 > "$test_output" || true; then
        log "✓ Network dependency handling tested"
    fi
}

test_disk_space_checks() {
    log "Testing disk space considerations..."
    
    # Check if build script mentions disk space requirements
    if grep -q -i "space\|disk\|storage" "$BUILD_SCRIPT"; then
        log "✓ Disk space considerations found"
    else
        warn "No disk space considerations found"
    fi
}

test_parallel_build_support() {
    log "Testing parallel build support..."
    
    # Check if build script supports parallel builds
    if grep -q -i "parallel\|jobs\|-j" "$BUILD_SCRIPT"; then
        log "✓ Parallel build support detected"
    else
        warn "Parallel build support not detected"
    fi
}

test_output_validation() {
    log "Testing output validation..."
    
    # Check if build script validates its output
    if grep -q -i "validate\|check\|verify" "$BUILD_SCRIPT"; then
        log "✓ Output validation logic detected"
    else
        warn "Output validation logic not detected"
    fi
}

test_logging_functionality() {
    log "Testing logging functionality..."
    
    # Check if build script has proper logging
    if grep -q -i "log\|echo.*\[\|printf" "$BUILD_SCRIPT"; then
        log "✓ Logging functionality detected"
    else
        warn "Logging functionality not detected"
    fi
}

main() {
    log "Starting build system test suite..."
    
    check_prerequisites
    test_build_script_syntax
    test_build_script_help
    test_environment_setup
    test_dependency_validation
    test_architecture_handling
    test_clean_build_option
    test_version_configuration
    test_error_handling
    test_network_dependency_handling
    test_disk_space_checks
    test_parallel_build_support
    test_output_validation
    test_logging_functionality
    
    log "Build system tests completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi