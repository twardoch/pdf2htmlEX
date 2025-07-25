#!/usr/bin/env bash
# this_file: v2/scripts/test-build.sh

# Test script to validate the pdf2htmlEX build

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly DIST_DIR="${ROOT_DIR}/v2/dist"
readonly BUILD_LOG="${ROOT_DIR}/v2/build.log.txt"
readonly BUILD_ERR="${ROOT_DIR}/v2/build.err.txt"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }
log_info() { echo -e "${YELLOW}ℹ${NC} $*"; }

# Check if build completed
check_build_completion() {
    log_info "Checking build completion..."
    
    if [[ -f "${DIST_DIR}/bin/pdf2htmlEX" ]]; then
        log_success "pdf2htmlEX binary found at ${DIST_DIR}/bin/pdf2htmlEX"
        return 0
    else
        log_error "pdf2htmlEX binary not found"
        return 1
    fi
}

# Check for critical errors in build logs
check_build_errors() {
    log_info "Checking for critical errors in build logs..."
    
    local error_patterns=(
        "no such file or directory: 'ApplicationServices'"
        "undefined symbols"
        "architecture.*not recognized"
        "patch.*failed"
        "cmake.*error"
        "ninja.*error"
    )
    
    local found_errors=0
    for pattern in "${error_patterns[@]}"; do
        if grep -i "$pattern" "${BUILD_ERR}" 2>/dev/null | tail -5; then
            log_error "Found error pattern: $pattern"
            ((found_errors++))
        fi
    done
    
    if [[ $found_errors -eq 0 ]]; then
        log_success "No critical errors found in build logs"
        return 0
    else
        log_error "Found $found_errors error patterns"
        return 1
    fi
}

# Check architecture support
check_architecture() {
    log_info "Checking binary architecture..."
    
    if [[ -f "${DIST_DIR}/bin/pdf2htmlEX" ]]; then
        local archs=$(lipo -info "${DIST_DIR}/bin/pdf2htmlEX" 2>/dev/null | grep -o 'x86_64\|arm64' | sort | tr '\n' ' ')
        log_info "Architectures: $archs"
        
        if [[ "$archs" == *"x86_64"* ]] && [[ "$archs" == *"arm64"* ]]; then
            log_success "Universal binary (x86_64 + arm64) confirmed"
        elif [[ -n "$archs" ]]; then
            log_info "Single architecture binary: $archs"
        else
            log_error "Could not determine architecture"
        fi
    fi
}

# Check dynamic library dependencies
check_dependencies() {
    log_info "Checking dynamic library dependencies..."
    
    if [[ -f "${DIST_DIR}/bin/pdf2htmlEX" ]]; then
        log_info "Dynamic libraries linked:"
        otool -L "${DIST_DIR}/bin/pdf2htmlEX" | grep -v ":" | sed 's/^[[:space:]]*/  /'
        
        # Check for unwanted Homebrew dependencies
        if otool -L "${DIST_DIR}/bin/pdf2htmlEX" | grep -q "/usr/local\|/opt/homebrew"; then
            log_error "Found Homebrew dependencies (should be self-contained)"
        else
            log_success "No Homebrew dependencies found"
        fi
    fi
}

# Main test execution
main() {
    echo "PDF2HTMLEX BUILD TEST"
    echo "===================="
    echo ""
    
    local failures=0
    
    # Run tests
    check_build_completion || ((failures++))
    check_build_errors || ((failures++))
    check_architecture
    check_dependencies
    
    echo ""
    echo "===================="
    if [[ $failures -eq 0 ]]; then
        log_success "All tests passed!"
        
        # Show next steps
        echo ""
        echo "Next steps:"
        echo "1. Test PDF conversion: ${DIST_DIR}/bin/pdf2htmlEX test.pdf"
        echo "2. Check output quality"
        echo "3. Test on both Intel and Apple Silicon Macs"
    else
        log_error "$failures tests failed"
        echo ""
        echo "Debug tips:"
        echo "1. Check full error log: tail -100 ${BUILD_ERR}"
        echo "2. Check build output: tail -100 ${BUILD_LOG}"
        echo "3. Look for framework linking errors"
        echo "4. Verify all dependencies built successfully"
    fi
    
    return $failures
}

# Run main
main "$@"