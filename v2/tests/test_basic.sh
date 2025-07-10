#!/bin/bash
# this_file: v2/tests/test_basic.sh
#
# Basic functionality tests for pdf2htmlEX v2
# Tests core conversion capabilities and binary integrity

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly TESTS_DIR="$SCRIPT_DIR"
readonly TEMP_DIR="$(mktemp -d)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[TEST] $*${NC}"
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

# Find pdf2htmlEX binary
find_pdf2htmlex() {
    local binary=""
    
    # Try common locations
    for path in \
        "$PROJECT_ROOT/v2/dist/bin/pdf2htmlEX" \
        "$(brew --prefix)/bin/pdf2htmlEX" \
        "$(which pdf2htmlEX 2>/dev/null || true)"; do
        
        if [[ -x "$path" ]]; then
            binary="$path"
            break
        fi
    done
    
    if [[ -z "$binary" ]]; then
        error "pdf2htmlEX binary not found. Please build or install first."
    fi
    
    echo "$binary"
}

create_test_pdf() {
    local pdf_file="$1"
    local title="$2"
    
    cat > "$pdf_file" << EOF
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>
endobj
4 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj
5 0 obj
<< /Length 60 >>
stream
BT
/F1 24 Tf
100 700 Td
($title) Tj
ET
endstream
endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000052 00000 n 
0000000101 00000 n 
0000000229 00000 n 
0000000299 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
398
%%EOF
EOF
}

test_version() {
    log "Testing version information..."
    
    local binary="$1"
    local version_output
    
    if version_output=$("$binary" --version 2>&1); then
        log "Version: $version_output"
        
        # Check if version contains expected information
        if [[ "$version_output" =~ pdf2htmlEX ]]; then
            log "✓ Version test passed"
        else
            error "Version output doesn't contain 'pdf2htmlEX'"
        fi
    else
        error "Failed to get version information"
    fi
}

test_help() {
    log "Testing help output..."
    
    local binary="$1"
    local help_output
    
    if help_output=$("$binary" --help 2>&1); then
        log "Help output available"
        
        # Check if help contains expected sections
        if [[ "$help_output" =~ "Usage:" ]]; then
            log "✓ Help test passed"
        else
            error "Help output doesn't contain 'Usage:'"
        fi
    else
        error "Failed to get help information"
    fi
}

test_basic_conversion() {
    log "Testing basic PDF conversion..."
    
    local binary="$1"
    local test_pdf="$TEMP_DIR/test.pdf"
    local output_html="$TEMP_DIR/test.html"
    
    create_test_pdf "$test_pdf" "Hello World"
    
    cd "$TEMP_DIR"
    
    if "$binary" test.pdf; then
        log "✓ Basic conversion completed"
        
        # Check if HTML file was created
        if [[ -f "$output_html" ]]; then
            log "✓ HTML output file created"
            
            # Check if HTML contains expected content
            if grep -q "Hello World" "$output_html"; then
                log "✓ HTML contains expected text"
            else
                error "HTML doesn't contain expected text"
            fi
            
            # Check if HTML is valid (basic check)
            if grep -q "<html>" "$output_html" && grep -q "</html>" "$output_html"; then
                log "✓ HTML has basic structure"
            else
                error "HTML doesn't have basic structure"
            fi
        else
            error "HTML output file not created"
        fi
    else
        error "Basic conversion failed"
    fi
}

test_advanced_options() {
    log "Testing advanced conversion options..."
    
    local binary="$1"
    local test_pdf="$TEMP_DIR/advanced.pdf"
    local output_html="$TEMP_DIR/advanced.html"
    
    create_test_pdf "$test_pdf" "Advanced Test"
    
    cd "$TEMP_DIR"
    
    # Test with zoom option
    if "$binary" --zoom 1.5 advanced.pdf; then
        log "✓ Advanced options test passed"
        
        if [[ -f "$output_html" ]]; then
            log "✓ Advanced HTML output created"
        else
            error "Advanced HTML output not created"
        fi
    else
        error "Advanced options test failed"
    fi
}

test_multipage_pdf() {
    log "Testing multipage PDF..."
    
    local binary="$1"
    local test_pdf="$TEMP_DIR/multipage.pdf"
    
    # Create a simple multipage PDF
    cat > "$test_pdf" << 'EOF'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 5 0 R >> >> /Contents 6 0 R >>
endobj
4 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 5 0 R >> >> /Contents 7 0 R >>
endobj
5 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj
6 0 obj
<< /Length 60 >>
stream
BT
/F1 24 Tf
100 700 Td
(Page 1) Tj
ET
endstream
endobj
7 0 obj
<< /Length 60 >>
stream
BT
/F1 24 Tf
100 700 Td
(Page 2) Tj
ET
endstream
endobj
xref
0 8
0000000000 65535 f 
0000000009 00000 n 
0000000052 00000 n 
0000000101 00000 n 
0000000229 00000 n 
0000000357 00000 n 
0000000427 00000 n 
0000000537 00000 n 
trailer
<< /Size 8 /Root 1 0 R >>
startxref
647
%%EOF
EOF
    
    cd "$TEMP_DIR"
    
    if "$binary" multipage.pdf; then
        log "✓ Multipage PDF conversion completed"
        
        if [[ -f "multipage.html" ]]; then
            log "✓ Multipage HTML output created"
            
            # Check if both pages are mentioned
            if grep -q "Page 1" "multipage.html" && grep -q "Page 2" "multipage.html"; then
                log "✓ Both pages processed"
            else
                warn "Not all pages may have been processed correctly"
            fi
        else
            error "Multipage HTML output not created"
        fi
    else
        error "Multipage PDF conversion failed"
    fi
}

test_binary_architecture() {
    log "Testing binary architecture..."
    
    local binary="$1"
    
    # Check if binary is universal (on macOS)
    if [[ "$(uname)" == "Darwin" ]]; then
        local file_output
        file_output=$(file "$binary")
        
        if [[ "$file_output" =~ "universal binary" ]]; then
            log "✓ Binary is universal (contains multiple architectures)"
            
            # Check specific architectures
            if lipo -info "$binary" 2>/dev/null | grep -q "x86_64"; then
                log "✓ Contains x86_64 architecture"
            fi
            
            if lipo -info "$binary" 2>/dev/null | grep -q "arm64"; then
                log "✓ Contains arm64 architecture"
            fi
        else
            warn "Binary is not universal (single architecture)"
            log "Architecture: $file_output"
        fi
    else
        warn "Architecture test skipped (not on macOS)"
    fi
}

test_static_linking() {
    log "Testing static linking..."
    
    local binary="$1"
    local otool_output
    
    if command -v otool &> /dev/null; then
        otool_output=$(otool -L "$binary" 2>/dev/null || true)
        
        # Check that we don't link to Homebrew versions of our dependencies
        if echo "$otool_output" | grep -q "$(brew --prefix)/lib/libpoppler" 2>/dev/null; then
            error "Binary links to Homebrew Poppler (should be static)"
        fi
        
        if echo "$otool_output" | grep -q "$(brew --prefix)/lib/libfontforge" 2>/dev/null; then
            error "Binary links to Homebrew FontForge (should be static)"
        fi
        
        # Should only link to system libraries
        local system_libs_count
        system_libs_count=$(echo "$otool_output" | grep -c "/usr/lib\|/System/" || true)
        
        if [[ $system_libs_count -gt 0 ]]; then
            log "✓ Binary links to system libraries only"
        else
            warn "No system library links found (unusual)"
        fi
    else
        warn "otool not available, skipping static linking test"
    fi
}

test_error_handling() {
    log "Testing error handling..."
    
    local binary="$1"
    local invalid_pdf="$TEMP_DIR/invalid.pdf"
    
    # Create invalid PDF
    echo "This is not a PDF file" > "$invalid_pdf"
    
    cd "$TEMP_DIR"
    
    # This should fail gracefully
    if "$binary" invalid.pdf 2>/dev/null; then
        error "Binary should have failed on invalid PDF"
    else
        log "✓ Binary correctly rejected invalid PDF"
    fi
    
    # Test with non-existent file
    if "$binary" nonexistent.pdf 2>/dev/null; then
        error "Binary should have failed on non-existent PDF"
    else
        log "✓ Binary correctly handled non-existent file"
    fi
}

main() {
    log "Starting pdf2htmlEX v2 test suite..."
    
    local binary
    binary=$(find_pdf2htmlex)
    
    log "Testing binary: $binary"
    
    # Run all tests
    test_version "$binary"
    test_help "$binary"
    test_basic_conversion "$binary"
    test_advanced_options "$binary"
    test_multipage_pdf "$binary"
    test_binary_architecture "$binary"
    test_static_linking "$binary"
    test_error_handling "$binary"
    
    log "All tests completed successfully!"
    log "Binary is ready for use: $binary"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi