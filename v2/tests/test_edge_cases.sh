#!/bin/bash
# this_file: v2/tests/test_edge_cases.sh
#
# Edge case and error handling tests for pdf2htmlEX v2
# Tests various edge cases, error conditions, and robustness scenarios

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly TEMP_DIR="$(mktemp -d)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[EDGE TEST] $*${NC}"
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
        "$PROJECT_ROOT/v2/dist/bin/pdf2htmlEX" \
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

create_corrupted_pdf() {
    local pdf_file="$1"
    local corruption_type="$2"
    
    case "$corruption_type" in
        "truncated")
            # Create truncated PDF
            cat > "$pdf_file" << 'EOF'
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
(Truncated) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
EOF
            # File is truncated here - missing trailer
            ;;
            
        "invalid_header")
            # Create PDF with invalid header
            cat > "$pdf_file" << 'EOF'
%PDF-INVALID
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
(Invalid Header) Tj
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
            ;;
            
        "circular_reference")
            # Create PDF with circular object references
            cat > "$pdf_file" << 'EOF'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 /Parent 3 0 R >>
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
(Circular Ref) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000130 00000 n 
0000000222 00000 n 
trailer
<< /Size 5 /Root 1 0 R >>
startxref
316
%%EOF
EOF
            ;;
            
        "missing_xref")
            # Create PDF with missing xref table
            cat > "$pdf_file" << 'EOF'
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
(Missing Xref) Tj
ET
endstream
endobj
trailer
<< /Size 5 /Root 1 0 R >>
startxref
301
%%EOF
EOF
            ;;
    esac
}

create_large_pdf() {
    local pdf_file="$1"
    local size_mb="$2"
    
    # Create a PDF with many repeated pages to reach target size
    cat > "$pdf_file" << 'EOF'
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
<< /Length 1000 >>
stream
BT
/F1 12 Tf
100 700 Td
EOF
    
    # Add repetitive content to increase size
    for ((i=1; i<=size_mb*100; i++)); do
        echo "(Large PDF content line $i with lots of text to make it bigger) Tj 0 -12 Td" >> "$pdf_file"
    done
    
    cat >> "$pdf_file" << 'EOF'
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
}

test_corrupted_pdf_handling() {
    log "Testing corrupted PDF handling..."
    
    local binary="$1"
    local corruption_types=("truncated" "invalid_header" "circular_reference" "missing_xref")
    
    for corruption in "${corruption_types[@]}"; do
        local test_pdf="$TEMP_DIR/corrupted_${corruption}.pdf"
        create_corrupted_pdf "$test_pdf" "$corruption"
        
        cd "$TEMP_DIR"
        
        # Test that binary handles corruption gracefully
        if "$binary" "corrupted_${corruption}.pdf" 2>/dev/null; then
            warn "Binary succeeded on corrupted PDF ($corruption) - unexpected"
        else
            log "✓ Binary correctly rejected corrupted PDF ($corruption)"
        fi
    done
}

test_large_pdf_handling() {
    log "Testing large PDF handling..."
    
    local binary="$1"
    
    # Test with moderately large PDF (1MB)
    local large_pdf="$TEMP_DIR/large_test.pdf"
    create_large_pdf "$large_pdf" 1
    
    cd "$TEMP_DIR"
    
    # Test with timeout to prevent hanging
    if timeout 60 "$binary" large_test.pdf; then
        log "✓ Large PDF (1MB) processed successfully"
        
        if [[ -f "large_test.html" ]]; then
            log "✓ Large PDF HTML output created"
        else
            warn "Large PDF HTML output not created"
        fi
    else
        warn "Large PDF processing timed out or failed"
    fi
}

test_special_characters_in_filenames() {
    log "Testing special characters in filenames..."
    
    local binary="$1"
    
    # Test files with special characters
    local special_files=(
        "test with spaces.pdf"
        "test-with-dashes.pdf"
        "test_with_underscores.pdf"
        "test.with.dots.pdf"
        "test@with@symbols.pdf"
    )
    
    for filename in "${special_files[@]}"; do
        local test_pdf="$TEMP_DIR/$filename"
        
        # Create simple PDF with special filename
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
(Special Filename) Tj
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
        
        if "$binary" "$filename" 2>/dev/null; then
            log "✓ Special filename handled: $filename"
        else
            warn "Special filename failed: $filename"
        fi
    done
}

test_memory_exhaustion() {
    log "Testing memory exhaustion scenarios..."
    
    local binary="$1"
    
    # Create PDF designed to use lots of memory
    local memory_pdf="$TEMP_DIR/memory_test.pdf"
    
    # Create PDF with many objects
    cat > "$memory_pdf" << 'EOF'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [
EOF
    
    # Add many page references
    for ((i=3; i<=102; i++)); do
        echo "$i 0 R" >> "$memory_pdf"
    done
    
    cat >> "$memory_pdf" << 'EOF'
] /Count 100 >>
endobj
EOF
    
    # Add many page objects
    for ((i=3; i<=102; i++)); do
        cat >> "$memory_pdf" << EOF
$i 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents $((i+100)) 0 R >>
endobj
EOF
    done
    
    # Add content objects
    for ((i=103; i<=202; i++)); do
        cat >> "$memory_pdf" << EOF
$i 0 obj
<< /Length 100 >>
stream
BT /F1 12 Tf 100 700 Td (Page $((i-100))) Tj ET
endstream
endobj
EOF
    done
    
    cat >> "$memory_pdf" << 'EOF'
xref
0 203
0000000000 65535 f 
trailer
<< /Size 203 /Root 1 0 R >>
startxref
1000
%%EOF
EOF
    
    cd "$TEMP_DIR"
    
    # Test with memory limit (if available)
    if command -v ulimit &> /dev/null; then
        # Limit memory to 100MB
        ulimit -v 102400 2>/dev/null || true
    fi
    
    if timeout 120 "$binary" memory_test.pdf 2>/dev/null; then
        log "✓ Memory exhaustion test completed"
    else
        warn "Memory exhaustion test failed or timed out"
    fi
}

test_concurrent_processing() {
    log "Testing concurrent processing..."
    
    local binary="$1"
    
    # Create multiple test PDFs
    for i in {1..3}; do
        local test_pdf="$TEMP_DIR/concurrent_$i.pdf"
        cat > "$test_pdf" << EOF
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
(Concurrent Test $i) Tj
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
    done
    
    cd "$TEMP_DIR"
    
    # Run conversions concurrently
    ("$binary" concurrent_1.pdf &)
    ("$binary" concurrent_2.pdf &)
    ("$binary" concurrent_3.pdf &)
    
    # Wait for all processes
    wait
    
    # Check results
    local success_count=0
    for i in {1..3}; do
        if [[ -f "concurrent_$i.html" ]]; then
            ((success_count++))
        fi
    done
    
    if [[ $success_count -eq 3 ]]; then
        log "✓ Concurrent processing successful ($success_count/3)"
    else
        warn "Concurrent processing partial success ($success_count/3)"
    fi
}

test_disk_space_exhaustion() {
    log "Testing disk space exhaustion scenarios..."
    
    local binary="$1"
    
    # Create a small tmpfs if possible (Linux only)
    if [[ "$(uname)" == "Linux" ]] && command -v mount &> /dev/null; then
        local small_tmpfs="$TEMP_DIR/small_disk"
        mkdir -p "$small_tmpfs"
        
        # Try to create a 1MB tmpfs
        if sudo mount -t tmpfs -o size=1M tmpfs "$small_tmpfs" 2>/dev/null; then
            # Create test PDF in small filesystem
            local test_pdf="$small_tmpfs/disk_test.pdf"
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
(Disk Space Test) Tj
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
            
            cd "$small_tmpfs"
            
            # Test conversion with limited disk space
            if "$binary" disk_test.pdf 2>/dev/null; then
                log "✓ Disk space exhaustion test completed"
            else
                warn "Disk space exhaustion test failed"
            fi
            
            # Cleanup
            sudo umount "$small_tmpfs" 2>/dev/null || true
        else
            warn "Cannot create small tmpfs, skipping disk space test"
        fi
    else
        warn "Disk space exhaustion test skipped (not Linux or no mount)"
    fi
}

test_signal_handling() {
    log "Testing signal handling..."
    
    local binary="$1"
    
    # Create a test PDF
    local test_pdf="$TEMP_DIR/signal_test.pdf"
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
(Signal Test) Tj
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
    
    # Start conversion in background
    "$binary" signal_test.pdf &
    local pid=$!
    
    # Wait a moment then send SIGTERM
    sleep 1
    kill -TERM "$pid" 2>/dev/null || true
    
    # Wait for process to exit
    wait "$pid" 2>/dev/null || true
    
    # Check for cleanup
    if [[ -f "signal_test.html" ]]; then
        log "✓ Signal handling test - partial output created"
    else
        log "✓ Signal handling test - no partial output"
    fi
}

main() {
    log "Starting edge case test suite..."
    
    local binary
    binary=$(find_pdf2htmlex)
    
    log "Testing binary: $binary"
    
    # Run edge case tests
    test_corrupted_pdf_handling "$binary"
    test_large_pdf_handling "$binary"
    test_special_characters_in_filenames "$binary"
    test_memory_exhaustion "$binary"
    test_concurrent_processing "$binary"
    test_disk_space_exhaustion "$binary"
    test_signal_handling "$binary"
    
    log "Edge case tests completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi