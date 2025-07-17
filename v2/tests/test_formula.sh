#!/bin/bash
# this_file: v2/tests/test_formula.sh
#
# Homebrew formula validation tests for pdf2htmlEX v2
# Tests formula syntax, dependencies, and Homebrew compliance

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly FORMULA_PATH="$PROJECT_ROOT/v2/Formula/pdf2htmlex.rb"
readonly TEMP_DIR="$(mktemp -d)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[FORMULA TEST] $*${NC}"
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
    log "Checking formula test prerequisites..."
    
    if [[ ! -f "$FORMULA_PATH" ]]; then
        error "Formula not found at $FORMULA_PATH"
    fi
    
    if ! command -v brew &> /dev/null; then
        error "Homebrew is required for formula tests"
    fi
    
    if ! command -v ruby &> /dev/null; then
        error "Ruby is required for formula validation"
    fi
    
    log "✓ Prerequisites check passed"
}

test_formula_syntax() {
    log "Testing formula syntax..."
    
    # Test Ruby syntax
    if ruby -c "$FORMULA_PATH" > /dev/null 2>&1; then
        log "✓ Formula Ruby syntax is valid"
    else
        error "Formula has Ruby syntax errors"
    fi
    
    # Test that it's a proper Formula class
    if grep -q "class.*< Formula" "$FORMULA_PATH"; then
        log "✓ Formula class structure is correct"
    else
        error "Formula doesn't have proper class structure"
    fi
}

test_formula_metadata() {
    log "Testing formula metadata..."
    
    # Check required metadata fields
    local required_fields=("desc" "homepage" "url" "sha256" "license")
    
    for field in "${required_fields[@]}"; do
        if grep -q "^[[:space:]]*$field" "$FORMULA_PATH"; then
            log "✓ Formula has $field field"
        else
            error "Formula missing required field: $field"
        fi
    done
    
    # Check URL validity format
    if grep -q "https://github.com/pdf2htmlEX/pdf2htmlEX" "$FORMULA_PATH"; then
        log "✓ Formula URL points to correct repository"
    else
        warn "Formula URL might not point to correct repository"
    fi
    
    # Check license format
    if grep -q "GPL-3.0" "$FORMULA_PATH"; then
        log "✓ Formula has correct license"
    else
        warn "Formula license might be incorrect"
    fi
}

test_formula_dependencies() {
    log "Testing formula dependencies..."
    
    # Check for build dependencies
    if grep -q "depends_on.*=> :build" "$FORMULA_PATH"; then
        log "✓ Formula has build dependencies"
    else
        warn "Formula might not have build dependencies"
    fi
    
    # Check for runtime dependencies
    if grep -q "depends_on.*cmake" "$FORMULA_PATH"; then
        log "✓ Formula depends on cmake"
    else
        warn "Formula might not depend on cmake"
    fi
    
    # Check for critical dependencies
    local critical_deps=("cairo" "fontconfig" "freetype" "pango")
    
    for dep in "${critical_deps[@]}"; do
        if grep -q "depends_on.*$dep" "$FORMULA_PATH"; then
            log "✓ Formula depends on $dep"
        else
            warn "Formula might not depend on $dep"
        fi
    done
    
    # Check for resource blocks
    if grep -q "resource.*do" "$FORMULA_PATH"; then
        log "✓ Formula has resource blocks"
    else
        warn "Formula might not have resource blocks"
    fi
}

test_formula_resources() {
    log "Testing formula resources..."
    
    # Check for required resources
    local required_resources=("poppler" "fontforge" "jpeg-turbo")
    
    for resource in "${required_resources[@]}"; do
        if grep -q "resource.*$resource" "$FORMULA_PATH"; then
            log "✓ Formula has $resource resource"
        else
            warn "Formula might not have $resource resource"
        fi
    done
    
    # Check that resources have URLs and checksums
    local resource_count=$(grep -c "resource.*do" "$FORMULA_PATH")
    local url_count=$(grep -c "url.*https://" "$FORMULA_PATH")
    local sha_count=$(grep -c "sha256" "$FORMULA_PATH")
    
    if [[ $resource_count -gt 0 ]]; then
        log "✓ Formula has $resource_count resource(s)"
        
        # Should have at least one URL per resource plus main formula URL
        if [[ $url_count -ge $((resource_count + 1)) ]]; then
            log "✓ Resources have URLs"
        else
            warn "Some resources might be missing URLs"
        fi
        
        # Should have at least one SHA per resource plus main formula SHA
        if [[ $sha_count -ge $((resource_count + 1)) ]]; then
            log "✓ Resources have checksums"
        else
            warn "Some resources might be missing checksums"
        fi
    fi
}

test_formula_install_method() {
    log "Testing formula install method..."
    
    # Check for install method
    if grep -q "def install" "$FORMULA_PATH"; then
        log "✓ Formula has install method"
    else
        error "Formula missing install method"
    fi
    
    # Check for staging prefix setup
    if grep -q "staging_prefix" "$FORMULA_PATH"; then
        log "✓ Formula uses staging prefix"
    else
        warn "Formula might not use staging prefix"
    fi
    
    # Check for universal binary support
    if grep -q "x86_64.*arm64\|archs.*=" "$FORMULA_PATH"; then
        log "✓ Formula supports universal binaries"
    else
        warn "Formula might not support universal binaries"
    fi
    
    # Check for CMake usage
    if grep -q "cmake.*-S\|system.*cmake" "$FORMULA_PATH"; then
        log "✓ Formula uses CMake"
    else
        warn "Formula might not use CMake"
    fi
}

test_formula_test_block() {
    log "Testing formula test block..."
    
    # Check for test block
    if grep -q "test do" "$FORMULA_PATH"; then
        log "✓ Formula has test block"
        
        # Check for basic functionality tests
        if grep -q "version\|--version" "$FORMULA_PATH"; then
            log "✓ Formula test checks version"
        else
            warn "Formula test might not check version"
        fi
    else
        warn "Formula might not have test block"
    fi
}

test_formula_audit() {
    log "Testing formula audit compliance..."
    
    # Run brew audit
    if brew audit --strict --online "$FORMULA_PATH" 2>/dev/null; then
        log "✓ Formula passes brew audit"
    else
        warn "Formula might have audit issues"
        
        # Get detailed audit results
        local audit_output
        audit_output=$(brew audit --strict --online "$FORMULA_PATH" 2>&1 || true)
        
        # Check for common issues
        if echo "$audit_output" | grep -q "line too long"; then
            warn "Formula has long lines"
        fi
        
        if echo "$audit_output" | grep -q "checksum"; then
            warn "Formula has checksum issues"
        fi
        
        if echo "$audit_output" | grep -q "style"; then
            warn "Formula has style issues"
        fi
    fi
}

test_formula_versioning() {
    log "Testing formula versioning..."
    
    # Check for version consistency
    local version_lines=$(grep -n "version\|0\.18\.8" "$FORMULA_PATH" | head -5)
    
    if [[ -n "$version_lines" ]]; then
        log "✓ Formula has version information"
        
        # Check that version is consistent
        if echo "$version_lines" | grep -q "0\.18\.8"; then
            log "✓ Formula version is 0.18.8"
        else
            warn "Formula version might be inconsistent"
        fi
    else
        warn "Formula version information not found"
    fi
}

test_formula_security() {
    log "Testing formula security considerations..."
    
    # Check for secure URLs (HTTPS)
    if grep -q "http://\|ftp://" "$FORMULA_PATH"; then
        warn "Formula might use insecure URLs"
    else
        log "✓ Formula uses secure URLs"
    fi
    
    # Check for hardcoded paths
    if grep -q "/usr/local\|/opt/homebrew" "$FORMULA_PATH"; then
        warn "Formula might have hardcoded paths"
    else
        log "✓ Formula doesn't have obvious hardcoded paths"
    fi
    
    # Check for shell injection risks
    if grep -q "system.*\${" "$FORMULA_PATH"; then
        warn "Formula might have shell injection risks"
    else
        log "✓ Formula doesn't have obvious shell injection risks"
    fi
}

test_formula_compatibility() {
    log "Testing formula compatibility..."
    
    # Check for macOS version requirements
    if grep -q "depends_on.*macos" "$FORMULA_PATH"; then
        log "✓ Formula specifies macOS requirements"
    else
        warn "Formula might not specify macOS requirements"
    fi
    
    # Check for architecture handling
    if grep -q "CMAKE_OSX_ARCHITECTURES\|lipo" "$FORMULA_PATH"; then
        log "✓ Formula handles multiple architectures"
    else
        warn "Formula might not handle multiple architectures"
    fi
    
    # Check for C++ standard
    if grep -q "cxx11\|cxx14\|cxx17" "$FORMULA_PATH"; then
        log "✓ Formula specifies C++ standard"
    else
        warn "Formula might not specify C++ standard"
    fi
}

test_formula_documentation() {
    log "Testing formula documentation..."
    
    # Check for comments
    local comment_lines=$(grep -c "^[[:space:]]*#" "$FORMULA_PATH" || true)
    
    if [[ $comment_lines -gt 5 ]]; then
        log "✓ Formula has documentation comments ($comment_lines lines)"
    else
        warn "Formula might need more documentation"
    fi
    
    # Check for descriptive text
    if grep -q "# V2 Strategy\|# Stage [0-9]" "$FORMULA_PATH"; then
        log "✓ Formula has strategy documentation"
    else
        warn "Formula might need strategy documentation"
    fi
}

test_formula_performance() {
    log "Testing formula performance considerations..."
    
    # Check for parallel build support
    if grep -q "ninja\|make.*-j" "$FORMULA_PATH"; then
        log "✓ Formula supports parallel builds"
    else
        warn "Formula might not support parallel builds"
    fi
    
    # Check for optimization flags
    if grep -q "CMAKE_BUILD_TYPE.*Release\|CXXFLAGS.*-O" "$FORMULA_PATH"; then
        log "✓ Formula uses optimization flags"
    else
        warn "Formula might not use optimization flags"
    fi
}

main() {
    log "Starting formula validation test suite..."
    
    check_prerequisites
    test_formula_syntax
    test_formula_metadata
    test_formula_dependencies
    test_formula_resources
    test_formula_install_method
    test_formula_test_block
    test_formula_audit
    test_formula_versioning
    test_formula_security
    test_formula_compatibility
    test_formula_documentation
    test_formula_performance
    
    log "Formula validation tests completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi