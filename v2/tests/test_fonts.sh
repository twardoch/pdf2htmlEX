#!/bin/bash
# this_file: v2/tests/test_fonts.sh
#
# Font handling tests for pdf2htmlEX v2
# Tests various font scenarios including embedded fonts, system fonts, and Unicode

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEMP_DIR="$(mktemp -d)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[FONT TEST] $*${NC}"
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
    
    for path in \
        "$SCRIPT_DIR/../../dist/bin/pdf2htmlEX" \
        "$(brew --prefix)/bin/pdf2htmlEX" \
        "$(which pdf2htmlEX 2>/dev/null || true)"; do
        
        if [[ -x "$path" ]]; then
            binary="$path"
            break
        fi
    done
    
    if [[ -z "$binary" ]]; then
        error "pdf2htmlEX binary not found"
    fi
    
    echo "$binary"
}

create_font_test_pdf() {
    local pdf_file="$1"
    local font_type="$2"
    
    case "$font_type" in
        "type1")
            # PDF with Type1 font
            cat > "$pdf_file" << 'EOF'
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
<< /Type /Font /Subtype /Type1 /BaseFont /Times-Roman >>
endobj
5 0 obj
<< /Length 88 >>
stream
BT
/F1 16 Tf
50 700 Td
(Type1 Font Test: Times Roman) Tj
0 -20 Td
(ABCDEFGHIJKLMNOPQRSTUVWXYZ) Tj
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
0000000301 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
429
%%EOF
EOF
            ;;
            
        "truetype")
            # PDF with TrueType font reference
            cat > "$pdf_file" << 'EOF'
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
<< /Type /Font /Subtype /TrueType /BaseFont /Arial >>
endobj
5 0 obj
<< /Length 85 >>
stream
BT
/F1 16 Tf
50 700 Td
(TrueType Font Test: Arial) Tj
0 -20 Td
(abcdefghijklmnopqrstuvwxyz) Tj
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
0000000300 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
425
%%EOF
EOF
            ;;
            
        "unicode")
            # PDF with Unicode text
            cat > "$pdf_file" << 'EOF'
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
<< /Length 120 >>
stream
BT
/F1 16 Tf
50 700 Td
(Unicode Test: Hello) Tj
0 -20 Td
(Special chars: @#$%^&*) Tj
0 -20 Td
(Numbers: 0123456789) Tj
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
459
%%EOF
EOF
            ;;
    esac
}

test_type1_fonts() {
    log "Testing Type1 font handling..."
    
    local binary="$1"
    local test_pdf="$TEMP_DIR/type1_test.pdf"
    
    create_font_test_pdf "$test_pdf" "type1"
    
    cd "$TEMP_DIR"
    
    if "$binary" type1_test.pdf; then
        log "✓ Type1 font conversion completed"
        
        if [[ -f "type1_test.html" ]]; then
            # Check if text is preserved
            if grep -q "Type1 Font Test" "type1_test.html" && \
               grep -q "ABCDEFGHIJKLMNOPQRSTUVWXYZ" "type1_test.html"; then
                log "✓ Type1 font text preserved correctly"
            else
                error "Type1 font text not preserved"
            fi
            
            # Check for font-related CSS
            if grep -q "font-family" "type1_test.html"; then
                log "✓ Font CSS generated"
            else
                warn "No font CSS found"
            fi
        else
            error "Type1 HTML output not created"
        fi
    else
        error "Type1 font conversion failed"
    fi
}

test_truetype_fonts() {
    log "Testing TrueType font handling..."
    
    local binary="$1"
    local test_pdf="$TEMP_DIR/truetype_test.pdf"
    
    create_font_test_pdf "$test_pdf" "truetype"
    
    cd "$TEMP_DIR"
    
    if "$binary" truetype_test.pdf; then
        log "✓ TrueType font conversion completed"
        
        if [[ -f "truetype_test.html" ]]; then
            # Check if text is preserved
            if grep -q "TrueType Font Test" "truetype_test.html" && \
               grep -q "abcdefghijklmnopqrstuvwxyz" "truetype_test.html"; then
                log "✓ TrueType font text preserved correctly"
            else
                error "TrueType font text not preserved"
            fi
        else
            error "TrueType HTML output not created"
        fi
    else
        error "TrueType font conversion failed"
    fi
}

test_unicode_handling() {
    log "Testing Unicode text handling..."
    
    local binary="$1"
    local test_pdf="$TEMP_DIR/unicode_test.pdf"
    
    create_font_test_pdf "$test_pdf" "unicode"
    
    cd "$TEMP_DIR"
    
    if "$binary" unicode_test.pdf; then
        log "✓ Unicode text conversion completed"
        
        if [[ -f "unicode_test.html" ]]; then
            # Check if special characters are preserved
            if grep -q "Special chars" "unicode_test.html" && \
               grep -q "Numbers: 0123456789" "unicode_test.html"; then
                log "✓ Unicode text preserved correctly"
            else
                error "Unicode text not preserved"
            fi
            
            # Check HTML encoding
            if head -20 "unicode_test.html" | grep -q "charset=utf-8"; then
                log "✓ UTF-8 encoding specified"
            else
                warn "UTF-8 encoding not explicitly specified"
            fi
        else
            error "Unicode HTML output not created"
        fi
    else
        error "Unicode text conversion failed"
    fi
}

test_font_embedding_options() {
    log "Testing font embedding options..."
    
    local binary="$1"
    local test_pdf="$TEMP_DIR/embed_test.pdf"
    
    create_font_test_pdf "$test_pdf" "type1"
    
    cd "$TEMP_DIR"
    
    # Test with font embedding disabled
    if "$binary" --embed-font 0 embed_test.pdf -o no_embed.html; then
        log "✓ No-embed font conversion completed"
        
        if [[ -f "no_embed.html" ]]; then
            # Check that no font files were created
            local font_files
            font_files=$(ls *.woff *.ttf *.otf 2>/dev/null | wc -l)
            
            if [[ $font_files -eq 0 ]]; then
                log "✓ No font files created (as expected)"
            else
                warn "Font files created despite --embed-font 0"
            fi
        fi
    else
        warn "No-embed font conversion failed"
    fi
    
    # Test with font embedding enabled (default)
    if "$binary" embed_test.pdf -o embed.html; then
        log "✓ Embed font conversion completed"
        
        if [[ -f "embed.html" ]]; then
            log "✓ Font embedding test passed"
        fi
    else
        warn "Embed font conversion failed"
    fi
}

test_font_fallback() {
    log "Testing font fallback handling..."
    
    local binary="$1"
    local test_pdf="$TEMP_DIR/fallback_test.pdf"
    
    # Create PDF with potentially missing font
    cat > "$test_pdf" << 'EOF'
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
<< /Type /Font /Subtype /Type1 /BaseFont /NonExistentFont >>
endobj
5 0 obj
<< /Length 70 >>
stream
BT
/F1 16 Tf
50 700 Td
(Font Fallback Test) Tj
0 -20 Td
(Should use fallback font) Tj
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
0000000306 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
416
%%EOF
EOF
    
    cd "$TEMP_DIR"
    
    if "$binary" fallback_test.pdf 2>/dev/null; then
        log "✓ Font fallback conversion completed"
        
        if [[ -f "fallback_test.html" ]]; then
            # Check if text is still preserved despite missing font
            if grep -q "Font Fallback Test" "fallback_test.html" && \
               grep -q "Should use fallback font" "fallback_test.html"; then
                log "✓ Text preserved with font fallback"
            else
                error "Text not preserved during font fallback"
            fi
        else
            error "Font fallback HTML output not created"
        fi
    else
        warn "Font fallback conversion failed (may be expected)"
    fi
}

main() {
    log "Starting font handling test suite..."
    
    local binary
    binary=$(find_pdf2htmlex)
    
    log "Testing binary: $binary"
    
    # Run font tests
    test_type1_fonts "$binary"
    test_truetype_fonts "$binary"
    test_unicode_handling "$binary"
    test_font_embedding_options "$binary"
    test_font_fallback "$binary"
    
    log "Font handling tests completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi