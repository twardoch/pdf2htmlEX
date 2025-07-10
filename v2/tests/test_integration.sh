#!/bin/bash
# this_file: v2/tests/test_integration.sh
#
# Integration tests for pdf2htmlEX v2 Homebrew formula
# Tests the complete build and installation process

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
    echo -e "${GREEN}[INTEGRATION] $*${NC}"
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
    
    # Optionally uninstall pdf2htmlex if test installed it
    if [[ "${UNINSTALL_AFTER:-no}" == "yes" ]]; then
        brew uninstall pdf2htmlex 2>/dev/null || true
    fi
}
trap cleanup EXIT

check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v brew &> /dev/null; then
        error "Homebrew is required for integration tests"
    fi
    
    if [[ ! -f "$FORMULA_PATH" ]]; then
        error "Formula not found at $FORMULA_PATH"
    fi
    
    # Check if pdf2htmlex is already installed
    if brew list pdf2htmlex &> /dev/null; then
        warn "pdf2htmlex is already installed"
        warn "Run 'brew uninstall pdf2htmlex' first, or set FORCE_REINSTALL=yes"
        
        if [[ "${FORCE_REINSTALL:-no}" != "yes" ]]; then
            error "Aborting to prevent conflicts"
        fi
        
        log "Force reinstall requested, uninstalling existing..."
        brew uninstall pdf2htmlex
    fi
    
    log "✓ Prerequisites check passed"
}

test_formula_syntax() {
    log "Testing formula syntax..."
    
    if brew audit --strict "$FORMULA_PATH"; then
        log "✓ Formula syntax is valid"
    else
        error "Formula syntax validation failed"
    fi
}

test_formula_installation() {
    log "Testing formula installation..."
    log "This will take several minutes as it builds all dependencies..."
    
    # Set flag to uninstall after test
    UNINSTALL_AFTER=yes
    
    # Try to install the formula
    if brew install --build-from-source --verbose "$FORMULA_PATH"; then
        log "✓ Formula installation succeeded"
    else
        error "Formula installation failed"
    fi
}

test_installed_binary() {
    log "Testing installed binary..."
    
    local binary="$(brew --prefix)/bin/pdf2htmlEX"
    
    if [[ ! -x "$binary" ]]; then
        error "Installed binary not found at $binary"
    fi
    
    # Test version
    if "$binary" --version; then
        log "✓ Binary version check passed"
    else
        error "Binary version check failed"
    fi
    
    # Test basic conversion
    local test_pdf="$TEMP_DIR/test.pdf"
    cat > "$test_pdf" << 'EOF'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>
endobj
4 0 obj
<< /Length 44 >>
stream
BT
/F1 12 Tf
100 700 Td
(Homebrew Test) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000207 00000 n 
trailer
<< /Size 5 /Root 1 0 R >>
startxref
301
%%EOF
EOF
    
    cd "$TEMP_DIR"
    if "$binary" test.pdf; then
        log "✓ Basic conversion test passed"
        
        if [[ -f test.html ]]; then
            log "✓ HTML output created"
        else
            error "HTML output not created"
        fi
    else
        error "Basic conversion test failed"
    fi
}

test_universal_binary() {
    log "Testing universal binary support..."
    
    local binary="$(brew --prefix)/bin/pdf2htmlEX"
    
    if [[ "$(uname)" == "Darwin" ]]; then
        local file_output
        file_output=$(file "$binary")
        
        if [[ "$file_output" =~ "universal binary" ]]; then
            log "✓ Binary is universal"
            
            # Check architectures
            local lipo_output
            lipo_output=$(lipo -info "$binary")
            
            if [[ "$lipo_output" =~ "x86_64" ]] && [[ "$lipo_output" =~ "arm64" ]]; then
                log "✓ Contains both x86_64 and arm64 architectures"
            else
                warn "Missing expected architectures: $lipo_output"
            fi
        else
            warn "Binary is not universal: $file_output"
        fi
    else
        warn "Universal binary test skipped (not on macOS)"
    fi
}

test_static_dependencies() {
    log "Testing static dependency linking..."
    
    local binary="$(brew --prefix)/bin/pdf2htmlEX"
    
    if command -v otool &> /dev/null; then
        local otool_output
        otool_output=$(otool -L "$binary")
        
        # Check that we don't dynamically link to poppler or fontforge
        if echo "$otool_output" | grep -q "libpoppler"; then
            error "Binary dynamically links to Poppler (should be static)"
        fi
        
        if echo "$otool_output" | grep -q "libfontforge"; then
            error "Binary dynamically links to FontForge (should be static)"
        fi
        
        log "✓ Poppler and FontForge are statically linked"
        
        # Count system library dependencies
        local dylib_count
        dylib_count=$(echo "$otool_output" | grep -c "\.dylib" || true)
        
        log "Binary has $dylib_count dynamic library dependencies"
        
        # Show only non-system dependencies
        echo "$otool_output" | grep -v "/usr/lib\|/System/" | grep "\.dylib" || true
    else
        warn "otool not available, skipping dependency test"
    fi
}

test_formula_test_block() {
    log "Running formula test block..."
    
    if brew test "$FORMULA_PATH"; then
        log "✓ Formula test block passed"
    else
        error "Formula test block failed"
    fi
}

test_performance() {
    log "Testing conversion performance..."
    
    local binary="$(brew --prefix)/bin/pdf2htmlEX"
    local test_pdf="$TEMP_DIR/perf_test.pdf"
    
    # Create a slightly larger test PDF
    cat > "$test_pdf" << 'EOF'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R 4 0 R 5 0 R] /Count 3 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 6 0 R >>
endobj
4 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 7 0 R >>
endobj
5 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 8 0 R >>
endobj
6 0 obj
<< /Length 60 >>
stream
BT
/F1 24 Tf
100 700 Td
(Performance Test Page 1) Tj
ET
endstream
endobj
7 0 obj
<< /Length 60 >>
stream
BT
/F1 24 Tf
100 700 Td
(Performance Test Page 2) Tj
ET
endstream
endobj
8 0 obj
<< /Length 60 >>
stream
BT
/F1 24 Tf
100 700 Td
(Performance Test Page 3) Tj
ET
endstream
endobj
xref
0 9
0000000000 65535 f 
0000000009 00000 n 
0000000052 00000 n 
0000000111 00000 n 
0000000199 00000 n 
0000000287 00000 n 
0000000375 00000 n 
0000000485 00000 n 
0000000595 00000 n 
trailer
<< /Size 9 /Root 1 0 R >>
startxref
705
%%EOF
EOF
    
    cd "$TEMP_DIR"
    
    # Time the conversion
    local start_time end_time elapsed
    start_time=$(date +%s)
    
    if "$binary" perf_test.pdf; then
        end_time=$(date +%s)
        elapsed=$((end_time - start_time))
        
        log "✓ Conversion completed in ${elapsed} seconds"
        
        if [[ $elapsed -gt 10 ]]; then
            warn "Conversion took longer than expected (${elapsed}s > 10s)"
        fi
    else
        error "Performance test conversion failed"
    fi
}

test_memory_usage() {
    log "Testing memory usage..."
    
    local binary="$(brew --prefix)/bin/pdf2htmlEX"
    
    # This is a basic check - in production you'd want more sophisticated monitoring
    if command -v /usr/bin/time &> /dev/null; then
        local test_pdf="$TEMP_DIR/mem_test.pdf"
        
        # Use the same test PDF
        cp "$TEMP_DIR/perf_test.pdf" "$test_pdf" 2>/dev/null || \
            echo "%PDF-1.4" > "$test_pdf"
        
        cd "$TEMP_DIR"
        
        # Run with time command to get memory stats (macOS version)
        local time_output
        if time_output=$(/usr/bin/time -l "$binary" mem_test.pdf 2>&1); then
            log "✓ Memory usage test completed"
            
            # Extract peak memory usage on macOS
            local peak_mem
            peak_mem=$(echo "$time_output" | grep "peak memory" | awk '{print $1}')
            
            if [[ -n "$peak_mem" ]]; then
                log "Peak memory usage: $peak_mem bytes"
            fi
        else
            warn "Memory usage test failed"
        fi
    else
        warn "time command not available, skipping memory test"
    fi
}

run_all_tests() {
    log "Running all integration tests..."
    
    check_prerequisites
    test_formula_syntax
    test_formula_installation
    test_installed_binary
    test_universal_binary
    test_static_dependencies
    test_formula_test_block
    test_performance
    test_memory_usage
    
    log "All integration tests completed successfully!"
}

main() {
    local test_suite="${1:-all}"
    
    case "$test_suite" in
        all)
            run_all_tests
            ;;
        syntax)
            check_prerequisites
            test_formula_syntax
            ;;
        install)
            check_prerequisites
            test_formula_installation
            test_installed_binary
            ;;
        binary)
            test_installed_binary
            test_universal_binary
            test_static_dependencies
            ;;
        performance)
            test_performance
            test_memory_usage
            ;;
        *)
            echo "Usage: $0 [all|syntax|install|binary|performance]"
            echo "  all         - Run all tests (default)"
            echo "  syntax      - Test formula syntax only"
            echo "  install     - Test installation process"
            echo "  binary      - Test installed binary"
            echo "  performance - Test performance and memory"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi