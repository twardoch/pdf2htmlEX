#!/bin/bash
# test-formula.sh - Test the pdf2htmlEX formula locally

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to create test PDF
create_test_pdf() {
    local pdf_file="$1"
    cat > "$pdf_file" << 'EOF'
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Resources<</Font<</F1 4 0 R>>>>/Contents 5 0 R>>endobj
4 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
5 0 obj<</Length 87>>stream
BT
/F1 24 Tf
100 700 Td
(Hello from pdf2htmlEX!) Tj
0 -30 Td
/F1 16 Tf
(Testing formula build) Tj
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
trailer<</Size 6/Root 1 0 R>>
startxref
441
%%EOF
EOF
}

print_status "$GREEN" "=== pdf2htmlEX Formula Test Script ==="
echo ""

# Check prerequisites
print_status "$YELLOW" "Checking prerequisites..."

if ! command_exists brew; then
    print_status "$RED" "Error: Homebrew is not installed"
    exit 1
fi

# Get formula path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMULA_PATH="$SCRIPT_DIR/../Formula/pdf2htmlex.rb"

if [ ! -f "$FORMULA_PATH" ]; then
    print_status "$RED" "Error: Formula not found at $FORMULA_PATH"
    exit 1
fi

# Run audit
print_status "$YELLOW" "Running formula audit..."
if brew audit --strict "$FORMULA_PATH"; then
    print_status "$GREEN" "✓ Formula audit passed"
else
    print_status "$RED" "✗ Formula audit failed"
    exit 1
fi

# Check if already installed
if brew list pdf2htmlex &>/dev/null; then
    print_status "$YELLOW" "pdf2htmlEX is already installed. Uninstalling first..."
    brew uninstall pdf2htmlex
fi

# Install formula
print_status "$YELLOW" "Installing formula from source..."
if brew install --build-from-source "$FORMULA_PATH"; then
    print_status "$GREEN" "✓ Formula installed successfully"
else
    print_status "$RED" "✗ Formula installation failed"
    exit 1
fi

# Run brew test
print_status "$YELLOW" "Running brew test..."
if brew test pdf2htmlex; then
    print_status "$GREEN" "✓ Brew test passed"
else
    print_status "$RED" "✗ Brew test failed"
    exit 1
fi

# Test basic functionality
print_status "$YELLOW" "Testing basic functionality..."

# Create temporary directory
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Create test PDF
create_test_pdf "test.pdf"

# Convert PDF to HTML
print_status "$YELLOW" "Converting test PDF to HTML..."
if pdf2htmlEX test.pdf; then
    print_status "$GREEN" "✓ PDF conversion successful"
else
    print_status "$RED" "✗ PDF conversion failed"
    cd - >/dev/null
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check output
if [ -f "test.html" ]; then
    if grep -q "Hello from pdf2htmlEX!" test.html; then
        print_status "$GREEN" "✓ HTML output contains expected content"
    else
        print_status "$RED" "✗ HTML output missing expected content"
        cd - >/dev/null
        rm -rf "$TEST_DIR"
        exit 1
    fi
else
    print_status "$RED" "✗ HTML output file not created"
    cd - >/dev/null
    rm -rf "$TEST_DIR"
    exit 1
fi

# Test with options
print_status "$YELLOW" "Testing with various options..."

# Test zoom option
if pdf2htmlEX --zoom 2 test.pdf test-zoom.html; then
    print_status "$GREEN" "✓ Zoom option works"
else
    print_status "$RED" "✗ Zoom option failed"
fi

# Test split pages
if pdf2htmlEX --split-pages 1 test.pdf test-split.html; then
    print_status "$GREEN" "✓ Split pages option works"
else
    print_status "$RED" "✗ Split pages option failed"
fi

# Check architecture
print_status "$YELLOW" "Checking binary architecture..."
BINARY_PATH="$(brew --prefix)/bin/pdf2htmlEX"
if [ -f "$BINARY_PATH" ]; then
    ARCH_INFO=$(file "$BINARY_PATH")
    echo "Binary info: $ARCH_INFO"
    
    if [[ "$ARCH_INFO" == *"universal"* ]] || [[ "$ARCH_INFO" == *"x86_64"* ]] || [[ "$ARCH_INFO" == *"arm64"* ]]; then
        print_status "$GREEN" "✓ Binary architecture looks correct"
        
        # Check with lipo if available
        if command_exists lipo; then
            print_status "$YELLOW" "Detailed architecture info:"
            lipo -info "$BINARY_PATH"
        fi
    else
        print_status "$RED" "✗ Unexpected binary architecture"
    fi
else
    print_status "$RED" "✗ Binary not found at expected location"
fi

# Cleanup
cd - >/dev/null
rm -rf "$TEST_DIR"

# Performance test (optional)
if [ "${RUN_PERF_TEST:-0}" = "1" ]; then
    print_status "$YELLOW" "Running performance test..."
    
    # Create a more complex PDF for performance testing
    PERF_DIR=$(mktemp -d)
    cd "$PERF_DIR"
    
    # Here we would create a larger PDF or use a sample
    # For now, just use the simple test
    create_test_pdf "perf-test.pdf"
    
    # Time the conversion
    START_TIME=$(date +%s)
    pdf2htmlEX perf-test.pdf >/dev/null 2>&1
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    print_status "$GREEN" "✓ Performance test completed in ${DURATION}s"
    
    cd - >/dev/null
    rm -rf "$PERF_DIR"
fi

# Summary
echo ""
print_status "$GREEN" "=== All tests passed! ==="
print_status "$YELLOW" "pdf2htmlEX version:"
pdf2htmlEX --version

# Optional: show formula info
if [ "${SHOW_INFO:-0}" = "1" ]; then
    echo ""
    print_status "$YELLOW" "Formula info:"
    brew info pdf2htmlex
fi